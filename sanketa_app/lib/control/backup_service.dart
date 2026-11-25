import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Encrypted backup / restore for Sanketa user data.
///
/// Security model:
/// - AES-256-CBC with PKCS7 padding
/// - PBKDF2-HMAC-SHA256 key derivation (100 000 iterations)
/// - Encrypt-then-MAC (HMAC-SHA256) for integrity
/// - Passphrase is never stored
/// - Pairing secrets are excluded (Keystore-only)
/// - Zero network calls (local file only)
///
/// File layout (`.sanketa`):
///   version (1 B) | salt (32 B) | IV (16 B) | ciphertext (n B) | HMAC (32 B)
class BackupService extends ChangeNotifier {
  List<BackupEntry> _backups = [];
  bool _busy = false;

  List<BackupEntry> get backups => List.unmodifiable(_backups);
  bool get isBusy => _busy;

  static const int _version = 1;
  static const int _saltLen = 32;
  static const int _ivLen = 16;
  static const int _hmacLen = 32;
  static const int _iterations = 100000;
  static const int _dkLen = 64; // 32 enc + 32 mac

  /// JSON files eligible for backup (no pairing secrets).
  static const _dataFiles = [
    'macros.json',
    'search_shortcuts.json',
    'custom_layouts.json',
    'usage.json',
    'parental.json',
  ];

  // ── backup list management ──────────────────────────────────

  Future<void> loadBackupList() async {
    final dir = await _backupDir();
    if (!dir.existsSync()) return;
    _backups = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sanketa'))
        .map((f) => BackupEntry(
              path: f.path,
              name: f.uri.pathSegments.last.replaceAll('.sanketa', ''),
              created: f.statSync().modified,
              sizeBytes: f.lengthSync(),
            ))
        .toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    notifyListeners();
  }

  Future<void> deleteBackup(String path) async {
    final f = File(path);
    if (f.existsSync()) await f.delete();
    await loadBackupList();
  }

