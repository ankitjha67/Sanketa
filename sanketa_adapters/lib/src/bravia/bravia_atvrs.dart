/// ATVRS (Android TV Remote Service) text injection for Sony BRAVIA.
///
/// The BRAVIA 2 II and other Google TV–based Sony TVs expose port 6466 (remote)
/// and 6467 (pairing) for the ATVRS protocol — the same one the Google TV
/// Remote app uses. Simple IP handles keys and power but has no text command;
/// this channel fills the gap with live IME batch edits.
///
/// Text typed on the phone keyboard is sent directly to the TV over TLS on the
/// local network. It is never logged, never analyzed, never leaves the phone
/// except to the target TV (PRD §14.3).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';

import '../android_tv/atv_framing.dart';
import '../android_tv/atv_pairing.dart';
import '../android_tv/der_utils.dart';
import '../android_tv/protobuf_codec.dart';

void _atvrsLog(String msg) {
  assert(() {
    // ignore: avoid_print
    print('[ATVRS] $msg');
    return true;
  }());
}

class BraviaAtvrs {
  BraviaAtvrs({
    required this.host,
    required this.certPem,
    required this.keyPem,
    this.pairingPort = 6467,
    this.remotePort = 6466,
    this.onDisconnect,
    this.certVerifier,
  });

  final String host;
  final String certPem;
  final String keyPem;
  final int pairingPort;
  final int remotePort;
  final void Function()? onDisconnect;
  final bool Function(X509Certificate cert)? certVerifier;

  SecureSocket? _socket;
  MessageDeframer? _deframer;
  StreamSubscription<Uint8List>? _sub;
  int _imeCounter = 0;
  int _fieldCounter = 0;
  String _textBuffer = '';
  bool _paired = false;

  bool get isConnected => _socket != null;
  bool get isPaired => _paired;

  String? lastPairError;

