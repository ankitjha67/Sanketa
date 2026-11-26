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
  static const int configure = 1;
  static const int setActive = 2;
  static const int error = 3;
  static const int pingRequest = 8;
  static const int pingResponse = 9;
  static const int keyInject = 10;
  static const int imeKeyInject = 20;
  static const int imeBatchEdit = 21;
  static const int imeShowRequest = 22;
  static const int remoteStart = 40;
  static const int setVolumeLevel = 50;
  static const int voiceBegin = 30; // FLAGGED: validate Phase 0
  static const int voicePayload = 31; // FLAGGED: validate Phase 0
  static const int voiceEnd = 32; // FLAGGED: validate Phase 0
  static const int setAudioDevice = 60; // FLAGGED: validate Phase 0
  static const int resetAudioDevice = 61; // FLAGGED: validate Phase 0
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

/// RemoteMessage{ remote_ime_batch_edit { ime_counter, field_counter,
/// edit_info { committed, text_field_status { start, end, value } } } }.
///
/// Proto: RemoteImeBatchEdit (field 21) → RemoteEditInfo → RemoteImeObject.
/// `committed` (field 1) is a string: empty during composing, set to the
/// final text when committing. `text_field_status.value` (field 2→3) holds
/// the composing text. Counter is a module-level monotonic int; callers that
/// send many edits in one session should pass a shared counter.
Uint8List buildImeText(String text, {int imeCounter = 1, int fieldCounter = 1,
    int? start, int? end}) {
  final cursor = start ?? text.length;
  final imeObject = ProtoWriter()
    ..writeUint(1, cursor) // start
    ..writeUint(2, end ?? cursor) // end
    ..writeString(3, text); // value
  final editInfo = ProtoWriter()
    ..writeString(1, '') // committed (empty during composing)
    ..writeMessage(2, imeObject); // text_field_status
  final batchEdit = ProtoWriter()
    ..writeUint(1, imeCounter) // ime_counter
    ..writeUint(2, fieldCounter) // field_counter
    ..writeMessage(3, editInfo); // edit_info
  return (ProtoWriter()..writeMessage(RemoteField.imeBatchEdit, batchEdit))
      .toBytes();
}

/// Commit the composition: tells the TV to finalize the text in the focused
/// field. After this, KEYCODE_ENTER triggers the field's IME action (search,
/// done, go) instead of being consumed by the on-screen keyboard.
Uint8List buildImeCommit(String text, {int imeCounter = 1,
    int fieldCounter = 1}) {
  final imeObject = ProtoWriter()
    ..writeUint(1, 0) // start
    ..writeUint(2, 0) // end
    ..writeString(3, ''); // value (composing cleared)
  final editInfo = ProtoWriter()
    ..writeString(1, text) // committed (finalize this text)
    ..writeMessage(2, imeObject); // text_field_status
  final batchEdit = ProtoWriter()
    ..writeUint(1, imeCounter) // ime_counter
    ..writeUint(2, fieldCounter) // field_counter
    ..writeMessage(3, editInfo); // edit_info
  return (ProtoWriter()..writeMessage(RemoteField.imeBatchEdit, batchEdit))
      .toBytes();
}

/// RemoteMessage launching an app by its app-link URI. FLAGGED for Phase 0.
Uint8List buildAppLink(String link) {
  final inner = ProtoWriter()..writeString(1, link);
  return (ProtoWriter()..writeMessage(RemoteField.appLinkLaunch, inner))
      .toBytes();
}

/// Reply to the TV's periodic ping to keep the session alive.
Uint8List buildPingResponse(int value) {
  final inner = ProtoWriter()..writeUint(1, value);
  return (ProtoWriter()..writeMessage(RemoteField.pingResponse, inner))
      .toBytes();
}

/// RemoteMessage{ remote_set_preferred_audio_device { device_id } }.
/// Tells the TV to route audio to the specified output device. FLAGGED for Phase 0.
Uint8List buildSetAudioDevice(String deviceId) {
  final inner = ProtoWriter()..writeString(1, deviceId);
  return (ProtoWriter()..writeMessage(RemoteField.setAudioDevice, inner))
      .toBytes();
}

/// RemoteMessage{ remote_reset_preferred_audio_device { } }.
/// Reverts audio routing to the TV's default output. FLAGGED for Phase 0.
Uint8List buildResetAudioDevice() {
  final inner = ProtoWriter();
  return (ProtoWriter()..writeMessage(RemoteField.resetAudioDevice, inner))
      .toBytes();
}

/// RemoteMessage{ remote_voice_begin { } }.
/// Signals the TV that voice audio streaming is starting. FLAGGED for Phase 0.
Uint8List buildVoiceBegin() {
  final inner = ProtoWriter();
  return (ProtoWriter()..writeMessage(RemoteField.voiceBegin, inner))
      .toBytes();
}

/// RemoteMessage{ remote_voice_end { } }.
/// Signals the TV that voice audio streaming has stopped. FLAGGED for Phase 0.
Uint8List buildVoiceEnd() {
  final inner = ProtoWriter();
  return (ProtoWriter()..writeMessage(RemoteField.voiceEnd, inner))
      .toBytes();
}

// --- Pairing message set -----------------------------------------------------

Uint8List buildPairingRequest(String serviceName, String clientName) {
  final inner = ProtoWriter()
    ..writeString(1, serviceName)
    ..writeString(2, clientName);
  return (ProtoWriter()..writeMessage(RemoteField.pairingRequest, inner))
      .toBytes();
}

Uint8List buildPairingOption() {
  // Encoding = hexadecimal, symbol length 6 (documented default).
  final inner = ProtoWriter()..writeUint(1, 6);
  return (ProtoWriter()..writeMessage(RemoteField.pairingOption, inner))
      .toBytes();
}

Uint8List buildPairingConfiguration() {
  final inner = ProtoWriter()..writeUint(1, 6);
  return (ProtoWriter()..writeMessage(RemoteField.pairingConfiguration, inner))
      .toBytes();
}

Uint8List buildPairingSecret(List<int> hash) {
  final inner = ProtoWriter()..writeBytes(1, hash);
  return (ProtoWriter()..writeMessage(RemoteField.pairingSecret, inner))
      .toBytes();
}
