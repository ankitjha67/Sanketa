/// Live TLS socket implementation of [AtvChannel] for Android TV Remote
/// Service protocol v2 (port 6466).
///
/// Handles TLS with a client certificate (the same one used for ATVRS pairing),
/// varint-length message framing, the RemoteConfigure + RemoteSetActive
/// handshake required by the protocol, automatic ping replies, and
/// bidirectional protobuf message streams.
///
/// Keeps the connection alive with periodic client-side pings and automatically
/// reconnects when the socket drops (unless the TV explicitly rejected us).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

import 'atv_channel.dart';
import 'atv_framing.dart';
import 'atv_messages.dart';
import 'protobuf_codec.dart';

void _log(String msg) {
  assert(() {
    // ignore: avoid_print
    print('[ATV] $msg');
    return true;
  }());
}

class LiveAtvChannel implements AtvChannel {
  LiveAtvChannel({
    required this.host,
    required this.certPem,
    required this.keyPem,
    this.port = 6466,
  });

  final String host;
  final String certPem;
  final String keyPem;
  final int port;

  SecureSocket? _socket;
  StreamSubscription<Uint8List>? _sub;
  MessageDeframer? _deframer;
  final _messages = StreamController<Uint8List>.broadcast();
  bool _gotError = false;

  Timer? _keepaliveTimer;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  DateTime _lastReceived = DateTime.now();
  int _reconnectAttempts = 0;
  bool _intentionallyClosed = false;
  bool _handshakeComplete = false;

  // ATVRS feature flags (bitmask).
  static const int _fPing = 1;
  static const int _fKey = 2;
  static const int _fIme = 4;
  static const int _fPower = 32;
  static const int _fVolume = 64;
  static const int _fAppLink = 512;
  static const int _wantedFeatures =
      _fPing | _fKey | _fIme | _fPower | _fVolume | _fAppLink;
  int _activeFeatures = 0;

  @override
  bool get isOpen => _socket != null && _handshakeComplete;

  @override
  bool get gotError => _gotError;

  @override
  int get negotiatedFeatures => _activeFeatures;

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  Future<void> connect() async {
    _intentionallyClosed = false;
    _reconnectAttempts = 0;
    _gotError = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _log('connecting to $host:$port ...');
    _stopTimers();
    await _closeSocket();
    _gotError = false;
    _activeFeatures = 0;
    _handshakeComplete = false;
    final ctx = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(certPem))
      ..usePrivateKeyBytes(utf8.encode(keyPem));
    _socket = await SecureSocket.connect(
      host,
      port,
      context: ctx,
      onBadCertificate: (_) => true,
      timeout: const Duration(seconds: 8),
    );
    _log('TLS socket open');
    _deframer = MessageDeframer();

    final handshakeDone = Completer<bool>();

    _sub = _socket!.listen(
      (data) {
        _lastReceived = DateTime.now();
        _deframer!.addChunk(data);
        for (final msg in _deframer!.drain()) {
          _handleIncoming(msg);
          _messages.add(msg);

          final tag = _firstField(msg);
          if (tag == 1 && _activeFeatures == 0) {
            _respondToConfigure(msg);
          } else if (tag == 2 && !handshakeDone.isCompleted) {
            _respondToSetActive();
          } else if (tag == 40 && !handshakeDone.isCompleted) {
            _log('RemoteStart received — handshake complete');
            handshakeDone.complete(true);
          } else if (tag == 3) {
            if (!handshakeDone.isCompleted) handshakeDone.complete(false);
          }
        }
      },
      onError: (Object e) {
        _log('socket onError: $e');
        if (!handshakeDone.isCompleted) handshakeDone.complete(false);
        _onSocketLost();
      },
      onDone: () {
        _log('socket onDone (closed by TV)');
        if (!handshakeDone.isCompleted) handshakeDone.complete(false);
        _onSocketLost();
      },
    );

    final ok = await handshakeDone.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    if (!ok || _socket == null) {
      _log('handshake failed: ok=$ok socket=${_socket != null}');
      _socket?.destroy();
      _socket = null;
      throw StateError('not_paired');
    }