  /// Convenience: create a named backup without a passphrase (unencrypted JSON).
  Future<String> createBackup(String name) async {
    _busy = true;
    notifyListeners();
    try {
      final payload = await _buildPayload();
      final dir = await _backupDir();
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final safeName = name.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final file = File('${dir.path}/$safeName.sanketa');
      await file.writeAsString(jsonEncode(payload));
      await loadBackupList();
      return file.path;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Convenience: restore from a named backup (unencrypted JSON).
  Future<int> restoreBackup(String filePath) async {
    _busy = true;
    notifyListeners();
    try {
      final raw = await File(filePath).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return 0;
      final appDir = await getApplicationSupportDirectory();
      var count = 0;
      for (final entry in data.entries) {
        if (_dataFiles.contains(entry.key)) {
          await File('${appDir.path}/${entry.key}')
              .writeAsString(jsonEncode(entry.value));
          count++;
        }
      }
      return count;
    } on Object {
      return 0;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── encrypted export ────────────────────────────────────────

  /// Create an encrypted `.sanketa` backup and return its file path.
  Future<String> exportBackup(String passphrase) async {
    _busy = true;
    notifyListeners();

    try {
      final payload = await _buildPayload();
      final plain = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

      final salt = _randomBytes(_saltLen);
      final iv = _randomBytes(_ivLen);
      final dk = _pbkdf2(passphrase, salt, _iterations, _dkLen);
      final encKey = enc.Key(Uint8List.fromList(dk.sublist(0, 32)));
      final macKey = dk.sublist(32, 64);

      // Encrypt.
      final cipher = enc.Encrypter(
        enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      ).encryptBytes(plain, iv: enc.IV(iv));

      // Assemble: version || salt || iv || ciphertext.
      final header = BytesBuilder()
        ..addByte(_version)
        ..add(salt)
        ..add(iv)
        ..add(cipher.bytes);
      final preHmac = header.toBytes();

      // MAC over everything before the HMAC itself.
      final mac = Hmac(sha256, macKey).convert(preHmac).bytes;

      // Write version || salt || iv || ciphertext || hmac.
      final out = Uint8List(preHmac.length + _hmacLen)
        ..setAll(0, preHmac)
        ..setRange(preHmac.length, preHmac.length + _hmacLen, mac);

      final dir = await _backupDir();
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/backup_$ts.sanketa');
      await file.writeAsBytes(out);

      await loadBackupList();
      return file.path;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── encrypted import ────────────────────────────────────────

  /// Decrypt and restore a `.sanketa` backup.  Returns `true` on success.
  Future<bool> importBackup(String filePath, String passphrase) async {
    _busy = true;
    notifyListeners();

    try {
      final raw = await File(filePath).readAsBytes();
      // Minimum: version(1) + salt(32) + iv(16) + hmac(32) + 16 ciphertext.
      if (raw.length < 1 + _saltLen + _ivLen + _hmacLen + 16) return false;

      final version = raw[0];
      if (version != _version) return false;

      final salt = Uint8List.fromList(raw.sublist(1, 1 + _saltLen));
      final iv = Uint8List.fromList(
          raw.sublist(1 + _saltLen, 1 + _saltLen + _ivLen));
      final ct = Uint8List.fromList(
          raw.sublist(1 + _saltLen + _ivLen, raw.length - _hmacLen));
      final storedMac =
          Uint8List.fromList(raw.sublist(raw.length - _hmacLen));

      // Derive keys.
      final dk = _pbkdf2(passphrase, salt, _iterations, _dkLen);
      final encKey = enc.Key(Uint8List.fromList(dk.sublist(0, 32)));
      final macKey = dk.sublist(32, 64);

      // Verify MAC (constant-time).
      final preHmac =
          Uint8List.fromList(raw.sublist(0, raw.length - _hmacLen));
      final computed =
          Uint8List.fromList(Hmac(sha256, macKey).convert(preHmac).bytes);
      if (!_constantTimeEq(computed, storedMac)) return false;

      // Decrypt.
      final plain = enc.Encrypter(
        enc.AES(encKey, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      ).decryptBytes(enc.Encrypted(ct), iv: enc.IV(iv));

      final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      // Restore individual data files.
      final appDir = await getApplicationSupportDirectory();
      for (final entry in data.entries) {
        if (_dataFiles.contains(entry.key)) {
          await File('${appDir.path}/${entry.key}')
              .writeAsString(jsonEncode(entry.value));
        }
      }
      return true;
    } on Object {
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── internals ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _buildPayload() async {
    final dir = await getApplicationSupportDirectory();
    final data = <String, dynamic>{};
    for (final name in _dataFiles) {
      final f = File('${dir.path}/$name');
      if (await f.exists()) {
        try {
          data[name] = jsonDecode(await f.readAsString());
        } on Object {
          // Skip unreadable file.
        }
      }
    }
    return {
      'version': _version,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device': Platform.operatingSystem,
      'data': data,
    };
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018 s5.2).
  Uint8List _pbkdf2(
      String passphrase, Uint8List salt, int iterations, int keyLen) {
    final prf = Hmac(sha256, utf8.encode(passphrase));
    final blocks = (keyLen + 31) ~/ 32;
    final out = Uint8List(keyLen);

    for (var b = 1; b <= blocks; b++) {
      final input = BytesBuilder()
        ..add(salt)
        ..add([
          (b >> 24) & 0xff,
          (b >> 16) & 0xff,
          (b >> 8) & 0xff,
          b & 0xff,
        ]);
      var u = Uint8List.fromList(prf.convert(input.toBytes()).bytes);
      final t = Uint8List.fromList(u);
      for (var j = 1; j < iterations; j++) {
        u = Uint8List.fromList(prf.convert(u).bytes);
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      final off = (b - 1) * 32;
      final end = off + 32 > keyLen ? keyLen : off + 32;
      out.setRange(off, end, t);
    }
    return out;
  }

  Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));
  }

  /// Constant-time comparison to prevent timing side-channels.
  bool _constantTimeEq(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }

  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/backups');
  }
}

class BackupEntry {
  const BackupEntry({
    required this.path,
    required this.name,
    required this.created,
    required this.sizeBytes,
  });
  final String path;
  final String name;
  final DateTime created;
  final int sizeBytes;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
