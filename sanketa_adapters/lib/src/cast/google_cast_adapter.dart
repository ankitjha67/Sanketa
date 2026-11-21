/// Google Cast (CastV2) media-casting adapter — Rung 1 casting (FR-7.1).
///
/// Connects to a Chromecast-compatible device (BRAVIA, Chromecast, Android TV,
/// etc.) over TLS on port 8009, launches the Default Media Receiver, and
/// streams local media via the CastV2 JSON media protocol.
///
/// This is a [MediaCaster] only — it does not implement [ControlAdapter]
/// because remote-control is handled by separate protocol-specific adapters
/// (ATVRS, BRAVIA IP, etc.). The casting layer calls this independently.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:sanketa_core/sanketa_core.dart';

import 'cast_channel.dart';

const _defaultMediaReceiver = 'CC1AD845';

const _nsConnection = 'urn:x-cast:com.google.cast.tp.connection';
const _nsHeartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
const _nsReceiver = 'urn:x-cast:com.google.cast.receiver';
const _nsMedia = 'urn:x-cast:com.google.cast.media';

class GoogleCastAdapter implements MediaCaster {
  GoogleCastAdapter({required String host, int port = 8009})
      : _host = host,
        _port = port;

  final String _host;
  final int _port;

  String get host => _host;

  SecureSocket? _socket;
  final _buf = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _sub;
  Timer? _heartbeat;
  int _requestId = 0;

  String? _transportId;
  int? _mediaSessionId;
  bool _connected = false;

  final _incoming = StreamController<CastMessage>.broadcast();

  Future<bool> connect() async {
    try {
      _socket = await SecureSocket.connect(
        _host,
        _port,
        onBadCertificate: (_) => true,
        timeout: const Duration(seconds: 8),
      );
      _sub = _socket!.listen(
        _onData,
        onError: (_) => _cleanup(),
        onDone: _cleanup,
      );
      _connected = true;

      _send(_nsConnection, 'receiver-0',
          '{"type":"CONNECT","origin":{}}');

      _heartbeat = Timer.periodic(
          const Duration(seconds: 5), (_) => _ping());

      return true;
    } on Object {
      _cleanup();
      return false;
    }
  }

  Future<bool> _launchReceiver() async {
    // Drain any unsolicited RECEIVER_STATUS the TV sent after CONNECT —
    // otherwise _waitFor below catches the stale status (empty app list)
    // instead of the one triggered by our LAUNCH.
    await _waitFor(
      (m) => m.namespace == _nsReceiver,
      timeout: const Duration(seconds: 1),
    );

    _send(_nsReceiver, 'receiver-0',
        jsonEncode({
          'type': 'LAUNCH',
          'appId': _defaultMediaReceiver,
          'requestId': ++_requestId,
        }));

    // Wait for a RECEIVER_STATUS that has the Default Media Receiver in its
    // applications list, or a LAUNCH_ERROR. Intermediate status updates
    // without the app are skipped.
    final status = await _waitFor(
      (m) {
        if (m.namespace != _nsReceiver) return false;
        final p = _tryDecode(m.payloadUtf8);
        if (p == null) return false;
        final type = p['type'] as String?;
        if (type == 'LAUNCH_ERROR') return true;
        if (type != 'RECEIVER_STATUS') return false;
        final statusMap = p['status'] as Map<String, Object?>?;
        final apps = statusMap?['applications'] as List?;
        return apps != null &&
            apps.any((a) => a is Map && a['appId'] == _defaultMediaReceiver);
      },
      timeout: const Duration(seconds: 15),
    );

    if (status == null) return false;
    final payload = _tryDecode(status.payloadUtf8);
    if (payload?['type'] == 'LAUNCH_ERROR') return false;

    final statusMap = payload?['status'] as Map<String, Object?>?;
    final apps = statusMap?['applications'] as List?;
    if (apps == null || apps.isEmpty) return false;

    final app = apps.firstWhere(
      (a) => a is Map && a['appId'] == _defaultMediaReceiver,
      orElse: () => apps.first,
    ) as Map;
    _transportId = app['transportId'] as String?;
    if (_transportId == null) return false;

    _send(_nsConnection, _transportId!,
        '{"type":"CONNECT","origin":{}}');

    return true;
  }

  @override
  Future<CastResult> castUri(
    String uri, {
    String? mimeType,
    String? title,
    bool live = false,
  }) async {
    if (!_connected) {
      final ok = await connect();
      if (!ok) {
        return const CastResult.failure(
            'Could not connect to the Cast device. '
            'Make sure it is powered on and on the same WiFi network.');
      }
    }

    if (_transportId == null) {
      var launched = await _launchReceiver();
      if (!launched) {
        // Retry once — the TV may need a moment to start the receiver.
        launched = await _launchReceiver();
      }
      if (!launched) {
        return const CastResult.failure(
            'Could not launch the media receiver on the TV. '
            'The device may not support Google Cast.');
      }
    }

    final isLive = live ||
        mimeType == 'application/x-mpegurl' ||
        mimeType == 'application/vnd.apple.mpegurl';

    final media = <String, Object?>{
      'contentId': uri,
      'streamType': isLive ? 'LIVE' : 'BUFFERED',
      if (mimeType != null) 'contentType': mimeType,
      if (title != null) 'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': title,
      },
    };

