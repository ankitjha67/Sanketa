/// ADB-over-TCP client for communicating with Android TV devices.
///
/// Supports the ADB wire protocol, RSA authentication, and a restricted
/// set of shell commands for debloating and system stats.
///
/// Security: only whitelisted shell operations are exposed. No raw shell
/// access. Package names are validated against `^[a-zA-Z0-9._]+$`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'adb_auth.dart';
import 'adb_models.dart';
import 'adb_protocol.dart';

final _validPackageName = RegExp(r'^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

const _allowedCommandPrefixes = <String>[
  'pm list packages',
  'pm disable-user',
  'pm enable',
  'pm path',
  'dumpsys meminfo',
  'dumpsys battery',
  'dumpsys diskstats',
  'top ',
  'df ',
  'getprop ',
  'settings get',
  'am start',
  'am force-stop',
  'input ',
  'wm size',
  'cat /proc/meminfo',
  'ps ',
  'cmd package',
];

class AdbClient {
  AdbClient({required this.host, this.port = 5555, this.keyStore});

  final String host;
  final int port;
  final AdbKeyStore? keyStore;

  Socket? _socket;
  bool _connected = false;
  String? _deviceBanner;
  int _nextLocalId = 1;
  final _pendingStreams = <int, Completer<_ShellStream>>{};
  final _activeStreams = <int, _ShellStream>{};
  final _buf = BytesBuilder(copy: false);

  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;

  bool get isConnected => _connected;
  String? get deviceBanner => _deviceBanner;

  Future<bool> connect() async {
    if (_connected) return true;
    await _ensureKeys();
    try {
      _socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 5));
    } on Object {
      return false;
    }
    _buf.clear();

    final connCompleter = Completer<bool>();
    _socket!.listen(
      (data) => _onData(data, connCompleter),
      onError: (Object e) {
        _connected = false;
        if (!connCompleter.isCompleted) connCompleter.complete(false);
      },
      onDone: () {
        _connected = false;
        if (!connCompleter.isCompleted) connCompleter.complete(false);
        _failAllStreams('Connection closed');
      },
    );

    _send(buildCnxn());
    _connected = await connCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
    return _connected;
  }

  Future<void> disconnect() async {
    _connected = false;
    _failAllStreams('Disconnected');
    _socket?.destroy();
    _socket = null;
  }

  // -- Whitelisted operations ------------------------------------------------

  Future<List<String>> listPackages({bool disabledOnly = false}) async {
    final flag = disabledOnly ? ' -d' : '';
    final raw = await _shellCommand('pm list packages$flag');
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('package:'))
        .map((l) => l.substring(8).trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  Future<bool> disablePackage(String pkg) async {
    _validatePackageName(pkg);
    final out = await _shellCommand(
        'pm disable-user --user 0 $pkg');
    return out.contains('disabled') || out.contains('new state: disabled');
  }

  Future<bool> enablePackage(String pkg) async {
    _validatePackageName(pkg);
    final out = await _shellCommand('pm enable $pkg');
    return out.contains('enabled') || out.contains('new state: enabled');
  }

  Future<String> getDeviceModel() async {
    return (await _shellCommand('getprop ro.product.model')).trim();
  }

  Future<String> getAndroidVersion() async {
    return (await _shellCommand('getprop ro.build.version.release')).trim();
  }

  Future<Map<String, String>> getDeviceProps() async {
    const keys = [
      'ro.product.model',
      'ro.product.brand',
      'ro.product.manufacturer',
      'ro.product.device',
      'ro.build.version.release',
      'ro.build.version.sdk',
      'ro.build.display.id',
    ];
    final result = <String, String>{};
    for (final k in keys) {
      result[k] = (await _shellCommand('getprop $k')).trim();
    }
    return result;
  }

  Future<String> getMemInfoRaw() async {
    return _shellCommand('cat /proc/meminfo');
  }

  Future<TvMemoryStats> getMemoryStats() async {
    final raw = await _shellCommand('cat /proc/meminfo');
    var total = 0, free = 0, available = 0;
    for (final line in raw.split('\n')) {
      if (line.startsWith('MemTotal:')) {
        total = _parseKb(line);
      } else if (line.startsWith('MemFree:')) {
        free = _parseKb(line);
      } else if (line.startsWith('MemAvailable:')) {
        available = _parseKb(line);
      }
    }
    final used = total - (available > 0 ? available : free);
    return TvMemoryStats(totalKb: total, freeKb: free, usedKb: used);
  }

  Future<String> getCpuInfoRaw() async {
    return _shellCommand('top -b -n 1 -m 20');
  }

  Future<TvCpuStats> getCpuStats() async {
    final raw = await _shellCommand('top -b -n 1 -m 20');
    double user = 0, system = 0, idle = 100;
    for (final line in raw.split('\n')) {
      final lower = line.toLowerCase();
      if (lower.contains('%cpu') || lower.contains('cpu:')) {
        final nums = RegExp(r'(\d+(?:\.\d+)?)')
            .allMatches(line)
            .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
            .toList();
        if (nums.length >= 3) {
          user = nums[0];
          system = nums[1];
          idle = nums.length > 3 ? nums[3] : 100.0 - user - system;
        }
        break;
      }
    }
    return TvCpuStats(
        userPercent: user, systemPercent: system, idlePercent: idle);
  }

  Future<String> getDiskUsageRaw() async {
    return _shellCommand('df -h');
  }

  Future<TvStorageStats> getStorageStats() async {
    final raw = await _shellCommand('df /data');
    for (final line in raw.split('\n')) {
      if (line.contains('/data')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          return TvStorageStats(
            totalKb: _parseSizeField(parts[1]),
            usedKb: _parseSizeField(parts[2]),
            availableKb: _parseSizeField(parts[3]),
            mountPoint: '/data',
          );
        }
      }
    }
    return const TvStorageStats(
        totalKb: 0, usedKb: 0, availableKb: 0, mountPoint: '/data');
  }

  Future<List<TvProcess>> getTopProcesses({int limit = 20}) async {
    final raw = await _shellCommand('top -b -n 1 -m $limit');
    final processes = <TvProcess>[];
    var headerPassed = false;
    for (final line in raw.split('\n')) {
      if (line.contains('PID') &&
          (line.contains('NAME') || line.contains('ARGS'))) {
        headerPassed = true;
        continue;
      }
      if (!headerPassed) continue;
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 3) continue;
      final pid = int.tryParse(parts[0]);
      if (pid == null) continue;
      final name = parts.last;
      final cpuStr = parts.firstWhere(
          (p) => p.endsWith('%') || double.tryParse(p) != null,
          orElse: () => '0');
      final cpu = double.tryParse(cpuStr.replaceAll('%', '')) ?? 0.0;
      processes.add(TvProcess(pid: pid, name: name, cpuPercent: cpu, memKb: 0));
    }
    processes.sort((a, b) => b.cpuPercent.compareTo(a.cpuPercent));
    return processes;
  }

  Future<List<String>> getRunningProcessNames() async {
    final raw = await _shellCommand('ps -A -o PID,NAME,RSS,VSZ');
    return raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  Future<String> getBatteryInfo() async {
    return _shellCommand('dumpsys battery');
  }

  Future<List<TvApp>> getInstalledApps() async {
    final sysRaw = await _shellCommand('pm list packages -s');
    final allRaw = await _shellCommand('pm list packages -f');

    final systemPkgs = <String>{};
    for (final line in sysRaw.split('\n')) {
      final pkg = line.replaceFirst('package:', '').trim();
      if (pkg.isNotEmpty) systemPkgs.add(pkg);
    }

    final apps = <TvApp>[];
    for (final line in allRaw.split('\n')) {
      final trimmed = line.replaceFirst('package:', '').trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.lastIndexOf('=');
      if (eqIdx < 0) continue;
      final pkg = trimmed.substring(eqIdx + 1);
      apps.add(TvApp(
        packageName: pkg,
        label: pkg.split('.').last,
        isSystem: systemPkgs.contains(pkg),
      ));
    }
    apps.sort((a, b) => a.label.compareTo(b.label));
    return apps;
  }

  Future<void> forceStopApp(String pkg) async {
    _validatePackageName(pkg);
    await _shellCommand('am force-stop $pkg');
  }

  Future<void> launchApp(String pkg) async {
    _validatePackageName(pkg);
    await _shellCommand(
        'am start -a android.intent.action.MAIN -c android.intent.category.LEANBACK_LAUNCHER $pkg');
  }

  static int _parseKb(String line) {
    final match = RegExp(r'(\d+)').firstMatch(line);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  static int _parseSizeField(String s) {
    final clean = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  // -- Internal shell execution ----------------------------------------------

  Future<String> _shellCommand(String cmd) async {
    if (!_connected || _socket == null) {
      throw StateError('ADB not connected');
    }
    if (!_allowedCommandPrefixes.any((p) => cmd.startsWith(p))) {
      throw ArgumentError('Command not whitelisted: '
          '${cmd.substring(0, cmd.length.clamp(0, 30))}');
    }
    final localId = _nextLocalId++;
    final completer = Completer<_ShellStream>();
    _pendingStreams[localId] = completer;

    _send(buildOpen(localId, 'shell:$cmd'));

    final stream = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingStreams.remove(localId);
        throw TimeoutException('Shell command timed out: $cmd');
      },
    );

    final output = await stream.output.timeout(
      const Duration(seconds: 30),
      onTimeout: () => stream.collectedOutput,
    );
    _activeStreams.remove(localId);
    return output;
  }

  // -- Wire protocol handling ------------------------------------------------

  void _onData(Uint8List chunk, Completer<bool> connCompleter) {
    _buf.add(chunk);
    _processBuffer(connCompleter);
  }

  void _processBuffer(Completer<bool> connCompleter) {
    while (true) {
      final bytes = _buf.takeBytes();
      if (bytes.length < adbHeaderSize) {
        _buf.add(bytes);
        return;
      }

      final msg = AdbMessage.decodeHeader(bytes);
      if (msg == null) {
        _buf.add(bytes);
        return;
      }

      final totalSize = adbHeaderSize + msg.data.length;
      if (bytes.length < totalSize) {
        _buf.add(bytes);
        return;
      }

      if (msg.data.isNotEmpty) {
        msg.data.setRange(0, msg.data.length,
            bytes.sublist(adbHeaderSize, totalSize));
      }

      if (bytes.length > totalSize) {
        _buf.add(bytes.sublist(totalSize));
      }

      _handleMessage(msg, connCompleter);
    }
  }

  void _handleMessage(AdbMessage msg, Completer<bool> connCompleter) {
    switch (msg.command) {
      case adbCnxn:
        _deviceBanner = msg.dataAsString;
        if (!connCompleter.isCompleted) connCompleter.complete(true);

      case adbAuth:
        if (msg.arg0 == authToken) {
          _handleAuthToken(msg.data, connCompleter);
        }

      case adbOkay:
        final localId = msg.arg1;
        final remoteId = msg.arg0;
        final pending = _pendingStreams.remove(localId);
        if (pending != null) {
          final stream = _ShellStream(localId: localId, remoteId: remoteId);
          _activeStreams[localId] = stream;
          pending.complete(stream);
        }
        final active = _activeStreams[localId];
        if (active != null) {
          _send(buildOkay(localId, remoteId));
        }

      case adbWrte:
        final localId = msg.arg1;
        final remoteId = msg.arg0;
        final stream = _activeStreams[localId];
        if (stream != null) {
          stream.addData(msg.data);
          _send(buildOkay(localId, remoteId));
        }

      case adbClse:
        final localId = msg.arg1;
        final stream = _activeStreams.remove(localId);
        stream?.close();
    }
  }

  void _handleAuthToken(Uint8List token, Completer<bool> connCompleter) {
    final signed = _signToken(token);
    if (signed != null) {
      _send(buildAuthSignature(signed));
    }
    // Also send public key so TV can prompt user to accept.
    final pubKeyBytes = _encodePublicKeyForAdb();
    _send(buildAuthPublicKey(pubKeyBytes));
  }

  Uint8List? _signToken(Uint8List token) {
    if (_privateKey == null) return null;
    final signer = RSASigner(SHA1Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey!));
    final sig = signer.generateSignature(token);
    return sig.bytes;
  }

  Uint8List _encodePublicKeyForAdb() {
    // ADB expects: base64(android_pubkey_encode(key)) + " adb@sanketa\0"
    final n = _publicKey!.modulus!;
    final e = _publicKey!.exponent!;

    // Android RSA public key format (see system/core/libcrypto_utils/android_pubkey.c):
    // uint32_t modulus_size_words (LE)
    // uint32_t n0inv (LE) — Montgomery parameter
    // uint8_t  modulus[MODULUS_SIZE] (LE)
    // uint8_t  rr[MODULUS_SIZE] (LE)
    // uint32_t exponent (LE)
    const modulusSize = 256; // 2048 bits = 256 bytes
    const wordsCount = modulusSize ~/ 4;

    final buf = ByteData(4 + 4 + modulusSize + modulusSize + 4);
    buf.setUint32(0, wordsCount, Endian.little);

    // n0inv = -n^(-1) mod 2^32
    final n0inv = _computeN0inv(n);
    buf.setUint32(4, n0inv, Endian.little);

    // modulus in LE bytes
    final nBytes = _bigIntToLEBytes(n, modulusSize);
    for (var i = 0; i < modulusSize; i++) {
      buf.setUint8(8 + i, nBytes[i]);
    }

    // rr = (2^(modulusSize*8))^2 mod n
    final rr = (BigInt.one << (modulusSize * 8 * 2)) % n;
    final rrBytes = _bigIntToLEBytes(rr, modulusSize);
    for (var i = 0; i < modulusSize; i++) {
      buf.setUint8(8 + modulusSize + i, rrBytes[i]);
    }

    buf.setUint32(8 + modulusSize * 2, e.toInt(), Endian.little);

    final b64 = base64Encode(buf.buffer.asUint8List());
    return Uint8List.fromList(utf8.encode('$b64 adb@sanketa\x00'));
  }

  int _computeN0inv(BigInt n) {
    // Compute -n^(-1) mod 2^32 using extended Euclidean algorithm.
    final mask = BigInt.from(0xFFFFFFFF);
    final nLow = n & mask;
    var inv = BigInt.one;
    for (var i = 1; i < 32; i++) {
      inv = (inv * inv * nLow) & mask;
    }
    return ((mask + BigInt.one - inv) & mask).toInt();
  }

  Uint8List _bigIntToLEBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var v = value;
    for (var i = 0; i < length; i++) {
      bytes[i] = (v & BigInt.from(0xFF)).toInt();
      v >>= 8;
    }
    return bytes;
  }

  void _send(AdbMessage msg) {
    _socket?.add(msg.encode());
  }

  Future<void> _ensureKeys() async {
    if (_privateKey != null) return;

    if (keyStore != null) {
      final loaded = await keyStore!.loadKeys();
      if (loaded != null) {
        _publicKey = loaded.$1;
        _privateKey = loaded.$2;
        return;
      }
    }

    final secureRandom = FortunaRandom()
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(256)))));
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
          secureRandom));
    final pair = keyGen.generateKeyPair();
    _publicKey = pair.publicKey as RSAPublicKey;
    _privateKey = pair.privateKey as RSAPrivateKey;

    if (keyStore != null) {
      await keyStore!.saveKeys(_publicKey!, _privateKey!);
    }
  }

  void _failAllStreams(String reason) {
    for (final c in _pendingStreams.values) {
      if (!c.isCompleted) {
        c.completeError(StateError(reason));
      }
    }
    _pendingStreams.clear();
    for (final s in _activeStreams.values) {
      s.close();
    }
    _activeStreams.clear();
  }

  void _validatePackageName(String pkg) {
    if (!_validPackageName.hasMatch(pkg)) {
      throw ArgumentError.value(
          pkg, 'packageName', 'Invalid package name');
    }
    if (pkg.length > 256) {
      throw ArgumentError.value(
          pkg, 'packageName', 'Package name too long');
    }
  }
}

class _ShellStream {
  _ShellStream({required this.localId, required this.remoteId});

  final int localId;
  final int remoteId;
  final _data = StringBuffer();
  final _completer = Completer<String>();
  void addData(Uint8List bytes) {
    _data.write(utf8.decode(bytes, allowMalformed: true));
  }

  void close() {
    if (!_completer.isCompleted) {
      _completer.complete(_data.toString());
    }
  }

  String get collectedOutput => _data.toString();

  Future<String> get output => _completer.future;
}
