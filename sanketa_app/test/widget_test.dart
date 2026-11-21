import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanketa_app/control/ir_device_service.dart';
import 'package:sanketa_app/control/remote_controller.dart';
import 'package:sanketa_app/native/platform_bridge.dart';
import 'package:sanketa_app/screens/app_shell.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

class FakeIrBridge implements IrBridge {
  FakeIrBridge({this.available = true});

  final bool available;
  final List<({int frequencyHz, List<int> pattern})> transmissions = [];

  @override
  Future<bool> get hasIrEmitter async => available;

  @override
  Future<List<int>> get carrierFrequencies async => const [38000, 40000];

  @override
  Future<void> transmit(int frequencyHz, List<int> pattern) async {
    transmissions.add((frequencyHz: frequencyHz, pattern: pattern));
  }
}

class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Missing fake asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false; // no network in tests
  });

  Widget shell({RemoteController? controller}) {
    final c = controller ?? RemoteController(backends: []);
    return RemoteScope(
      controller: c,
      child: const MaterialApp(
        home: AppShell(),
      ),
    );
  }

  testWidgets(
    'AppShell renders the remote screen with hero keyboard, D-pad, apps, and nav',
    (t) async {
      await t.pumpWidget(shell());
      // Hero keyboard-sync card
      expect(find.text('TV Search & Text Sync'), findsOneWidget);
      expect(find.text('q'), findsOneWidget);
      // D-pad + app shortcuts (built eagerly via SingleChildScrollView)
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('NETFLIX'), findsOneWidget);
      expect(find.text('Disney+'), findsOneWidget);
      // Bottom nav (now in AppShell)
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Search'), findsWidgets);
    },
  );

  testWidgets('bottom nav switches between screens', (t) async {
    final c = RemoteController(backends: []);
    await t.pumpWidget(shell(controller: c));

    // Initially on Remote (index 0)
    expect(find.text('TV Search & Text Sync'), findsOneWidget);

    // Tap Search in bottom nav (last match — keyboard also has a Search button)
    await t.tap(find.text('Search').last);
    await t.pump();
    expect(find.text('QUICK LAUNCH'), findsOneWidget);

    // Tap Cast in bottom nav (last match — screens may duplicate labels)
    await t.tap(find.text('Cast').last);
    await t.pump();
    expect(find.text('CAST DEVICES'), findsOneWidget);

    // Tap Devices in bottom nav
    await t.tap(find.text('Devices').last);
    await t.pump();
    expect(find.text('No device connected'), findsOneWidget);
    expect(find.text('NEARBY DEVICES'), findsOneWidget);

    // Tap Remote to go back
    await t.tap(find.text('Remote').last);
    await t.pump();
    expect(find.text('TV Search & Text Sync'), findsOneWidget);
  });

  group('RemoteController wiring', () {
    test('IRDB catalog loads metadata first and codesets lazily', () async {
      const id = 'flipper_tvs_sony_test_12345678';
      final bundle = FakeAssetBundle({
        'assets/irdb/catalog.json': jsonEncode([
          {
            'id': id,
            'brand': 'bravia',
            'brandName': 'Sony',
            'deviceType': 'tv',
            'name': 'Sony Test Model',
            'source': 'flipperIrdb',
            'keyCount': 1,
          },
        ]),
        'assets/irdb/codesets/$id.json': jsonEncode({
          'id': id,
          'brand': 'bravia',
          'brandName': 'Sony',
          'deviceType': 'tv',
          'name': 'Sony Test Model',
          'source': 'flipperIrdb',
          'keyCount': 1,
          'keys': {
            'power': {'p': 'sonySirc12', 'a': 1, 'c': 21},
          },
        }),
      });
      final service = IrDeviceService(bundle: bundle);

      await service.initialize();
      final matches = service.byBrand(
        core.BrandFamily.bravia,
        deviceType: core.DeviceType.tv,
      );
      final generated = matches.firstWhere((entry) => entry.id == id);

      expect(service.catalogLoaded, isTrue);
      expect(service.allEntries, hasLength(5));
      expect(
        service.availableBrandNames(deviceType: core.DeviceType.tv),
        contains('Sony'),
      );
      expect(generated.codeset, isNull);
      final codeset = await service.loadCodeset(generated);
      expect(codeset.supports(core.Key.power), isTrue);
      expect(generated.codeset, same(codeset));
    });

    test('type() appends to the TV buffer and logs a sendText', () {
      final c = RemoteController(backends: [])..tvText = '';
      c.type('l');
      c.type('o');
      expect(c.tvText, 'lo');
      expect(c.actionLog.where((a) => a.contains('text')).length, 2);
    });

    test('backspace() and clearText() edit the buffer', () {
      final c = RemoteController(backends: [])..tvText = 'abc';
      c.backspace();
      expect(c.tvText, 'ab');
      c.clearText();
      expect(c.tvText, '');
    });

    test('key() logs a key command', () {
      final c = RemoteController(backends: []);
      c.key(core.Key.ok);
      expect(c.actionLog.first, contains('ok'));
    });

    test('launch() logs launchApp with the app name', () {
      final c = RemoteController(backends: []);
      c.launch('NETFLIX');
      expect(c.actionLog.first, contains('NETFLIX'));
    });

    test('setSource() updates the source and logs setInput', () {
      final c = RemoteController(backends: []);
      c.setSource('HDMI 2');
      expect(c.currentSource, 'HDMI 2');
      expect(c.actionLog.first, contains('HDMI 2'));
    });

    test('toggleCaps flips capsLock; toggleNumbers resets capsLock', () {
      final c = RemoteController(backends: []);
      expect(c.capsLock, false);
      expect(c.numberMode, false);
      c.toggleCaps();
      expect(c.capsLock, true);
      c.toggleNumbers();
      expect(c.numberMode, true);
      expect(c.capsLock, false);
      c.toggleNumbers();
      expect(c.numberMode, false);
    });

    test('transportLabel and transportBadge reflect adapter transport', () {
      final c = RemoteController(backends: []);
      expect(c.transportLabel, 'Network');
      expect(c.transportBadge, 'IP Link');
    });

    test('IR Power test emits without activating the candidate', () async {
      final bridge = FakeIrBridge();
      final c = RemoteController(backends: [], irBridge: bridge);
      await c.refreshIrHardware();
      final entry = c.irService.allEntries.first;

      final result = await c.testIrDevice(entry);

      expect(result.ok, true);
      expect(bridge.transmissions, hasLength(1));
      expect(c.activeIrEntry, isNull);
      expect(c.isIrDevice, false);
    });

    test('tvText starts empty, not with placeholder content', () {
      final c = RemoteController(backends: []);
      expect(c.tvText, '');
    });

    test('starts disconnected with no device name', () {
      final c = RemoteController(backends: []);
      expect(c.isConnected, false);
      expect(c.deviceName, '');
    });

    test('setNavIndex updates navIndex', () {
      final c = RemoteController(backends: []);
      expect(c.navIndex, 0);
      c.setNavIndex(2);
      expect(c.navIndex, 2);
    });
  });

  testWidgets('layout geometry: header top, keyboard sized, nav at bottom', (
    t,
  ) async {
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(shell());

    final header = t.getRect(find.text('Sanketa'));
    final q = t.getRect(find.text('q'));
    final ok = t.getRect(find.text('OK'));
    final nav = t.getRect(find.text('Remote'));

    // Header sits near the top.
    expect(header.top, lessThan(80));
    // The keyboard 'Q' key is laid out with real size.
    expect(q.width, greaterThan(8));
    expect(q.height, greaterThan(8));
    // The D-pad OK is below the header and roughly horizontally centred.
    expect(ok.top, greaterThan(header.bottom));
    expect(ok.center.dx, closeTo(200, 130));
    // The nav sits at the bottom of the 900-tall view.
    expect(nav.top, greaterThan(760));
  });

  testWidgets('Search screen shows search bar and quick launch', (t) async {
    final c = RemoteController(backends: [])..setNavIndex(1);
    await t.pumpWidget(shell(controller: c));
    expect(find.text('Search'), findsWidgets);
    expect(find.text('QUICK LAUNCH'), findsOneWidget);
  });

  testWidgets('Cast screen shows ready state and media sources', (t) async {
    final c = RemoteController(backends: [])..setNavIndex(2);
    await t.pumpWidget(shell(controller: c));
    expect(find.text('CAST DEVICES'), findsOneWidget);
    expect(find.text('MEDIA SOURCES'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
  });

  testWidgets('Devices screen shows not-connected state and discovery', (
    t,
  ) async {
    final c = RemoteController(backends: [])..setNavIndex(4);
    await t.pumpWidget(shell(controller: c));
    expect(find.text('No device connected'), findsOneWidget);
    expect(find.text('NEARBY DEVICES'), findsOneWidget);
    expect(find.text('Add Device Manually'), findsOneWidget);
  });

  testWidgets('IR setup requires a successful Power confirmation', (t) async {
    final bridge = FakeIrBridge();
    final c = RemoteController(backends: [], irBridge: bridge)..setNavIndex(4);
    await c.refreshIrHardware();
    await t.pumpWidget(shell(controller: c));
    await t.pump();

    await t.tap(find.text('Add IR Remote'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(
      find.text(
        'Choose your TV brand. We’ll test a Power command before saving the remote.',
      ),
      findsOneWidget,
    );

    await t.tap(find.text('Sony'));
    await t.pump();
    expect(
      find.text('Point the top of your phone at the TV, then tap Test Power.'),
      findsOneWidget,
    );
    expect(c.activeIrEntry, isNull);

    await t.tap(find.byKey(const ValueKey('test-ir-power')));
    await t.pump();
    expect(find.text('Did the TV turn on or off?'), findsOneWidget);
    expect(bridge.transmissions, hasLength(1));
    expect(c.activeIrEntry, isNull);

    await t.tap(find.byKey(const ValueKey('confirm-ir-code')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(c.activeIrEntry?.displayName, 'Sony TV (SIRC)');
    expect(c.isIrDevice, true);
  });
}