  /// Pair with the TV via the ATVRS pairing handshake on [pairingPort].
  ///
  /// The TV displays a 6-hex-digit code; [requestPin] must return it (empty
  /// string means the user cancelled). On success the TV stores our client
  /// certificate and future [connect] calls on the remote port succeed.
  Future<bool> pair(Future<String> Function() requestPin) async {
    SecureSocket? ps;
    StreamSubscription<Uint8List>? pairingSub;
    StreamController<Uint8List>? controller;
    StreamQueue<Uint8List>? acks;
    _paired = false;
    lastPairError = null;
    try {
      _atvrsLog('pairing: connecting to $host:$pairingPort ...');
      ps = await _tlsConnect(pairingPort);
      _atvrsLog('pairing: TLS connected');

      final deframer = MessageDeframer();
      controller = StreamController<Uint8List>.broadcast();
      pairingSub = ps.listen((data) {
        deframer.addChunk(data);
        for (final msg in deframer.drain()) {
          controller!.add(msg);
        }
      }, onError: (Object e) {
        if (!controller!.isClosed) controller.addError(e);
      }, onDone: () {
        if (!controller!.isClosed) controller.close();
      });

      acks = StreamQueue<Uint8List>(controller.stream);
      const ackTimeout = Duration(seconds: 10);

      // 1. PairingRequest { service_name, client_name }
      _atvrsLog('pairing step 1: PairingRequest');
      await _sendOnAsync(
          ps,
          _pairingMsg(
              10,
              ProtoWriter()
                ..writeString(1, 'atvremote')
                ..writeString(2, 'Sanketa')));
      final ack1 = await acks.next.timeout(ackTimeout);
      _atvrsLog('pairing step 1 ack: ${_parseAck(ack1)}');
      if (!_ackAccepted(ack1)) {
        lastPairError = 'TV rejected the pairing request (step 1)';
        return false;
      }

      // 2. PairingOption { input_encoding, preferred_role }
      _atvrsLog('pairing step 2: PairingOption');
      ProtoWriter _hexEnc() => ProtoWriter()
        ..writeUint(1, 3) // type = ENCODING_TYPE_HEXADECIMAL
        ..writeUint(2, 6); // symbol_length = 6
      final optMsg = _pairingMsg(
          20,
          ProtoWriter()
            ..writeMessage(1, _hexEnc()) // input_encodings only
            ..writeUint(3, 1)); // preferred_role = INPUT
      await _sendOnAsync(ps, optMsg);
      final ack2 = await acks.next.timeout(ackTimeout);
      _atvrsLog('pairing step 2 ack: ${_parseAck(ack2)}');
      if (!_ackAccepted(ack2)) {
        lastPairError = 'TV rejected the encoding option (step 2)';
        return false;
      }

      // 3. PairingConfiguration { encoding=HEXADECIMAL, client_role=INPUT }
      _atvrsLog('pairing step 3: PairingConfiguration');
      await _sendOnAsync(
          ps,
          _pairingMsg(
              30,
              ProtoWriter()
                ..writeMessage(1, _hexEnc()) // field 1 = encoding
                ..writeUint(2, 1))); // field 2 = client_role = INPUT
      final ack3 = await acks.next.timeout(ackTimeout);
      _atvrsLog('pairing step 3 ack: ${_parseAck(ack3)}');
      if (!_ackAccepted(ack3)) {
        lastPairError = 'TV rejected the configuration (step 3)';
        return false;
      }

      // 4. User enters the PIN shown on TV
      _atvrsLog('pairing step 4: requesting PIN from user');
      final pin = await requestPin();
      _atvrsLog('pairing step 4: got PIN (length=${pin.length})');
      if (pin.isEmpty) {
        lastPairError = 'cancelled';
        return false;
      }

      final codeBytes = decodeHexCode(pin);

      // Extract RSA public keys from both TLS certificates
      final clientRsa = rsaPublicKeyFromDer(pemToDer(certPem));
      final serverRsa =
          rsaPublicKeyFromDer(Uint8List.fromList(ps.peerCertificate!.der));

      final hash = computePairingHash(
        clientModulus: clientRsa.modulus,
        clientExponent: clientRsa.exponent,
        serverModulus: serverRsa.modulus,
        serverExponent: serverRsa.exponent,
        nonce: nonceFromCode(codeBytes),
      );
      if (!pairingChecksumMatches(codeBytes: codeBytes, hash: hash)) {
        lastPairError = 'Code checksum mismatch — re-check the code on your TV';
        return false;
      }

      // 5. PairingSecret { secret = hash }
      _atvrsLog('pairing step 5: sending PairingSecret');
      await _sendOnAsync(
          ps, _pairingMsg(40, ProtoWriter()..writeBytes(1, hash)));
      final ack4 = await acks.next.timeout(ackTimeout);
      _atvrsLog('pairing step 5 ack: ${_parseAck(ack4)}');
      if (!_ackAccepted(ack4)) {
        lastPairError = 'TV rejected the pairing secret (wrong code?)';
        return false;
      }

      _atvrsLog('pairing succeeded');
      _paired = true;
      return true;
    } on TimeoutException {
      _atvrsLog('pairing timeout');
      lastPairError = 'TV did not respond in time — make sure it is on';
      return false;
    } on SocketException catch (e) {
      _atvrsLog('pairing socket error: $e');
      lastPairError = 'Could not reach the TV for pairing: ${e.message}';
      return false;
    } on HandshakeException catch (e) {
      _atvrsLog('pairing TLS handshake failed: $e');
      lastPairError = 'TLS handshake failed — the TV may have reset pairing';
      return false;
    } on FormatException catch (e) {
      _atvrsLog('pairing format error: $e');
      lastPairError = 'Invalid code format — enter the 6-character hex code shown on TV';
      return false;
    } on Object catch (e) {
      _atvrsLog('pairing failed: $e');
      lastPairError = 'Pairing failed: $e';
      return false;
    } finally {
      ps?.destroy();
      await acks?.cancel(immediate: true);
      await pairingSub?.cancel();
      if (controller != null && !controller.isClosed) {
        await controller.close();
      }
    }
  }

  /// Open the remote session channel on [remotePort]. Must be paired first.
  ///
  /// The TV accepts TLS from any client but resets unpaired connections at the
  /// protocol level. After sending the active flag we wait for the first
  /// incoming message (confirming acceptance) or socket closure (rejection).
  static const int _fPing = 1;
  static const int _fKey = 2;
  static const int _fIme = 4;
  static const int _fPower = 32;
  static const int _fVolume = 64;
  static const int _fAppLink = 512;
  static const int _wantedFeatures =
      _fPing | _fKey | _fIme | _fPower | _fVolume | _fAppLink;
  int _activeFeatures = 0;

