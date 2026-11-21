import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('WolPacket', () {
    test('builds a 102-byte magic packet', () {
      final wol = WolPacket('AA:BB:CC:DD:EE:FF');
      expect(wol.bytes.length, 102);
    });

    test('first 6 bytes are 0xFF', () {
      final wol = WolPacket('00:11:22:33:44:55');
      for (var i = 0; i < 6; i++) {
        expect(wol.bytes[i], 0xFF);
      }
    });

    test('MAC is repeated 16 times after the header', () {
      final wol = WolPacket('AA:BB:CC:DD:EE:FF');
      final mac = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF];
      for (var rep = 0; rep < 16; rep++) {
        final offset = 6 + rep * 6;
        for (var b = 0; b < 6; b++) {
          expect(wol.bytes[offset + b], mac[b], reason: 'rep=$rep byte=$b');
        }
      }
    });

    test('accepts hyphen-separated MAC', () {
      final wol = WolPacket('11-22-33-44-55-66');
      expect(wol.bytes[6], 0x11);
      expect(wol.bytes[11], 0x66);
    });

    test('rejects invalid MAC format', () {
      expect(() => WolPacket('AA:BB:CC'), throwsA(isA<FormatException>()));
      expect(() => WolPacket('not-a-mac'), throwsA(isA<FormatException>()));
    });

    test('parseMac returns 6 bytes', () {
      final mac = WolPacket.parseMac('DE:AD:BE:EF:CA:FE');
      expect(mac.length, 6);
      expect(mac[0], 0xDE);
      expect(mac[3], 0xEF);
      expect(mac[5], 0xFE);
    });
  });
}