    _handshakeComplete = true;
    _log('handshake accepted (features=$_activeFeatures), starting keepalive');
    _lastReceived = DateTime.now();
    _startKeepalive();
  }

  void _respondToConfigure(Uint8List msg) {
    final tvFeatures = _extractCode1(msg) ?? 0;
    _activeFeatures = _wantedFeatures & tvFeatures;
    _log('TV features=$tvFeatures, negotiated=$_activeFeatures');
    final deviceInfo = ProtoWriter()
      ..writeString(1, 'Sanketa')
      ..writeString(2, 'Sanketa')
      ..writeUint(3, 1)
      ..writeString(4, '1.0.0')
      ..writeUint(5, 2)
      ..writeString(6, 'com.sanketa.sanketa_app');
    final reply = ProtoWriter()
      ..writeMessage(
          1,
          ProtoWriter()
            ..writeUint(1, _activeFeatures)
            ..writeMessage(2, deviceInfo));
    _sendRaw(reply.toBytes());
    _log('sent Configure response (features=$_activeFeatures)');
  }

  void _respondToSetActive() {
    final reply = ProtoWriter()
      ..writeMessage(2, ProtoWriter()..writeUint(1, _activeFeatures));
    _sendRaw(reply.toBytes());
    _log('sent SetActive response (features=$_activeFeatures)');
  }

  void _startKeepalive() {
    _stopTimers();

    _keepaliveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final s = _socket;
      if (s == null) return;
      try {
        s.add(frameMessage(Uint8List.fromList(buildPingResponse(0))));
      } on Object {
        // Socket dead — onDone/onError will handle reconnect.
      }
    });

    // Check every 15s that we've heard from the TV recently.
    // Most Android TVs ping every 5-10s, so 60s of silence = dead socket.
    _watchdogTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_socket == null || _intentionallyClosed) return;
      final gap = DateTime.now().difference(_lastReceived);
      if (gap > const Duration(seconds: 60)) {
        _scheduleReconnect();
      }
    });
  }

  void _onSocketLost() {
    _socket = null;
    _log('socket lost: intentionallyClosed=$_intentionallyClosed gotError=$_gotError');
    if (!_intentionallyClosed && !_gotError) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _stopTimers();
    _handshakeComplete = false;
    _sub?.cancel();
    _sub = null;
    _socket?.destroy();
    _socket = null;
    if (_intentionallyClosed || _gotError) return;
    _reconnectAttempts++;
    if (_reconnectAttempts > 120) {
      _log('giving up reconnect after $_reconnectAttempts attempts');
      return;
    }
    final delaySec = min(2 * _reconnectAttempts, 15);
    _log('reconnect #$_reconnectAttempts in ${delaySec}s');
    _reconnectTimer = Timer(Duration(seconds: delaySec), () async {
      _reconnectTimer = null;
      if (_intentionallyClosed || _gotError) return;
      try {
        await _doConnect();
        _reconnectAttempts = 0;
        _log('reconnect succeeded');
      } on Object catch (e) {
        _log('reconnect failed: $e');
        _scheduleReconnect();
      }
    });
  }

  void _stopTimers() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  @override
  Future<void> close() async {
    _intentionallyClosed = true;
    _stopTimers();
    await _closeSocket();
  }

  Future<void> _closeSocket() async {
    _handshakeComplete = false;
    await _sub?.cancel();
    _sub = null;
    _socket?.destroy();
    _socket = null;
    _deframer = null;
  }

  @override
  void sendMessage(List<int> body) {
    _sendRaw(body);
  }

  void _sendRaw(List<int> body) {
    final socket = _socket;
    if (socket == null) throw StateError('ATV channel not connected');
    socket.add(frameMessage(Uint8List.fromList(body)));
  }

  int? _firstField(Uint8List msg) {
    try {
      final r = ProtoReader(msg);
      if (!r.hasMore) return null;
      return r.readTag().number;
    } on Object {
      return null;
    }
  }

  int? _extractCode1(Uint8List msg) {
    try {
      final r = ProtoReader(msg);
      if (!r.hasMore) return null;
      final outer = r.readTag();
      if (outer.number != 1) return null;
      final body = ProtoReader(r.readLengthDelimited());
      if (!body.hasMore) return null;
      final f1 = body.readTag();
      if (f1.number != 1) return null;
      return body.readVarint();
    } on Object {
      return null;
    }
  }

  void _handleIncoming(Uint8List msg) {
    _log('received frame (${msg.length}B)');
    try {
      final r = ProtoReader(msg);
      while (r.hasMore) {
        final tag = r.readTag();
        _log('  field=${tag.number} wire=${tag.wireType}');
        if (tag.number == 8 && tag.wireType == WireType.lengthDelimited) {
          final inner = ProtoReader(r.readLengthDelimited());
          inner.readTag();
          final val = inner.readVarint();
          final resp = (ProtoWriter()
                ..writeMessage(9, ProtoWriter()..writeUint(1, val)))
              .toBytes();
          _sendRaw(resp);
          _log('  -> ping response val=$val');
        } else if (tag.number == 3) {
          final errBytes = r.readLengthDelimited();
          _log('  RemoteError received (${errBytes.length}B)');
          try {
            final er = ProtoReader(errBytes);
            while (er.hasMore) {
              final et = er.readTag();
              if (et.wireType == WireType.varint) {
                er.readVarint();
                _log('    err f${et.number} (varint)');
              } else if (et.wireType == WireType.lengthDelimited) {
                final s = er.readLengthDelimited();
                _log('    err field ${et.number} (${s.length}B)');
              } else {
                er.skip(et.wireType);
              }
            }
          } on Object {
            // best-effort parse
          }
        } else if (tag.number == 1) {
          final cfgBytes = r.readLengthDelimited();
          _log('  Configure body (${cfgBytes.length}B)');
          try {
            final cr = ProtoReader(cfgBytes);
            while (cr.hasMore) {
              final ct = cr.readTag();
              if (ct.wireType == WireType.varint) {
                cr.readVarint();
                _log('    cfg f${ct.number} (varint)');
              } else if (ct.wireType == WireType.lengthDelimited) {
                final s = cr.readLengthDelimited();
                _log('    config field ${ct.number} (${s.length}B)');
              } else {
                cr.skip(ct.wireType);
              }
            }
          } on Object {
            // best-effort parse
          }
        } else {
          r.skip(tag.wireType);
        }
      }
    } on Object catch (e) {
      _log('  parse error: $e');
    }
  }
}
