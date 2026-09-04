/// Generic DLNA / UPnP media-renderer adapter (Rung 2 — broadest coverage).
///
/// Any UPnP MediaRenderer — old media boxes, blu-ray players, many TVs — exposes
/// AVTransport (play/pause/stop, set URI) and RenderingControl (volume, mute)
/// over SOAP. This adapter gives those transport + volume controls through the
/// same [ControlAdapter] contract; per FR-3.5 it declares no D-pad and no text,
/// so the UI shows only what a renderer can do. [playUri] is the casting entry
/// point the media engine (FR-7.1) will call.
///
/// Control URLs come from the device description document; parsing that is the
/// discovery layer's job — they are injected here.
library;

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

const _avTransport = 'urn:schemas-upnp-org:service:AVTransport:1';
const _renderingControl = 'urn:schemas-upnp-org:service:RenderingControl:1';

class DlnaAdapter implements ControlAdapter {
  DlnaAdapter({
    required Uri avTransportControlUrl,
    required Uri renderingControlUrl,
    http.Client? client,
    int volumeStep = 5,
  })  : _av = avTransportControlUrl,
        _rc = renderingControlUrl,
        _client = client ?? http.Client(),
        _step = volumeStep;

  final Uri _av;
  final Uri _rc;
  final http.Client _client;
  final int _step;

  static const _keys = {
    Key.play,
    Key.pause,
    Key.playPause,
    Key.stop,
    Key.volumeUp,
    Key.volumeDown,
    Key.mute,
  };

  @override
  String get id => 'dlna';

  @override
  BrandFamily get brandFamily => BrandFamily.dlna;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:schemas-upnp-org:device:MediaRenderer:1'],
      );

  @override
  CapabilityMap capabilities() => const CapabilityMap(
        keys: _keys,
        textMode: TextInjectionMode.none, // renderers have no text field
        wake: false,
        appLaunch: false,
        inputList: false,
        volumeReadback: true, // GetVolume works
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async =>
      const PairingResult.paired('dlna:open'); // no auth

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> heartbeat() async {
    final r = await _getVolume();
    return r != null;
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) async {
    switch (key) {
      case Key.play:
      case Key.playPause:
        return _av1('Play', '<Speed>1</Speed>');
      case Key.pause:
        return _av1('Pause', '');
      case Key.stop:
        return _av1('Stop', '');
      case Key.volumeUp:
        return _adjustVolume(_step);
      case Key.volumeDown:
        return _adjustVolume(-_step);
      case Key.mute:
        return _toggleMute();
      default:
        return CommandResult.failure('key not supported by DLNA renderer: ${key.name}');
    }
  }

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.failure('DLNA renderers have no text input');

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.failure('DLNA has no app launch');

  @override
  Future<CommandResult> setInput(InputRef input) async =>
      const CommandResult.failure('DLNA has no input switching');

  @override
  Future<CommandResult> power({required bool on}) async =>
      const CommandResult.failure('DLNA renderers have no power control');

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  /// Cast a media URL to the renderer (SetAVTransportURI + Play). The entry
  /// point the casting engine (FR-7.1) uses.
  Future<CommandResult> playUri(String uri, {String metadata = ''}) async {
    final set = await _av1(
      'SetAVTransportURI',
      '<CurrentURI>${_xml(uri)}</CurrentURI>'
          '<CurrentURIMetaData>${_xml(metadata)}</CurrentURIMetaData>',
    );
    if (!set.ok) return set;
    return _av1('Play', '<Speed>1</Speed>');
  }

  // --- SOAP plumbing ---------------------------------------------------------

  Future<http.Response> _soap(
      Uri url, String service, String action, String args) {
    final envelope = '<?xml version="1.0"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
        '<u:$action xmlns:u="$service"><InstanceID>0</InstanceID>$args</u:$action>'
        '</s:Body></s:Envelope>';
    return _client.post(
      url,
      headers: {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SOAPACTION': '"$service#$action"',
      },
      body: envelope,
    );
  }

  Future<CommandResult> _av1(String action, String args) async {
    final sw = Stopwatch()..start();
    try {
      final res = await _soap(_av, _avTransport, action, args);
      return res.statusCode >= 200 && res.statusCode < 300
          ? CommandResult.success(latency: sw.elapsed)
          : CommandResult.failure('http ${res.statusCode}');
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  Future<int?> _getVolume() async {
    try {
      final res = await _soap(
          _rc, _renderingControl, 'GetVolume', '<Channel>Master</Channel>');
      final m = RegExp(r'<CurrentVolume>(\d+)</CurrentVolume>').firstMatch(res.body);
      return m == null ? null : int.tryParse(m.group(1)!);
    } on Object {
      return null;
    }
  }

  Future<CommandResult> _adjustVolume(int delta) async {
    final cur = await _getVolume();
    if (cur == null) return const CommandResult.failure('could not read volume');
    final next = (cur + delta).clamp(0, 100);
    try {
      final res = await _soap(_rc, _renderingControl, 'SetVolume',
          '<Channel>Master</Channel><DesiredVolume>$next</DesiredVolume>');
      return res.statusCode >= 200 && res.statusCode < 300
          ? const CommandResult.success()
          : CommandResult.failure('http ${res.statusCode}');
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  Future<CommandResult> _toggleMute() async {
    int cur;
    try {
      final res = await _soap(
          _rc, _renderingControl, 'GetMute', '<Channel>Master</Channel>');
      final m = RegExp(r'<CurrentMute>(\d)</CurrentMute>').firstMatch(res.body);
      cur = m == null ? 0 : int.parse(m.group(1)!);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
    final next = cur == 0 ? 1 : 0;
    final res = await _soap(_rc, _renderingControl, 'SetMute',
        '<Channel>Master</Channel><DesiredMute>$next</DesiredMute>');
    return res.statusCode >= 200 && res.statusCode < 300
        ? const CommandResult.success()
        : CommandResult.failure('http ${res.statusCode}');
  }

  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
