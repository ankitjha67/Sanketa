import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/bravia/simple_ip_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late ServerSocket server;
  late SimpleIpAdapter adapter;
  late Map<String, String> responses;

  setUp(() async {
    responses = {
      'POWR': '*SAPOWR0000000000000001\n',
      'VOLU': '*SAVOLU0000000000000025\n',
      'AMUT': '*SAAMUT0000000000000000\n',
    };
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      socket.listen((data) {
        final frame = utf8.decode(data).trim();
        // Parse enquiry: *SEXXXX################
        final re = RegExp(r'\*SE(\w{4})');
        final match = re.firstMatch(frame);
        if (match != null) {
          final cmd = match.group(1)!;
          final resp = responses[cmd];
          if (resp != null) socket.write(resp);
        }
        // Parse set: *SCXXXX<param>
        final setRe = RegExp(r'\*SC(\w{4})');
        final setMatch = setRe.firstMatch(frame);
        if (setMatch != null) {
          final cmd = setMatch.group(1)!;
          socket.write('*SA${cmd}0000000000000000\n');
        }
      });
    });
    adapter = SimpleIpAdapter(host: '127.0.0.1', port: server.port);
  });

  tearDown(() async {
    await server.close();
  });

  test('capabilities report stateReadback and volumeReadback as true', () {
    final caps = adapter.capabilities();
    expect(caps.stateReadback, isTrue);
    expect(caps.volumeReadback, isTrue);
  });

  test('connect succeeds against a responding server', () async {
    await adapter.connect();
  });

  test('heartbeat returns true when server responds', () async {
    expect(await adapter.heartbeat(), isTrue);
  });

  test('readState emits volume, mute, and power from enquiry responses',
      () async {
    final delta = await adapter.readState().first;
    expect(delta.volume, 25);
    expect(delta.muted, isFalse);
    expect(delta.power, PowerState.on);
  });

  test('readState reflects changed TV state on next poll', () async {
    // First read: vol=25, unmuted, power on
    final first = await adapter.readState().first;
    expect(first.volume, 25);

    // Change server responses for next adapter instance (new stream)
    responses['VOLU'] = '*SAVOLU0000000000000042\n';
    responses['AMUT'] = '*SAAMUT0000000000000001\n';
    responses['POWR'] = '*SAPOWR0000000000000000\n';

    final second = await adapter.readState().first;
    expect(second.volume, 42);
    expect(second.muted, isTrue);
    expect(second.power, PowerState.standby);
  });

  test('sendKey(ok) sends the IRCC set command', () async {
    final result = await adapter.sendKey(Key.ok);
    expect(result.ok, isTrue);
  });

  test('power on/off sends POWR set command', () async {
    final on = await adapter.power(on: true);
    expect(on.ok, isTrue);
    final off = await adapter.power(on: false);
    expect(off.ok, isTrue);
  });
}