    final loadMsg = jsonEncode({
      'type': 'LOAD',
      'media': media,
      'autoplay': true,
      'requestId': ++_requestId,
    });
    dev.log('[Cast] LOAD: $loadMsg', name: 'GoogleCast');
    _send(_nsMedia, _transportId!, loadMsg);

    final response = await _waitFor(
      (m) {
        if (m.namespace != _nsMedia) return false;
        final p = _tryDecode(m.payloadUtf8);
        if (p == null) return false;
        final t = p['type'] as String?;
        return t == 'MEDIA_STATUS' || t == 'LOAD_FAILED' || t == 'INVALID_REQUEST';
      },
      timeout: const Duration(seconds: 15),
    );

    if (response == null) {
      dev.log('[Cast] No response within 15s', name: 'GoogleCast');
      return const CastResult.failure(
          'The TV did not respond to the cast request. Try again.');
    }

    final rPayload = _tryDecode(response.payloadUtf8);
    final type = rPayload?['type'] as String?;
    dev.log('[Cast] Response: type=$type payload=$rPayload', name: 'GoogleCast');
    if (type == 'LOAD_FAILED' || type == 'INVALID_REQUEST') {
      return CastResult.failure(
          rPayload?['reason'] as String? ??
              'The TV could not play this file. Try a different format.');
    }

    final statuses = rPayload?['status'] as List?;
    if (statuses != null && statuses.isNotEmpty) {
      _mediaSessionId = statuses.first['mediaSessionId'] as int?;
    }

    return const CastResult.success();
  }

  @override
  Future<CastResult> castPause() async => _mediaCommand('PAUSE');

  @override
  Future<CastResult> castResume() async => _mediaCommand('PLAY');

  @override
  Future<CastResult> castStop() async {
    final r = await _mediaCommand('STOP');
    await disconnect();
    return r;
  }

  Future<CastResult> _mediaCommand(String type) async {
    if (_transportId == null || _mediaSessionId == null) {
      return const CastResult.failure('No active cast session.');
    }

    _send(_nsMedia, _transportId!, jsonEncode({
      'type': type,
      'mediaSessionId': _mediaSessionId,
      'requestId': ++_requestId,
    }));

    final ack = await _waitFor(
      (m) => m.namespace == _nsMedia,
      timeout: const Duration(seconds: 5),
    );

    if (ack == null) {
      return CastResult.failure(
          'The TV did not respond to $type. It may have disconnected.');
    }

    return const CastResult.success();
  }

  Future<void> disconnect() async {
    if (_transportId != null) {
      try {
        _send(_nsConnection, _transportId!, '{"type":"CLOSE"}');
      } on Object { /* best-effort */ }
    }
    _cleanup();
  }

  // --- Wire-level plumbing ---------------------------------------------------

  void _send(String namespace, String destinationId, String payload) {
    final msg = CastMessage(
      sourceId: 'sender-0',
      destinationId: destinationId,
      namespace: namespace,
      payloadUtf8: payload,
    );
    _socket?.add(frameCastMessage(msg));
  }

  void _ping() {
    try {
      _send(_nsHeartbeat, 'receiver-0', '{"type":"PING"}');
    } on Object {
      _cleanup();
    }
  }

  void _onData(Uint8List chunk) {
    _buf.add(chunk);
    var buffer = _buf.toBytes();
    _buf.clear();

    while (true) {
      final result = readFramedMessage(buffer);
      if (result == null) break;
      final (msg, consumed) = result;
      buffer = buffer.sublist(consumed);

      if (msg.namespace == _nsHeartbeat) {
        final p = _tryDecode(msg.payloadUtf8);
        if (p?['type'] == 'PING') {
          _send(_nsHeartbeat, msg.sourceId, '{"type":"PONG"}');
        }
        continue;
      }

      _incoming.add(msg);
    }

    if (buffer.isNotEmpty) _buf.add(buffer);
  }

  Future<CastMessage?> _waitFor(
    bool Function(CastMessage) test, {
    required Duration timeout,
  }) {
    final completer = Completer<CastMessage?>();
    late StreamSubscription<CastMessage> sub;
    Timer? timer;

    sub = _incoming.stream.listen((msg) {
      if (test(msg)) {
        timer?.cancel();
        sub.cancel();
        if (!completer.isCompleted) completer.complete(msg);
      }
    });

    timer = Timer(timeout, () {
      sub.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  void _cleanup() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _sub?.cancel();
    _sub = null;
    try {
      _socket?.destroy();
    } on Object { /* already closed */ }
    _socket = null;
    _connected = false;
    _transportId = null;
    _mediaSessionId = null;
    _buf.clear();
  }

  static Map<String, Object?>? _tryDecode(String s) {
    try {
      return jsonDecode(s) as Map<String, Object?>?;
    } on Object {
      return null;
    }
  }
}

/// Probe whether a host accepts CastV2 TLS connections on port 8009.
/// Returns true if the handshake succeeds within [timeout].
Future<bool> probeGoogleCast(String host,
    {Duration timeout = const Duration(seconds: 4)}) async {
  try {
    final socket = await SecureSocket.connect(
      host,
      8009,
      onBadCertificate: (_) => true,
      timeout: timeout,
    );
    await socket.close();
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}
