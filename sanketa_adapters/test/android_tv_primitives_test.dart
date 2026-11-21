import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sanketa_adapters/src/android_tv/atv_framing.dart';
import 'package:sanketa_adapters/src/android_tv/atv_keymap.dart';
import 'package:sanketa_adapters/src/android_tv/atv_pairing.dart';
import 'package:sanketa_adapters/src/android_tv/der_utils.dart';
import 'package:sanketa_adapters/src/android_tv/protobuf_codec.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  group('protobuf codec — canonical wire vectors', () {
    test('varint field 1 = 150 encodes to 08 96 01', () {
      final w = ProtoWriter()..writeUint(1, 150);
      expect(w.toBytes(), [0x08, 0x96, 0x01]);
    });

    test('string field 2 = "testing" encodes to 12 07 74 65 73 74 69 6e 67',
        () {
      final w = ProtoWriter()..writeString(2, 'testing');
      expect(w.toBytes(), [0x12, 0x07, ...utf8.encode('testing')]);
    });

    test('round-trips fields through a reader', () {
      final bytes = (ProtoWriter()
            ..writeUint(1, 300)
            ..writeString(2, 'hi')
            ..writeBool(3, value: true))
          .toBytes();

      final r = ProtoReader(bytes);
      final f1 = r.readTag();
      expect([f1.number, f1.wireType], [1, WireType.varint]);
      expect(r.readVarint(), 300);

      final f2 = r.readTag();
      expect([f2.number, f2.wireType], [2, WireType.lengthDelimited]);
      expect(r.readString(), 'hi');

      final f3 = r.readTag();
      expect(f3.number, 3);
      expect(r.readVarint(), 1);
      expect(r.hasMore, isFalse);
    });

    test('nested message is length-delimited', () {
      final inner = ProtoWriter()..writeUint(1, 23);
      final outer = ProtoWriter()..writeMessage(10, inner);
      final r = ProtoReader(outer.toBytes());
      final tag = r.readTag();
      expect(tag.number, 10);
      expect(tag.wireType, WireType.lengthDelimited);
      final body = r.readLengthDelimited();
      expect(body, inner.toBytes());
    });

    test('skip advances past unwanted fields', () {
      final bytes = (ProtoWriter()
            ..writeString(1, 'skip me')
            ..writeUint(2, 7))
          .toBytes();
      final r = ProtoReader(bytes);
      final f1 = r.readTag();
      r.skip(f1.wireType);
      final f2 = r.readTag();
      expect(f2.number, 2);
      expect(r.readVarint(), 7);
    });

    test('rejects invalid writes and truncated skipped fields', () {
      expect(() => ProtoWriter().writeUint(1, -1), throwsArgumentError);
      expect(() => ProtoWriter().writeUint(0, 1), throwsArgumentError);
      expect(() => ProtoReader([0]).readTag(), throwsFormatException);
      expect(
        () => ProtoReader([5, 1, 2]).skip(WireType.lengthDelimited),
        throwsFormatException,
      );
      expect(
        () => ProtoReader([1, 2, 3]).skip(WireType.fixed32),
        throwsFormatException,
      );
    });
  });

  group('message framing', () {
    test('frames a body with its varint length prefix', () {
      expect(frameMessage([0xAA, 0xBB]), [0x02, 0xAA, 0xBB]);
    });

    test('deframes messages split across arbitrary chunk boundaries', () {
      final wire = <int>[
        ...frameMessage([1, 2, 3]),
        ...frameMessage([4, 5]),
      ];
      final deframer = MessageDeframer();
      // Feed byte-by-byte to stress partial-length and partial-body handling.
      var all = <List<int>>[];
      for (final b in wire) {
        deframer.addChunk([b]);
        all = [...all, ...deframer.drain()];
      }
      expect(all, [
        [1, 2, 3],
        [4, 5],
      ]);
    });

    test('a long message (length > 127) uses a multi-byte prefix', () {
      final body = List<int>.filled(200, 0x42);
      final framed = frameMessage(body);
      expect(framed[0], 0xC8); // 200 = 0xC8 0x01 as a varint
      expect(framed[1], 0x01);
      final deframer = MessageDeframer()..addChunk(framed);
      expect(deframer.drain().single, body);
    });

    test('rejects a frame larger than the configured safety limit', () {
      final deframer = MessageDeframer(maxFrameSize: 4)..addChunk([5]);
      expect(deframer.drain, throwsFormatException);
    });
  });

  group('DER parsing', () {
    test('malformed certificates fail with FormatException', () {
      expect(
        () => rsaPublicKeyFromDer(Uint8List.fromList(const [])),
        throwsFormatException,
      );
      expect(
        () => rsaPublicKeyFromDer(Uint8List.fromList(const [0x30, 0x05, 0x30])),
        throwsFormatException,
      );
    });
  });

  group('android keycodes', () {
    test('core navigation and volume map to documented KEYCODE_* values', () {
      expect(androidKeyCodes[Key.up], 19);
      expect(androidKeyCodes[Key.down], 20);
      expect(androidKeyCodes[Key.left], 21);
      expect(androidKeyCodes[Key.right], 22);
      expect(androidKeyCodes[Key.ok], 23);
      expect(androidKeyCodes[Key.home], 3);
      expect(androidKeyCodes[Key.back], 4);
      expect(androidKeyCodes[Key.volumeUp], 24);
      expect(androidKeyCodes[Key.digit0], 7);
      expect(androidKeyCodes[Key.digit9], 16);
    });

    test('press types map to protocol directions', () {
      expect(atvDirectionFor(PressType.tap), AtvDirection.short);
      expect(atvDirectionFor(PressType.holdStart), AtvDirection.startLong);
      expect(atvDirectionFor(PressType.holdEnd), AtvDirection.endLong);
    });
  });

  group('pairing secret', () {
    test('decodes a hex code to bytes', () {
      expect(decodeHexCode('4A5B6C'), [0x4A, 0x5B, 0x6C]);
    });

    test('rejects malformed or incorrectly sized pairing codes', () {
      expect(() => decodeHexCode(''), throwsFormatException);
      expect(() => decodeHexCode('1234'), throwsFormatException);
      expect(() => decodeHexCode('ZZZZZZ'), throwsFormatException);
    });

    test('nonce drops the leading checksum byte', () {
      expect(nonceFromCode([0x4A, 0x5B, 0x6C]), [0x5B, 0x6C]);
    });

    test('hash equals an independent SHA-256 over the concatenation', () {
      final clientMod = [1, 2, 3];
      final clientExp = [1, 0, 1];
      final serverMod = [9, 8, 7];
      final serverExp = [1, 0, 1];
      final nonce = [0x5B, 0x6C];

      final got = computePairingHash(
        clientModulus: clientMod,
        clientExponent: clientExp,
        serverModulus: serverMod,
        serverExponent: serverExp,
        nonce: nonce,
      );
      final expected = sha256.convert([
        ...clientMod,
        ...clientExp,
        ...serverMod,
        ...serverExp,
        ...nonce
      ]).bytes;
      expect(got, expected);
    });

    test('checksum match compares the code head to hash[0]', () {
      final hash = computePairingHash(
        clientModulus: const [1],
        clientExponent: const [1],
        serverModulus: const [1],
        serverExponent: const [1],
        nonce: const [0],
      );
      expect(
        pairingChecksumMatches(codeBytes: [hash[0], 0x00], hash: hash),
        isTrue,
      );
      expect(
        pairingChecksumMatches(codeBytes: [hash[0] ^ 0xFF, 0x00], hash: hash),
        isFalse,
      );
    });
  });
}