  Future<void> connect() async {
    await disconnect();
    _socket = await _tlsConnect(remotePort);
    _deframer = MessageDeframer();
    _imeCounter = 0;
    _fieldCounter = 0;
    _textBuffer = '';
    _activeFeatures = 0;

    final handshakeDone = Completer<bool>();

    _sub = _socket!.listen(
      (data) {
        _deframer!.addChunk(data);
        for (final msg in _deframer!.drain()) {
          _handleIncoming(msg);
          final tag = _firstFieldTag(msg);
          if (tag == 1 && _activeFeatures == 0) {
            _respondToConfigure(msg);
          } else if (tag == 2 && !handshakeDone.isCompleted) {
            _respondToSetActive();
          } else if (tag == 40 && !handshakeDone.isCompleted) {
            _atvrsLog('RemoteStart received — handshake complete');
            handshakeDone.complete(true);
          } else if (tag == 3 && !handshakeDone.isCompleted) {
            handshakeDone.complete(false);
          }
        }
      },
      onError: (Object _) {
        final wasConnected = _socket != null;
        _socket?.destroy();
        _socket = null;
        if (!handshakeDone.isCompleted) {
          handshakeDone.complete(false);
        } else if (wasConnected) {
          onDisconnect?.call();
        }
      },
      onDone: () {
        final wasConnected = _socket != null;
        _socket = null;
        if (!handshakeDone.isCompleted) {
          handshakeDone.complete(false);
        } else if (wasConnected) {
          onDisconnect?.call();
        }
      },
      cancelOnError: true,
    );

    final ok = await handshakeDone.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    if (ok) {
      _paired = true;
    } else {
      _socket?.destroy();
      _socket = null;
      throw StateError('not_paired');
    }
  }

  int? _firstFieldTag(Uint8List msg) {
    try {
      final r = ProtoReader(msg);
      if (!r.hasMore) return null;
      return r.readTag().number;
    } on Object {
      return null;
    }
  }

  void _respondToConfigure(Uint8List msg) {
    int? tvFeatures;
    try {
      final r = ProtoReader(msg);
      if (r.hasMore) {
        final tag = r.readTag();
        if (tag.number == 1) {
          final body = ProtoReader(r.readLengthDelimited());
          if (body.hasMore && body.readTag().number == 1) {
            tvFeatures = body.readVarint();
          }
        }
      }
    } on Object {
      // parse error
    }
    _activeFeatures = _wantedFeatures & (tvFeatures ?? 0);
    _atvrsLog('TV features=$tvFeatures, negotiated=$_activeFeatures');
    final deviceInfo = ProtoWriter()
      ..writeString(1, 'Sanketa')
      ..writeString(2, 'Sanketa')
      ..writeUint(3, 1)
      ..writeString(4, '1.0.0')
      ..writeUint(5, 2)
      ..writeString(6, 'com.sanketa.sanketa_app');
    _sendRemote(
        1,
        ProtoWriter()
          ..writeUint(1, _activeFeatures)
          ..writeMessage(2, deviceInfo));
    _atvrsLog('sent Configure response (features=$_activeFeatures)');
  }

  void _respondToSetActive() {
    _sendRemote(2, ProtoWriter()..writeUint(1, _activeFeatures));
    _atvrsLog('sent SetActive response (features=$_activeFeatures)');
  }

  /// Ensure the remote session is open, reconnecting if the socket dropped.
  /// Returns true if connected, false if connection failed.
  Future<bool> ensureConnected() async {
    if (isConnected) return true;
    try {
      await connect();
      return true;
    } on Object {
      return false;
    }
  }

  /// Append [text] to the tracked buffer and inject via IME batch edit.
  ///
  /// Uses ATVRS field 21 (RemoteImeBatchEdit) which writes directly into the
  /// TV's focused text field, bypassing the on-screen keyboard entirely.
  /// The old keycode-per-character approach moved the virtual keyboard cursor
  /// instead of typing on Google TV.
  void sendText(String text) {
    _textBuffer += text;
    _sendImeBatchEdit(_textBuffer);
  }

