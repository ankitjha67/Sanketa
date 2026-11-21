import 'dart:async';
import 'dart:typed_data';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:sanketa_adapters/src/android_tv/atv_pairing.dart';
import 'package:sanketa_adapters/src/android_tv/protobuf_codec.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

/// A fake channel: records sent RemoteMessage bodies and can push incoming ones.
/// With [autoAck] it emits an ack after every send, which drives the pairing
/// session's request→ack sequence.
class FakeAtvChannel implements AtvChannel {
  FakeAtvChannel({this.autoAck = false, this.fakeFeatures = 0});

  final bool autoAck;
  final int fakeFeatures;
  bool _open = false;
  final List<Uint8List> sent = [];
  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();

  @override
  bool get isOpen => _open;

  @override
  bool get gotError => false;

  @override
  int get negotiatedFeatures => fakeFeatures;

  @override
  Future<void> connect() async => _open = true;

  @override
  Future<void> close() async {
    _open = false;
    // Do NOT await: a single-subscription controller with no listener never
    // completes close() (it waits to deliver "done" to a subscriber that never
    // arrives), which would hang tearDown for every test that doesn't read
    // `messages`.
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }

  @override
  void sendMessage(List<int> body) {
    sent.add(Uint8List.fromList(body));
    if (autoAck) _incoming.add(Uint8List.fromList(const [0x00]));
  }

  @override
  Stream<Uint8List> get messages => _incoming.stream;
}

/// Decode a RemoteMessage into (oneof field number, inner body).
({int field, Uint8List body}) _outer(Uint8List msg) {
  final r = ProtoReader(msg);
  final tag = r.readTag();
  return (field: tag.number, body: r.readLengthDelimited());
}

