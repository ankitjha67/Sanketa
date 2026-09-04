/// RemoteMessage builders for the Android TV remote protocol v2.
///
/// Built on the verified [ProtoWriter]. The *shape* of each message is correct
/// protobuf; the **field numbers** below come from the documented androidtvremote2
/// schema and are the one thing that must be confirmed against a real device in
/// Phase 0 — they are centralised here so that confirmation is a one-file change.
library;

import 'dart:typed_data';

import 'atv_keymap.dart';
import 'protobuf_codec.dart';

/// Field numbers inside RemoteMessage / PairingMessage.
/// FLAGGED: validate against a real Android TV in Phase 0.
class RemoteField {
  static const int keyInject = 10;
  static const int imeKeyInject = 20;
  static const int pingResponse = 9;
  static const int appLinkLaunch = 90;

  // Pairing message set (separate 6467 connection):
  static const int pairingRequest = 10;
  static const int pairingOption = 20;
  static const int pairingConfiguration = 30;
  static const int pairingSecret = 40;
}

/// RemoteDirection enum values (documented): SHORT=3, START_LONG=1, END_LONG=2.
int atvDirectionCode(AtvDirection d) => switch (d) {
      AtvDirection.startLong => 1,
      AtvDirection.endLong => 2,
      AtvDirection.short => 3,
    };

/// RemoteMessage{ remote_key_inject { key_code, direction } }.
Uint8List buildKeyInject(int keyCode, AtvDirection direction) {
  final inner = ProtoWriter()
    ..writeUint(1, keyCode)
    ..writeUint(2, atvDirectionCode(direction));
  return (ProtoWriter()..writeMessage(RemoteField.keyInject, inner)).toBytes();
}

/// RemoteMessage carrying IME text. FLAGGED: real IME injection uses a richer
/// batch-edit message; this is the minimal insert shape pending Phase 0.
Uint8List buildImeText(String text) {
  final inner = ProtoWriter()..writeString(1, text);
  return (ProtoWriter()..writeMessage(RemoteField.imeKeyInject, inner)).toBytes();
}

/// RemoteMessage launching an app by its app-link URI. FLAGGED for Phase 0.
Uint8List buildAppLink(String link) {
  final inner = ProtoWriter()..writeString(1, link);
  return (ProtoWriter()..writeMessage(RemoteField.appLinkLaunch, inner)).toBytes();
}

/// Reply to the TV's periodic ping to keep the session alive.
Uint8List buildPingResponse(int value) {
  final inner = ProtoWriter()..writeUint(1, value);
  return (ProtoWriter()..writeMessage(RemoteField.pingResponse, inner)).toBytes();
}

// --- Pairing message set -----------------------------------------------------

Uint8List buildPairingRequest(String serviceName, String clientName) {
  final inner = ProtoWriter()
    ..writeString(1, serviceName)
    ..writeString(2, clientName);
  return (ProtoWriter()..writeMessage(RemoteField.pairingRequest, inner)).toBytes();
}

Uint8List buildPairingOption() {
  // Encoding = hexadecimal, symbol length 6 (documented default).
  final inner = ProtoWriter()..writeUint(1, 6);
  return (ProtoWriter()..writeMessage(RemoteField.pairingOption, inner)).toBytes();
}

Uint8List buildPairingConfiguration() {
  final inner = ProtoWriter()..writeUint(1, 6);
  return (ProtoWriter()..writeMessage(RemoteField.pairingConfiguration, inner))
      .toBytes();
}

Uint8List buildPairingSecret(List<int> hash) {
  final inner = ProtoWriter()..writeBytes(1, hash);
  return (ProtoWriter()..writeMessage(RemoteField.pairingSecret, inner)).toBytes();
}