  /// Delete [count] characters from the end of the buffer via IME batch edit.
  void sendDelete([int count = 1]) {
    if (_textBuffer.isEmpty) {
      sendKey(67); // KEYCODE_DEL fallback when buffer is empty
      return;
    }
    final end = (_textBuffer.length - count).clamp(0, _textBuffer.length);
    _textBuffer = _textBuffer.substring(0, end);
    _sendImeBatchEdit(_textBuffer);
  }

  /// Clear the entire text field via IME batch edit.
  void sendClear() {
    _textBuffer = '';
    _sendImeBatchEdit('');
  }

  /// Submit the current text field: commit the composition, clear the buffer,
  /// then send KEYCODE_ENTER. The commit message sets the `committed` string
  /// field so the TV finalizes the IME input; without it, KEYCODE_ENTER is
  /// consumed by the on-screen keyboard.
  void submitText() {
    if (_textBuffer.isNotEmpty) {
      _sendImeCommit(_textBuffer);
    }
    _textBuffer = '';
    sendKey(66); // KEYCODE_ENTER
  }

  /// Send the full composing text state to the TV via IME batch edit (field 21).
  ///
  /// Proto: RemoteImeBatchEdit { ime_counter(1), field_counter(2),
  ///   edit_info(3) { committed(1), text_field_status(2) { start(1), end(2), value(3) } } }
  /// `committed` is an empty string during composing; set to the final text
  /// by [_sendImeCommit] when submitting.
  void _sendImeBatchEdit(String fullText) {
    final imeObject = ProtoWriter()
      ..writeUint(1, fullText.length) // start cursor
      ..writeUint(2, fullText.length) // end cursor
      ..writeString(3, fullText); // value
    final editInfo = ProtoWriter()
      ..writeString(1, '') // committed (empty during composing)
      ..writeMessage(2, imeObject); // text_field_status
    _sendRemote(
        21,
        ProtoWriter()
          ..writeUint(1, _imeCounter)
          ..writeUint(2, _fieldCounter)
          ..writeMessage(3, editInfo));
  }

  /// Commit the composition: tells the TV to finalize the text in the focused
  /// field. The `committed` string carries the final text; `value` is cleared.
  void _sendImeCommit(String text) {
    final imeObject = ProtoWriter()
      ..writeUint(1, 0) // start
      ..writeUint(2, 0) // end
      ..writeString(3, ''); // value (composing cleared)
    final editInfo = ProtoWriter()
      ..writeString(1, text) // committed (finalize this text)
      ..writeMessage(2, imeObject); // text_field_status
    _sendRemote(
        21,
        ProtoWriter()
          ..writeUint(1, _imeCounter)
          ..writeUint(2, _fieldCounter)
          ..writeMessage(3, editInfo));
  }

  /// Inject a key event (e.g. backspace=67, enter=66). Direction 3 = short tap.
  /// Proto: RemoteKeyInject (field 10) { key_code(1), direction(2) }.
  void sendKey(int keyCode, {int direction = 3}) {
    _sendRemote(
        10,
        ProtoWriter()
          ..writeUint(1, keyCode)
          ..writeUint(2, direction));
  }

  /// Launch an app by its deep-link URI via ATVRS field 90 (appLinkLaunch).
  void launchApp(String deepLinkUri) {
    _sendRemote(90, ProtoWriter()..writeString(1, deepLinkUri));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    _socket?.destroy();
    _socket = null;
    _textBuffer = '';
  }

  // -- internal ---------------------------------------------------------------

