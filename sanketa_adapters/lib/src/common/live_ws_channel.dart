/// Live WebSocket implementation of [WsChannel] for LG webOS and Samsung Tizen.
///
/// Connects over plain or secure WebSocket to the TV's control port. The URL
/// scheme determines TLS: `wss://` uses a [SecureSocket]-backed WebSocket with
/// self-signed certificate acceptance; `ws://` is plain. An optional
/// [fallbackUrl] is tried when the primary fails (e.g. Samsung wss://8002 →
/// ws://8001).
library;

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'ws_channel.dart';

class LiveWsChannel implements WsChannel {
  LiveWsChannel({required this.url, this.fallbackUrl, this.certVerifier});

  final String url;
  final String? fallbackUrl;
  final bool Function(X509Certificate cert, String host, int port)? certVerifier;

  WebSocket? _ws;
  HttpClient? _client;
  int _generation = 0;
  final _messages = StreamController<String>.broadcast();

  @override
  bool get isOpen => _ws != null && _ws!.readyState == WebSocket.open;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Future<void> connect() async {
    await close();
    final gen = ++_generation;

    try {
      _ws = await _connectTo(url);
    } on Object catch (e) {
      final fb = fallbackUrl;
      if (fb != null && _isTlsError(e)) {
        assert(() {
          dev.log('[WsChannel] Primary ${Uri.parse(url).replace(query: '').toString()} failed ($e), trying fallback ${Uri.parse(fb).replace(query: '').toString()}');
          return true;
        }());
        _ws = await _connectTo(fb);
      } else {
        rethrow;
      }
    }

    _ws!.listen(
      (data) {
        if (data is String) _messages.add(data);
      },
      onError: (Object _) {
        if (gen == _generation) _cleanup();
      },
      onDone: () {
        if (gen == _generation) _cleanup();
      },
    );
  }

  Future<WebSocket> _connectTo(String target) async {
    final uri = Uri.parse(target);
    final isSecure = uri.scheme == 'wss';

    if (isSecure) {
      _client?.close(force: true);
      _client = HttpClient()
        ..badCertificateCallback = certVerifier ?? ((_, __, ___) => true)
        ..connectionTimeout = const Duration(seconds: 8);
      return WebSocket.connect(
        target,
        headers: {'Origin': 'http://localhost'},
        customClient: _client,
      ).timeout(const Duration(seconds: 10));
    } else {
      return WebSocket.connect(
        target,
        headers: {'Origin': 'http://localhost'},
      ).timeout(const Duration(seconds: 8));
    }
  }

  @override
  Future<void> close() async {
    final ws = _ws;
    _ws = null;
    _client?.close(force: true);
    _client = null;
    if (ws != null) {
      try {
        await ws.close();
      } on Object {
        // best-effort
      }
    }
  }

  @override
  void send(String message) {
    final ws = _ws;
    if (ws == null || ws.readyState != WebSocket.open) {
      throw StateError('WebSocket not connected');
    }
    ws.add(message);
  }

  void _cleanup() {
    _ws = null;
    _client?.close(force: true);
    _client = null;
  }

  static bool _isTlsError(Object e) =>
      e is HandshakeException ||
      e is TlsException ||
      e is CertificateException;
}