void main() {
  group('AndroidTvAdapter', () {
    late FakeAtvChannel channel;
    late AndroidTvAdapter adapter;

    setUp(() async {
      channel = FakeAtvChannel();
      adapter = AndroidTvAdapter(channel: channel);
      await adapter.connect();
    });

    tearDown(() => channel.close());

    test('capabilities: network transport, LIVE text (the hero), app launch',
        () {
      final caps = adapter.capabilities();
      expect(adapter.transport, Transport.network);
      expect(caps.textMode, TextInjectionMode.live);
      expect(caps.canType, isTrue);
      expect(caps.appLaunch, isTrue);
      expect(caps.wake, isFalse);
      expect(caps.supports(Key.ok), isTrue);
      expect(caps.supports(Key.star), isFalse); // Roku-only key
    });

    test('discovery hint is the androidtvremote2 mDNS service', () {
      expect(adapter.discoveryHints.mdnsServiceTypes,
          contains('_androidtvremote2._tcp'));
    });

    test('sendKey(ok) emits key_code=23 (DPAD_CENTER), direction SHORT=3', () {
      adapter.sendKey(Key.ok);
      final msg = _outer(channel.sent.single);
      expect(msg.field, 10); // remote_key_inject
      final inner = ProtoReader(msg.body);
      final f1 = inner.readTag();
      expect(f1.number, 1);
      expect(inner.readVarint(), 23); // KEYCODE_DPAD_CENTER
      inner.readTag();
      expect(inner.readVarint(), 3); // SHORT
    });

    test('hold maps to START_LONG then END_LONG directions', () async {
      await adapter.sendKey(Key.volumeUp, press: PressType.holdStart);
      await adapter.sendKey(Key.volumeUp, press: PressType.holdEnd);

      int directionOf(Uint8List m) {
        final inner = ProtoReader(_outer(m).body);
        inner.readTag();
        inner.readVarint(); // key_code
        inner.readTag();
        return inner.readVarint(); // direction
      }

      expect(directionOf(channel.sent[0]), 1); // START_LONG
      expect(directionOf(channel.sent[1]), 2); // END_LONG
    });

    test('unsupported key fails and emits nothing', () async {
      final res = await adapter.sendKey(Key.star);
      expect(res.ok, isFalse);
      expect(channel.sent, isEmpty);
    });

    test('text submit sends KEYCODE_ENTER (66)', () async {
      await adapter.sendText(const TextOp.submit());
      final inner = ProtoReader(_outer(channel.sent.single).body);
      inner.readTag();
      expect(inner.readVarint(), 66);
    });

    test('text insert sends an IME batch edit on field 21', () async {
      await adapter.sendText(const TextOp.insert('hi'));
      final msg = _outer(channel.sent.single);
      expect(msg.field, 21); // ime_batch_edit
      // Walk: batchEdit → edit_info(3) → text_field_status(2) → value(3)
      final batch = ProtoReader(msg.body);
      String? text;
      while (batch.hasMore) {
        final bt = batch.readTag();
        if (bt.number == 3) {
          final editInfo = ProtoReader(batch.readLengthDelimited());
          while (editInfo.hasMore) {
            final et = editInfo.readTag();
            if (et.number == 2) {
              final imeObj = ProtoReader(editInfo.readLengthDelimited());
              while (imeObj.hasMore) {
                final ot = imeObj.readTag();
                if (ot.number == 3) {
                  text = imeObj.readString();
                } else {
                  imeObj.skip(ot.wireType);
                }
              }
            } else {
              editInfo.skip(et.wireType);
            }
          }
        } else {
          batch.skip(bt.wireType);
        }
      }
      expect(text, 'hi');
    });

    test('delete from empty buffer sends KEYCODE_DEL key injects', () async {
      await adapter.sendText(const TextOp.delete(3));
      expect(channel.sent, hasLength(3));
      for (final m in channel.sent) {
        final inner = ProtoReader(_outer(m).body);
        inner.readTag();
        expect(inner.readVarint(), 67); // KEYCODE_DEL
      }
    });

    test('delete with text sends truncated IME batch edit', () async {
      await adapter.sendText(const TextOp.insert('hello'));
      channel.sent.clear();
      await adapter.sendText(const TextOp.delete(2));
      expect(channel.sent, hasLength(1));
      final outer = _outer(channel.sent.single);
      expect(outer.field, 21); // RemoteImeBatchEdit
    });

    test('launchApp sends an app-link message with the id', () async {
      await adapter
          .launchApp(const AppRef(id: 'https://youtube', name: 'YouTube'));
      final msg = _outer(channel.sent.single);
      expect(msg.field, 90);
      expect(ProtoReader(msg.body)..readTag(), isNotNull);
    });

    test('power(on) injects KEYCODE_POWER (26)', () async {
      await adapter.power(on: true);
      final inner = ProtoReader(_outer(channel.sent.single).body);
      inner.readTag();
      expect(inner.readVarint(), 26);
    });

    test('commands fail cleanly when the channel is closed', () async {
      await channel.close();
      final res = await adapter.sendKey(Key.home);
      expect(res.ok, isFalse);
      expect(res.error, contains('not connected'));
    });

    test('heartbeat true when open, false when closed', () async {
      expect(await adapter.heartbeat(), isTrue);
      await channel.close();
      expect(await adapter.heartbeat(), isFalse);
    });
  });

  group('AtvPairingSession', () {
    test('drives the handshake to paired and sends the secret', () async {
      final channel = FakeAtvChannel(autoAck: true);
      await channel.connect();
      final session = AtvPairingSession(
        channel: channel,
        clientKey: const AtvPublicKey(modulus: [1, 2, 3], exponent: [1, 0, 1]),
        serverKey: const AtvPublicKey(modulus: [9, 8, 7], exponent: [1, 0, 1]),
      );
      final hash = computePairingHash(
        clientModulus: const [1, 2, 3],
        clientExponent: const [1, 0, 1],
        serverModulus: const [9, 8, 7],
        serverExponent: const [1, 0, 1],
        nonce: const [0x5B, 0x6C],
      );
      final pin = '${hash[0].toRadixString(16).padLeft(2, '0')}5B6C';

      final result = await session.run(
        PairingContext(requestPin: () async => pin),
      );

      expect(result.isPaired, isTrue);
      expect(result.credential, 'android_tv:client-cert');
      // request, option, configuration, secret = 4 messages sent.
      expect(channel.sent, hasLength(4));
      await channel.close();
    });

    test('rejects a code with the wrong checksum before sending a secret',
        () async {
      final channel = FakeAtvChannel(autoAck: true);
      await channel.connect();
      final session = AtvPairingSession(
        channel: channel,
        clientKey: const AtvPublicKey(modulus: [1], exponent: [1]),
        serverKey: const AtvPublicKey(modulus: [2], exponent: [1]),
      );

      final hash = computePairingHash(
        clientModulus: const [1],
        clientExponent: const [1],
        serverModulus: const [2],
        serverExponent: const [1],
        nonce: const [0, 0],
      );
      final wrongChecksum = (hash[0] ^ 0xff).toRadixString(16).padLeft(2, '0');
      final result = await session.run(
        PairingContext(requestPin: () async => '${wrongChecksum}0000'),
      );

      expect(result.isPaired, isFalse);
      expect(result.error, contains('checksum'));
      expect(channel.sent, hasLength(3));
      await channel.close();
    });

    test('times out when the TV does not acknowledge pairing', () async {
      final channel = FakeAtvChannel();
      await channel.connect();
      final session = AtvPairingSession(
        channel: channel,
        clientKey: const AtvPublicKey(modulus: [1], exponent: [1]),
        serverKey: const AtvPublicKey(modulus: [2], exponent: [1]),
        ackTimeout: const Duration(milliseconds: 10),
      );

      final result = await session.run(
        PairingContext(requestPin: () async => '000000'),
      );

      expect(result.isPaired, isFalse);
      expect(result.error, contains('TimeoutException'));
      await channel.close();
    });

    test('fails cleanly without a PIN provider', () async {
      final channel = FakeAtvChannel(autoAck: true);
      await channel.connect();
      final session = AtvPairingSession(
        channel: channel,
        clientKey: const AtvPublicKey(modulus: [1], exponent: [1]),
        serverKey: const AtvPublicKey(modulus: [1], exponent: [1]),
      );
      final result = await session.run(const PairingContext());
      expect(result.status, PairingStatus.failed);
      await channel.close();
    });
  });
}
