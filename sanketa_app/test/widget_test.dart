import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanketa_app/control/remote_controller.dart';
import 'package:sanketa_app/screens/remote_screen.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false; // no network in tests
  });

  testWidgets('RemoteScreen renders the hero keyboard, D-pad OK, apps, and nav',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: RemoteScope(controller: RemoteController(), child: const RemoteScreen()),
    ));
    // Hero keyboard-sync card
    expect(find.text('TV Search & Text Sync'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    // D-pad + app shortcuts (built eagerly via SingleChildScrollView)
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('NETFLIX'), findsOneWidget);
    expect(find.text('Disney+'), findsOneWidget);
    // Bottom nav
    expect(find.text('Remote'), findsOneWidget);
    expect(find.text('Cast'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
  });

  // The controller is the wiring layer between the UI and the ControlAdapter
  // contract; testing it directly proves every button's effect without fragile
  // hit-test geometry. (Visual/interaction is verified by the web render.)
  group('RemoteController wiring', () {
    test('type() appends to the TV buffer and logs a sendText', () {
      final c = RemoteController()..tvText = '';
      c.type('l');
      c.type('o');
      expect(c.tvText, 'lo');
      expect(c.actionLog.where((a) => a.contains('text')).length, 2);
    });

    test('backspace() and clearText() edit the buffer', () {
      final c = RemoteController()..tvText = 'abc';
      c.backspace();
      expect(c.tvText, 'ab');
      c.clearText();
      expect(c.tvText, '');
    });

    test('key() logs a key command', () {
      final c = RemoteController();
      c.key(core.Key.ok);
      expect(c.actionLog.first, contains('ok'));
    });

    test('launch() logs launchApp with the app name', () {
      final c = RemoteController();
      c.launch('NETFLIX');
      expect(c.actionLog.first, contains('NETFLIX'));
    });

    test('setSource() updates the source and logs setInput', () {
      final c = RemoteController();
      c.setSource('HDMI 2');
      expect(c.currentSource, 'HDMI 2');
      expect(c.actionLog.first, contains('HDMI 2'));
    });
  });
}
