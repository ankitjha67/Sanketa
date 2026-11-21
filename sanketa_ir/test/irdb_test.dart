import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';
import 'package:test/test.dart';

void main() {
  group('FlipperIrParser', () {
    test('parses parsed-type SIRC entries', () {
      const content = '''
Filetype: IR signals file
Version: 1
#
# Sony RM-YD028 television remote
#
name: Power
type: parsed
protocol: SIRC
address: 01 00 00 00
command: 15 00 00 00
#
name: Vol_up
type: parsed
protocol: SIRC
address: 01 00 00 00
command: 12 00 00 00
#
name: Ch_next
type: parsed
protocol: SIRC15
address: A4 00 00 00
command: 10 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(3));

      expect(signals[0].name, 'Power');
      expect(signals[0].protocol, IrProtocol.sonySirc12);
      expect(signals[0].address, 1);
      expect(signals[0].command, 0x15);
      expect(signals[0].isParsed, isTrue);

      expect(signals[1].name, 'Vol_up');
      expect(signals[1].address, 1);
      expect(signals[1].command, 0x12);

      expect(signals[2].name, 'Ch_next');
      expect(signals[2].protocol, IrProtocol.sonySirc15);
      expect(signals[2].address, 0xA4);
      expect(signals[2].command, 0x10);
    });

    test('parses NEC entries', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: NEC
address: 04 00 00 00
command: 08 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(1));
      expect(signals[0].protocol, IrProtocol.nec);
      expect(signals[0].address, 4);
      expect(signals[0].command, 8);
    });

    test('parses Samsung32 entries', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: Samsung32
address: 07 00 00 00
command: 02 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(1));
      expect(signals[0].protocol, IrProtocol.samsung);
      expect(signals[0].address, 7);
      expect(signals[0].command, 2);
    });

    test('parses raw entries', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: raw
frequency: 38000
duty_cycle: 0.330000
data: 9024 4512 564 1692 564 564 564 564
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(1));
      expect(signals[0].name, 'Power');
      expect(signals[0].protocol, IrProtocol.raw);
      expect(signals[0].frequency, 38000);
      expect(signals[0].rawData, [9024, 4512, 564, 1692, 564, 564, 564, 564]);
      expect(signals[0].isRaw, isTrue);
    });

    test('skips unsupported protocols', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: KASEIKYO
address: 00 20 00 00
command: 3D 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, isEmpty);
    });

    test('handles multi-byte little-endian addresses', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: NECext
address: 86 85 00 00
command: 0A 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(1));
      expect(signals[0].protocol, IrProtocol.necExtended);
      expect(signals[0].address, 0x8586);
      expect(signals[0].command, 0x0A);
    });

    test('skips malformed hex and raw timing entries without throwing', () {
      const content = '''
name: Bad_hex
type: parsed
protocol: NEC
address: GG 00 00 00
command: 08 00 00 00
name: Bad_raw
type: raw
frequency: 38000
data: 9000 nope 560
name: Good
type: parsed
protocol: NEC
address: 04 00 00 00
command: 08 00 00 00
''';
      final signals = parseFlipperIr(content);
      expect(signals, hasLength(1));
      expect(signals.single.name, 'Good');
    });
  });

  group('KeyNameMap', () {
    test('resolves standard Flipper button names', () {
      expect(resolveKeyName('Power'), Key.power);
      expect(resolveKeyName('Vol_up'), Key.volumeUp);
      expect(resolveKeyName('Vol_dn'), Key.volumeDown);
      expect(resolveKeyName('Mute'), Key.mute);
      expect(resolveKeyName('Ch_next'), Key.channelUp);
      expect(resolveKeyName('Ch_prev'), Key.channelDown);
      expect(resolveKeyName('Up'), Key.up);
      expect(resolveKeyName('Down'), Key.down);
      expect(resolveKeyName('Left'), Key.left);
      expect(resolveKeyName('Right'), Key.right);
      expect(resolveKeyName('Ok'), Key.ok);
      expect(resolveKeyName('Select'), Key.ok);
      expect(resolveKeyName('Back'), Key.back);
      expect(resolveKeyName('Return'), Key.back);
      expect(resolveKeyName('Home'), Key.home);
      expect(resolveKeyName('Menu'), Key.menu);
      expect(resolveKeyName('Play'), Key.play);
      expect(resolveKeyName('Pause'), Key.pause);
      expect(resolveKeyName('Stop'), Key.stop);
    });

    test('resolves LIRC-style KEY_ names', () {
      expect(resolveKeyName('KEY_POWER'), Key.power);
      expect(resolveKeyName('KEY_VOLUMEUP'), Key.volumeUp);
      expect(resolveKeyName('KEY_VOLUMEDOWN'), Key.volumeDown);
      expect(resolveKeyName('KEY_MUTE'), Key.mute);
      expect(resolveKeyName('KEY_OK'), Key.ok);
    });

    test('is case-insensitive', () {
      expect(resolveKeyName('power'), Key.power);
      expect(resolveKeyName('POWER'), Key.power);
      expect(resolveKeyName('Power'), Key.power);
    });

    test('returns null for unknown names', () {
      expect(resolveKeyName('Theater'), isNull);
      expect(resolveKeyName('Wide'), isNull);
      expect(resolveKeyName('Sync_menu'), isNull);
    });

    test('resolves digit names', () {
      for (var i = 0; i <= 9; i++) {
        expect(resolveKeyName('$i'), isNotNull);
      }
    });
  });

  group('BrandMap', () {
    test('resolves known brands', () {
      expect(resolveBrand('Sony'), BrandFamily.bravia);
      expect(resolveBrand('Samsung'), BrandFamily.tizen);
      expect(resolveBrand('LG'), BrandFamily.webOs);
      expect(resolveBrand('Roku'), BrandFamily.roku);
      expect(resolveBrand('Vizio'), BrandFamily.vizio);
      expect(resolveBrand('Panasonic'), BrandFamily.panasonic);
      expect(resolveBrand('Philips'), BrandFamily.philips);
    });

    test('is case-insensitive', () {
      expect(resolveBrand('SONY'), BrandFamily.bravia);
      expect(resolveBrand('sony'), BrandFamily.bravia);
    });

    test('returns genericIr for unknown brands', () {
      expect(resolveBrand('Dynex'), BrandFamily.genericIr);
      expect(resolveBrand('Sceptre'), BrandFamily.genericIr);
    });

    test('resolves device types from Flipper categories', () {
      expect(resolveDeviceType('TVs'), DeviceType.tv);
      expect(resolveDeviceType('ACs'), DeviceType.airConditioner);
      expect(resolveDeviceType('Projectors'), DeviceType.projector);
      expect(resolveDeviceType('SoundBars'), DeviceType.soundbar);
      expect(resolveDeviceType('Streaming_Devices'), DeviceType.streamingStick);
      expect(resolveDeviceType('Cable_Boxes'), DeviceType.setTopBox);
      expect(resolveDeviceType('DVD_Players'), DeviceType.mediaRenderer);
      expect(tryResolveDeviceType('Fans'), isNull);
    });
  });

  group('CodesetBuilder', () {
    test('builds codeset from Flipper file path', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: NEC
address: 04 00 00 00
command: 08 00 00 00
#
name: Vol_up
type: parsed
protocol: NEC
address: 04 00 00 00
command: 02 00 00 00
#
name: Vol_dn
type: parsed
protocol: NEC
address: 04 00 00 00
command: 03 00 00 00
#
name: Mute
type: parsed
protocol: NEC
address: 04 00 00 00
command: 09 00 00 00
''';
      final codeset = CodesetBuilder.fromFlipperFile(
        relativePath: 'TVs/Samsung/Samsung_BN59-01175N.ir',
        content: content,
      );

      expect(codeset, isNotNull);
      expect(codeset!.brand, BrandFamily.tizen);
      expect(codeset.brandName, 'Samsung');
      expect(codeset.deviceType, DeviceType.tv);
      expect(codeset.supports(Key.power), isTrue);
      expect(codeset.supports(Key.volumeUp), isTrue);
      expect(codeset.supports(Key.volumeDown), isTrue);
      expect(codeset.supports(Key.mute), isTrue);
      expect(codeset.keys[Key.power]!.protocol, IrProtocol.nec);
      expect(codeset.keys[Key.power]!.address, 4);
      expect(codeset.keys[Key.power]!.command, 8);
    });

    test('uses top-level category and brand when a series folder is present',
        () {
      const content = '''
name: Power
type: parsed
protocol: NEC
address: 07 00 00 00
command: 02 00 00 00
''';
      final codeset = CodesetBuilder.fromFlipperFile(
        relativePath: 'TVs/Samsung/Q-Series/Samsung_QN85.ir',
        content: content,
      );
      expect(codeset, isNotNull);
      expect(codeset!.brand, BrandFamily.tizen);
      expect(codeset.deviceType, DeviceType.tv);
      expect(codeset.id.length, lessThan(120));
    });

    test('skips entries with unmapped button names', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: parsed
protocol: NEC
address: 04 00 00 00
command: 08 00 00 00
#
name: Theater_Mode_XYZ
type: parsed
protocol: NEC
address: 04 00 00 00
command: FF 00 00 00
''';
      final codeset = CodesetBuilder.fromFlipperFile(
        relativePath: 'TVs/LG/LG_Test.ir',
        content: content,
      );
      expect(codeset, isNotNull);
      expect(codeset!.keys.length, 1);
      expect(codeset.supports(Key.power), isTrue);
    });

    test('handles raw entries in codesets', () {
      const content = '''
Filetype: IR signals file
Version: 1
name: Power
type: raw
frequency: 38000
duty_cycle: 0.330000
data: 9024 4512 564 1692 564 564
''';
      final codeset = CodesetBuilder.fromFlipperFile(
        relativePath: 'TVs/Unknown/Test_Remote.ir',
        content: content,
      );
      expect(codeset, isNotNull);
      expect(codeset!.supports(Key.power), isTrue);
      expect(codeset.keys[Key.power]!.protocol, IrProtocol.raw);
      expect(codeset.keys[Key.power]!.raw, isNotNull);
      expect(codeset.keys[Key.power]!.carrierHzOverride, 38000);
    });

    test('returns null for path with fewer than 3 segments', () {
      expect(
        CodesetBuilder.fromFlipperFile(
            relativePath: 'test.ir',
            content: 'name: Power\ntype: raw\nfrequency: 38000\ndata: 100 200'),
        isNull,
      );
    });
  });

  group('IrdbCatalog', () {
    test('serializes and deserializes catalog', () {
      const codeset = IrCodeset(
        id: 'test_nec_1',
        brand: BrandFamily.tizen,
        deviceType: DeviceType.tv,
        name: 'Samsung Test',
        keys: {
          Key.power:
              IrCommand(protocol: IrProtocol.nec, address: 4, command: 8),
          Key.volumeUp:
              IrCommand(protocol: IrProtocol.nec, address: 4, command: 2),
        },
      );

      final serialized =
          IrdbCatalog.serializeCodeset(codeset, IrdbSource.flipperIrdb);
      final json = serialized.toJson();
      final restored = SerializedCodeset.fromJson(json);
      final restoredCodeset = restored.toCodeset();

      expect(restoredCodeset.id, 'test_nec_1');
      expect(restoredCodeset.brand, BrandFamily.tizen);
      expect(restoredCodeset.deviceType, DeviceType.tv);
      expect(restoredCodeset.supports(Key.power), isTrue);
      expect(restoredCodeset.keys[Key.power]!.protocol, IrProtocol.nec);
      expect(restoredCodeset.keys[Key.power]!.address, 4);
      expect(restoredCodeset.keys[Key.power]!.command, 8);
    });

    test('catalog search works', () {
      final catalog = IrdbCatalog([
        const CatalogEntry(
            id: 'sony_1',
            brand: BrandFamily.bravia,
            deviceType: DeviceType.tv,
            name: 'Sony KD-55',
            source: IrdbSource.flipperIrdb,
            keyCount: 20),
        const CatalogEntry(
            id: 'samsung_1',
            brand: BrandFamily.tizen,
            deviceType: DeviceType.tv,
            name: 'Samsung QN85',
            source: IrdbSource.flipperIrdb,
            keyCount: 18),
        const CatalogEntry(
            id: 'lg_ac',
            brand: BrandFamily.webOs,
            deviceType: DeviceType.airConditioner,
            name: 'LG AC',
            source: IrdbSource.lirc,
            keyCount: 5),
      ]);

      expect(catalog.byDeviceType(DeviceType.tv), hasLength(2));
      expect(catalog.byBrand(BrandFamily.bravia), hasLength(1));
      expect(catalog.byBrandAndType(BrandFamily.tizen, DeviceType.tv),
          hasLength(1));
      expect(catalog.search('sony'), hasLength(1));
      expect(catalog.search('ac'), hasLength(1));
    });

    test('catalog round-trips through JSON', () {
      final catalog = IrdbCatalog([
        const CatalogEntry(
            id: 'test_1',
            brand: BrandFamily.bravia,
            deviceType: DeviceType.tv,
            name: 'Test Remote',
            source: IrdbSource.flipperIrdb,
            keyCount: 10),
      ]);
      final json = catalog.toJson();
      final restored = IrdbCatalog.fromJson(json);
      expect(restored.length, 1);
      expect(restored.entries.first.id, 'test_1');
      expect(restored.entries.first.brand, BrandFamily.bravia);
    });
  });

  group('Kookong compact format', () {
    test('kk protocol expands to raw timing', () {
      final json = <String, dynamic>{
        'p': 'kk',
        'f': 38000,
        't': [9000, 4500, 560, 560, 1690, 560],
        'd': 'FF',
      };
      final cmd = SerializedCommand.fromJson(json);
      expect(cmd.protocol, 'raw');
      expect(cmd.frequency, 38000);
      // FF = 11111111: header + 8*(mark+bit1) + trail = 2 + 16 + 1 = 19
      expect(cmd.raw, isNotNull);
      expect(cmd.raw!.length, 19);
      expect(cmd.raw![0], 9000); // header mark
      expect(cmd.raw![1], 4500); // header space
      expect(cmd.raw![2], 560);  // bit mark
      expect(cmd.raw![3], 1690); // bit1 space (bit 7 = 1)
      expect(cmd.raw![18], 560); // trail mark
    });

    test('kk protocol bit0 uses bit0 space', () {
      final json = <String, dynamic>{
        'p': 'kk',
        'f': 38000,
        't': [9000, 4500, 560, 560, 1690, 560],
        'd': '00',
      };
      final cmd = SerializedCommand.fromJson(json);
      // 00 = 00000000: all bit0 spaces
      expect(cmd.raw![3], 560); // bit0 space
    });

    test('kk protocol codeset round-trips through toCodeset', () {
      final json = <String, dynamic>{
        'id': 'kookong_test',
        'brand': 'genericIr',
        'deviceType': 'tv',
        'name': 'Test KK',
        'source': 'kookong',
        'keyCount': 1,
        'brandName': 'KK-test',
        'keys': {
          'power': {
            'p': 'kk',
            'f': 38000,
            't': [9000, 4500, 560, 560, 1690, 560],
            'd': 'A1B2',
          },
        },
      };
      final codeset = SerializedCodeset.fromJson(json).toCodeset();
      expect(codeset.keys, contains(Key.power));
      final signal = const IrCodec().encode(codeset.keys[Key.power]!);
      expect(signal.carrierHz, 38000);
      // A1B2 = 10100001 10110010 → 16 bits → 2+32+1 = 35 values
      expect(signal.pattern.length, 35);
    });
  });

  group('LircParser', () {
    test('parses basic LIRC config', () {
      const content = '''
begin remote
  name  Test_TV
  bits  32
  flags SPACE_ENC|CONST_LENGTH
  header 9000 4500
  one   560  1690
  zero  560  560

  begin codes
    KEY_POWER    0x04080000
    KEY_VOLUMEUP 0x04020000
  end codes
end remote
''';
      final remotes = parseLircConf(content);
      expect(remotes, hasLength(1));
      expect(remotes[0].name, 'Test_TV');
      expect(remotes[0].signals, hasLength(2));
    });

    test('handles multiple remotes in one file', () {
      const content = '''
begin remote
  name  Remote_1
  bits  12
  flags SPACE_ENC
  header 2400 600
  one   1200 600
  zero  600  600
  frequency 40000

  begin codes
    KEY_POWER 0x095
  end codes
end remote

begin remote
  name  Remote_2
  bits  32
  flags SPACE_ENC
  header 9000 4500
  one   560  1690
  zero  560  560

  begin codes
    KEY_POWER 0x04080000
  end codes
end remote
''';
      final remotes = parseLircConf(content);
      expect(remotes, hasLength(2));
    });

    test('skips malformed timings instead of aborting the file', () {
      const content = '''
begin remote
  name Bad
  bits 32
  flags UNKNOWN
  header nope 4500
  one 560 1690
  zero 560 560
  begin codes
    KEY_POWER 0x01
  end codes
end remote
''';
      expect(parseLircConf(content), isEmpty);
    });
  });

  group('ProtocolDecoder', () {
    test('decodes NEC pattern', () {
      final pattern = <int>[9000, 4500];
      // Encode address=4 (0b00000100), ~address=0xFB, command=8 (0b00001000), ~command=0xF7
      void addByte(int b) {
        for (var i = 0; i < 8; i++) {
          pattern.add(560);
          pattern.add((b >> i) & 1 == 1 ? 1690 : 560);
        }
      }

      addByte(4); // address
      addByte(~4 & 0xFF); // ~address
      addByte(8); // command
      addByte(~8 & 0xFF); // ~command
      pattern.add(560); // stop bit

      final signal =
          decodeRawPattern(name: 'test', carrierHz: 38000, pattern: pattern);
      expect(signal.protocol, IrProtocol.nec);
      expect(signal.address, 4);
      expect(signal.command, 8);
    });

    test('falls back to raw for unrecognized patterns', () {
      final signal = decodeRawPattern(
          name: 'test', carrierHz: 38000, pattern: [100, 200, 300]);
      expect(signal.protocol, IrProtocol.raw);
      expect(signal.rawData, [100, 200, 300]);
    });

    test('does not mislabel an unsupported SIRC bit length', () {
      final pattern = <int>[2400, 600];
      for (var i = 0; i < 13; i++) {
        pattern.addAll(const [600, 600]);
      }
      final signal =
          decodeRawPattern(name: 'test', carrierHz: 40000, pattern: pattern);
      expect(signal.protocol, IrProtocol.raw);
    });
  });

  group('CaptureSession', () {
    test('tracks capture progress', () {
      final session = CaptureSession(
        deviceName: 'Test TV',
        brandName: 'Sony',
        deviceType: DeviceType.tv,
      );

      expect(session.isComplete, isFalse);
      expect(session.progress, 0.0);
      expect(session.nextKey, isNotNull);

      final keys = session.remaining.toList();
      for (final key in keys) {
        session.recordCapture(key,
            carrierHz: 38000, pattern: [9000, 4500, 560, 560, 560]);
      }

      expect(session.isComplete, isTrue);
      expect(session.progress, 1.0);
    });

    test('skip removes key from remaining', () {
      final session = CaptureSession(
        deviceName: 'Test SB',
        brandName: 'Sony',
        deviceType: DeviceType.soundbar,
      );

      final initial = session.remaining.length;
      session.skip(session.remaining.first);
      expect(session.remaining.length, initial - 1);
    });

    test('builds codeset from captured signals', () {
      final session = CaptureSession(
        deviceName: 'Test TV',
        brandName: 'Sony',
        deviceType: DeviceType.tv,
        keysToCapture: [Key.power, Key.volumeUp],
      );

      session.recordSignal(
          Key.power,
          const ParsedSignal(
            name: 'power',
            protocol: IrProtocol.sonySirc12,
            address: 1,
            command: 21,
          ));
      session.recordSignal(
          Key.volumeUp,
          const ParsedSignal(
            name: 'volumeUp',
            protocol: IrProtocol.sonySirc12,
            address: 1,
            command: 18,
          ));

      final codeset = session.buildCodeset();
      expect(codeset.brand, BrandFamily.bravia);
      expect(codeset.deviceType, DeviceType.tv);
      expect(codeset.supports(Key.power), isTrue);
      expect(codeset.supports(Key.volumeUp), isTrue);
      expect(codeset.keys[Key.power]!.command, 21);
    });
  });

  group('KookongKeyMap', () {
    test('resolves common IDs', () {
      expect(kookongIdToKey(1), Key.power);
      expect(kookongIdToKey(12), Key.mute);
      expect(kookongIdToKey(14), Key.volumeUp);
      expect(kookongIdToKey(15), Key.volumeDown);
      expect(kookongIdToKey(44), Key.ok);
    });

    test('resolves common names', () {
      expect(kookongNameToKey('POWER'), Key.power);
      expect(kookongNameToKey('MUTE'), Key.mute);
      expect(kookongNameToKey('OK'), Key.ok);
      expect(kookongNameToKey('GUIDE'), Key.guide);
    });

    test('returns null for unknown IDs', () {
      expect(kookongIdToKey(9999), isNull);
    });
  });
}
