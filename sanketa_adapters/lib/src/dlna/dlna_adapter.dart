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

class DlnaAdapter extends ControlAdapter implements MediaCaster {
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
        textMode: TextInjectionMode.none,
        wake: false,
        appLaunch: false,
        inputList: false,
        volumeReadback: true,
        stateReadback: false,
        canCast: true,
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
  Future<CommandResult> sendKey(Key key,
      {PressType press = PressType.tap}) async {
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
        return CommandResult.failure(
            'key not supported by DLNA renderer: ${key.name}');
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

  @override
  Future<int?> getVolume() async => null;
  @override
  Future<bool?> getMuted() async => null;
  @override
  Future<PowerState?> getPowerState() async => null;
  @override
  Future<AppRef?> getCurrentApp() async => null;

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

  // --- MediaCaster -----------------------------------------------------------

  @override
  Future<CastResult> castUri(
    String uri, {
    String? mimeType,
    String? title,
  }) async {
    final meta = _didlMetadata(uri, mimeType, title);
    final r = await playUri(uri, metadata: meta);
    return r.ok
        ? const CastResult.success()
        : CastResult.failure(r.error ?? 'cast failed');
  }

  @override
  Future<CastResult> castPause() async {
    final r = await _av1('Pause', '');
    return r.ok
        ? const CastResult.success()
        : CastResult.failure(r.error ?? 'pause failed');
  }

  @override
  Future<CastResult> castResume() async {
    final r = await _av1('Play', '<Speed>1</Speed>');
    return r.ok
        ? const CastResult.success()
        : CastResult.failure(r.error ?? 'resume failed');
  }

  @override
  Future<CastResult> castStop() async {
    final r = await _av1('Stop', '');
    return r.ok
        ? const CastResult.success()
        : CastResult.failure(r.error ?? 'stop failed');
  }

  String _didlMetadata(String uri, String? mimeType, String? title) {
    final t = title ?? 'Media';
    final m = mimeType ?? 'video/mp4';
    final upnpClass = _upnpClass(m);
    const dlnaFlags = 'DLNA.ORG_OP=01;DLNA.ORG_FLAGS='
        '01700000000000000000000000000000';
    return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
        '<item id="1" parentID="0" restricted="1">'
        '<dc:title>${_xml(t)}</dc:title>'
        '<upnp:class>$upnpClass</upnp:class>'
        '<res protocolInfo="http-get:*:$m:$dlnaFlags">${_xml(uri)}</res>'
        '</item></DIDL-Lite>';
  }

  static String _upnpClass(String mime) {
    if (mime.startsWith('image/')) return 'object.item.imageItem.photo';
    if (mime.startsWith('audio/')) return 'object.item.audioItem.musicTrack';
    return 'object.item.videoItem';
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
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return CommandResult.success(latency: sw.elapsed);
      }
      return CommandResult.failure(_humanSoapError(res.body, res.statusCode));
    } on Object {
      return const CommandResult.failure(
          'Could not reach the device. Check that it is powered on and connected to WiFi.');
    }
  }

  Future<int?> _getVolume() async {
    try {
      final res = await _soap(
          _rc, _renderingControl, 'GetVolume', '<Channel>Master</Channel>');
      final m =
          RegExp(r'<CurrentVolume>(\d+)</CurrentVolume>').firstMatch(res.body);
      return m == null ? null : int.tryParse(m.group(1)!);
    } on Object {
      return null;
    }
  }

  Future<CommandResult> _adjustVolume(int delta) async {
    final cur = await _getVolume();
    if (cur == null) {
      return const CommandResult.failure(
          'Could not read the device volume. The device may have disconnected.');
    }
    final next = (cur + delta).clamp(0, 100);
    try {
      final res = await _soap(_rc, _renderingControl, 'SetVolume',
          '<Channel>Master</Channel><DesiredVolume>$next</DesiredVolume>');
      return res.statusCode >= 200 && res.statusCode < 300
          ? const CommandResult.success()
          : const CommandResult.failure(
              'Could not change the volume. The device may have disconnected.');
    } on Object {
      return const CommandResult.failure(
          'Could not reach the device. Check that it is powered on and connected to WiFi.');
    }
  }

  Future<CommandResult> _toggleMute() async {
    int cur;
    try {
      final res = await _soap(
          _rc, _renderingControl, 'GetMute', '<Channel>Master</Channel>');
      final m = RegExp(r'<CurrentMute>(\d)</CurrentMute>').firstMatch(res.body);
      cur = m == null ? 0 : int.parse(m.group(1)!);
    } on Object {
      return const CommandResult.failure(
          'Could not reach the device. Check that it is powered on and connected to WiFi.');
    }
    final next = cur == 0 ? 1 : 0;
    try {
      final res = await _soap(_rc, _renderingControl, 'SetMute',
          '<Channel>Master</Channel><DesiredMute>$next</DesiredMute>');
      return res.statusCode >= 200 && res.statusCode < 300
          ? const CommandResult.success()
          : const CommandResult.failure(
              'Could not change mute. The device may have disconnected.');
    } on Object {
      return const CommandResult.failure(
          'Could not reach the device. Check that it is powered on and connected to WiFi.');
    }
  }

  static String _humanSoapError(String body, int statusCode) {
    final desc =
        RegExp(r'<errorDescription>([^<]+)</errorDescription>').firstMatch(body);
    if (desc != null) {
      final raw = desc.group(1)!.trim();
      final mapped = _mapUpnpError(raw);
      if (mapped != null) return mapped;
      return '$raw. Try a different file or check that the device supports this format.';
    }
    final code =
        RegExp(r'<errorCode>(\d+)</errorCode>').firstMatch(body);
    if (code != null) {
      final mapped = _mapUpnpErrorCode(int.tryParse(code.group(1)!) ?? 0);
      if (mapped != null) return mapped;
    }
    if (statusCode == 500) {
      return 'The device rejected the request. It may not support this media format.';
    }
    return 'The device returned an unexpected response. Try again or use a different file.';
  }

  static String? _mapUpnpError(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('not implemented') || lower.contains('not supported')) {
      return 'This device does not support media casting. Try a different device.';
    }
    if (lower.contains('mime') || lower.contains('format')) {
      return 'This device does not support this media format. Try a different file.';
    }
    if (lower.contains('resource not found')) {
      return 'The device could not access the file. Make sure both devices are on the same WiFi network.';
    }
    if (lower.contains('transport is locked') || lower.contains('busy')) {
      return 'The device is busy with another task. Stop the current playback first.';
    }
    return null;
  }

  static String? _mapUpnpErrorCode(int code) => switch (code) {
        704 => 'This device does not support this media format. Try a different file.',
        714 => 'This device does not support this media format. Try a different file.',
        716 => 'The device could not access the file. Make sure both devices are on the same WiFi network.',
        705 || 715 => 'The device is busy with another task. Stop the current playback first.',
        _ => null,
      };

  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