  Future<SecureSocket> _tlsConnect(int port) async {
    final ctx = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(certPem))
      ..usePrivateKeyBytes(utf8.encode(keyPem));
    return SecureSocket.connect(
      host, port,
      context: ctx,
      onBadCertificate: certVerifier ?? (_) => true,
      timeout: const Duration(seconds: 8),
    );
  }

  void _handleIncoming(Uint8List msg) {
    final r = ProtoReader(msg);
    while (r.hasMore) {
      final tag = r.readTag();
      switch (tag.number) {
        case 8 when tag.wireType == WireType.lengthDelimited:
          // RemotePingRequest (field 8) — reply with RemotePingResponse (field 9)
          final inner = ProtoReader(r.readLengthDelimited());
          inner.readTag();
          final val = inner.readVarint();
          _sendRemote(9, ProtoWriter()..writeUint(1, val));
        case 20 when tag.wireType == WireType.lengthDelimited:
          // RemoteImeKeyInject — TV says a text field was focused.
          // Extract counters so our batch edits are accepted.
          _parseImeKeyInject(r.readLengthDelimited());
        case 22 when tag.wireType == WireType.lengthDelimited:
          // RemoteImeShowRequest — TV echoes updated field status.
          _parseImeShowRequest(r.readLengthDelimited());
        default:
          r.skip(tag.wireType);
      }
    }
  }

  void _parseImeKeyInject(Uint8List data) {
    // RemoteImeKeyInject { app_info(1) { counter(1) }, text_field_status(2) { counter_field(1) } }
    final r = ProtoReader(data);
    final oldField = _fieldCounter;
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag.number == 1 && tag.wireType == WireType.lengthDelimited) {
        final appInfo = ProtoReader(r.readLengthDelimited());
        while (appInfo.hasMore) {
          final at = appInfo.readTag();
          if (at.number == 1 && at.wireType == WireType.varint) {
            _imeCounter = appInfo.readVarint();
          } else {
            appInfo.skip(at.wireType);
          }
        }
      } else if (tag.number == 2 && tag.wireType == WireType.lengthDelimited) {
        final tfs = ProtoReader(r.readLengthDelimited());
        while (tfs.hasMore) {
          final tt = tfs.readTag();
          if (tt.number == 1 && tt.wireType == WireType.varint) {
            _fieldCounter = tfs.readVarint();
          } else {
            tfs.skip(tt.wireType);
          }
        }
      } else {
        r.skip(tag.wireType);
      }
    }
    if (_fieldCounter != oldField) _textBuffer = '';
  }

  void _parseImeShowRequest(Uint8List data) {
    // RemoteImeShowRequest { remote_text_field_status(2) { counter_field(1) } }
    final r = ProtoReader(data);
    final oldField = _fieldCounter;
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag.number == 2 && tag.wireType == WireType.lengthDelimited) {
        final tfs = ProtoReader(r.readLengthDelimited());
        while (tfs.hasMore) {
          final tt = tfs.readTag();
          if (tt.number == 1 && tt.wireType == WireType.varint) {
            _fieldCounter = tfs.readVarint();
          } else {
            tfs.skip(tt.wireType);
          }
        }
      } else {
        r.skip(tag.wireType);
      }
    }
    if (_fieldCounter != oldField) _textBuffer = '';
  }

  void _sendRemote(int field, ProtoWriter inner) {
    final body = (ProtoWriter()..writeMessage(field, inner)).toBytes();
    final socket = _socket;
    if (socket == null) throw StateError('ATVRS channel not connected');
    socket.add(frameMessage(body));
  }

  Future<void> _sendOnAsync(SecureSocket sock, Uint8List body) async {
    sock.add(frameMessage(body));
    await sock.flush();
  }

  /// Wrap a pairing payload in an OuterMessage envelope.
  /// Proto field 1 = protocol_version (2), field 2 = status (200 = OK).
  static Uint8List _pairingMsg(int field, ProtoWriter inner) => (ProtoWriter()
        ..writeUint(1, 2) // protocol_version = 2
        ..writeUint(2, 200) // status = STATUS_OK
        ..writeMessage(field, inner))
      .toBytes();

  static bool _ackAccepted(Uint8List raw) {
    final status = _parseAck(raw).$2;
    return status == null || status == 200;
  }

  /// Parse an OuterMessage ack: returns (protocol_version, status).
  static (int?, int?) _parseAck(Uint8List raw) {
    try {
      final r = ProtoReader(raw);
      int? protoVersion;
      int? status;
      while (r.hasMore) {
        final tag = r.readTag();
        if (tag.number == 1 && tag.wireType == WireType.varint) {
          protoVersion = r.readVarint();
        } else if (tag.number == 2 && tag.wireType == WireType.varint) {
          status = r.readVarint();
        } else {
          r.skip(tag.wireType);
        }
      }
      return (protoVersion, status);
    } on Object {
      return (null, null);
    }
  }
}
