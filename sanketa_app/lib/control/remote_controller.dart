import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_adapters/sanketa_adapters.dart' as adapters;
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_discovery/sanketa_discovery.dart';
import 'package:sanketa_ir/sanketa_ir.dart' as ir;

import '../native/bridge_ir_transmitter.dart';
import '../native/multicast_lock.dart';
import '../native/platform_bridge.dart';
import '../native/screen_mirror_bridge.dart';
import '../native/stub_bridge.dart';
import 'custom_layout_service.dart';
import 'demo_adapter.dart';
import 'ir_device_service.dart';
import 'macro_service.dart';
import 'parental_control_service.dart';
import 'sleep_timer_service.dart';
import 'voice_control_service.dart';

enum ScanState { idle, scanning, done }

/// Result of probing which protocols are reachable on a given host.
class ProtocolProbe {
  const ProtocolProbe({
    this.atvrs = false,
    this.simpleIp = false,
    this.dlna = false,
    this.googleCast = false,
    this.airplay = false,
    this.dial = false,
    this.webos = false,
    this.tizen = false,
    this.roku = false,
    this.panasonic = false,
    this.philips = false,
    this.hisense = false,
  });

  final bool atvrs;
  final bool simpleIp;
  final bool dlna;
  final bool googleCast;
  final bool airplay;
  final bool dial;
  final bool webos;
  final bool tizen;
  final bool roku;
  final bool panasonic;
  final bool philips;
  final bool hisense;

  List<String> get available {
    final r = <String>[];
    if (atvrs) r.add('android_tv');
    if (simpleIp) r.add('bravia');
    if (dlna) r.add('dlna');
    if (googleCast) r.add('cast');
    if (airplay) r.add('airplay');
    if (webos) r.add('webos');
    if (tizen) r.add('tizen');
    if (roku) r.add('roku');
    if (dial) r.add('dial');
    if (panasonic) r.add('panasonic');
    if (philips) r.add('philips');
    if (hisense) r.add('hisense');
    return r;
  }
}

class RemoteController extends ChangeNotifier {
  RemoteController({
    List<core.DiscoveryBackend>? backends,
    IrBridge? irBridge,
    IrDeviceService? irDeviceService,
  }) {
    irService = irDeviceService ?? IrDeviceService();
    _adapter = DemoAdapter(_record);
    _engine = core.DiscoveryEngine(
      backends: backends ?? [SsdpBackend(), MdnsBackend()],
    );
    _deviceSub = _engine.devices.listen((list) {
      if (_disposed) return;
      discoveredDevices = list;
      notifyListeners();
    });
    _irTransmitter = BridgeIrTransmitter(irBridge ?? StubIrBridge());
    sleepTimer.onExpired = () => power(false);
    unawaited(macroService.load());
    unawaited(layoutService.load());
    unawaited(parentalControls.load());
    unawaited(voiceControl.checkAvailability());
    unawaited(refreshIrHardware());
    unawaited(_initializeIrDatabase());
  }

  late core.ControlAdapter _adapter;
  core.ControlAdapter get adapter => _adapter;
  core.CapabilityMap get caps => _adapter.capabilities();
  core.DiscoveredDevice? get selectedDevice => _selectedDevice;

  late final BridgeIrTransmitter _irTransmitter;
  bool _disposed = false;
  late final IrDeviceService irService;

  final SleepTimerService sleepTimer = SleepTimerService();
  final MacroService macroService = MacroService();
  final CustomLayoutService layoutService = CustomLayoutService();
  final ParentalControlService parentalControls = ParentalControlService();
  final VoiceControlService voiceControl = VoiceControlService();

  // Per-device ATVRS certificate (generated at first launch, persisted).
  static String? _cachedCertPem;
  static String? _cachedKeyPem;

  static Future<({String certPem, String keyPem})> _ensureDeviceCert() async {
    if (_cachedCertPem != null && _cachedKeyPem != null) {
      return (certPem: _cachedCertPem!, keyPem: _cachedKeyPem!);
    }
    final dir = await getApplicationSupportDirectory();
    final certFile = File('${dir.path}/atvrs_cert.pem');
    final keyFile = File('${dir.path}/atvrs_key.pem');

    if (await certFile.exists() && await keyFile.exists()) {
      _cachedCertPem = await certFile.readAsString();
      _cachedKeyPem = await keyFile.readAsString();
      debugPrint('[SANKETA] loaded existing ATVRS cert from ${dir.path}');
    } else {
      debugPrint('[SANKETA] generating new per-device ATVRS cert ...');
      final gen = adapters.generateSelfSignedCert();
      await certFile.writeAsString(gen.certPem);
      await keyFile.writeAsString(gen.keyPem);
      _cachedCertPem = gen.certPem;
      _cachedKeyPem = gen.keyPem;
      debugPrint('[SANKETA] saved new ATVRS cert to ${dir.path}');
    }
    return (certPem: _cachedCertPem!, keyPem: _cachedKeyPem!);
  }

  /// Force regeneration of the ATVRS certificate (e.g. after a pairing reset).
  static Future<void> resetDeviceCert() async {
    _cachedCertPem = null;
    _cachedKeyPem = null;
    final dir = await getApplicationSupportDirectory();
    final certFile = File('${dir.path}/atvrs_cert.pem');
    final keyFile = File('${dir.path}/atvrs_key.pem');
    if (await certFile.exists()) await certFile.delete();
    if (await keyFile.exists()) await keyFile.delete();
    debugPrint('[SANKETA] ATVRS cert reset — will regenerate on next use');
  }
  IrDeviceEntry? activeIrEntry;
  bool get hasIrHardware => _irTransmitter.available;
  bool irHardwareChecked = false;
  bool get isIrDevice => _adapter is ir.IrControlAdapter;

  Future<void> refreshIrHardware() async {
    try {
      await _irTransmitter.init();
    } on Object {
      // Capability checks are best-effort; a platform-channel failure means IR
      // is unavailable, not that app startup should fail.
    }
    if (_disposed) return;
    irHardwareChecked = true;
    notifyListeners();
  }

  Future<void> _initializeIrDatabase() async {
    await irService.initialize();
    if (_disposed) return;
    notifyListeners();
  }

  late final core.DiscoveryEngine _engine;
  StreamSubscription<List<core.DiscoveredDevice>>? _deviceSub;

  final List<String> actionLog = <String>[];
  final List<String> recentSearches = <String>[];
  String currentSource = 'HDMI 1';
  String tvText = '';
  Future<void> _textOpChain = Future.value();
  bool capsLock = false;
  bool numberMode = false;
  int navIndex = 0;
  String deviceName = '';
  bool isConnected = false;
  bool isConnecting = false;
  String? connectionError;
  String? lastCommandError;
  bool isMuted = false;
  bool isPoweredOn = true;
  int tvVolume = -1;
  StreamSubscription<core.StateDelta>? _stateSub;
  ScanState scanState = ScanState.idle;
  List<core.DiscoveredDevice> discoveredDevices = [];
  core.ScanResult? lastScanResult;
  String? scanError;
  int _consecutiveFailures = 0;
  int _connectionGeneration = 0;
  core.DiscoveredDevice? _selectedDevice;
  String? launchResult;

  // --- Per-device settings ---------------------------------------------------
  ProtocolProbe? protocolProbe;
  bool isProbing = false;
  String? forcedAdapterId;
  bool hapticEnabled = true;
  bool autoReconnect = true;
  bool touchpadMode = false;

  void toggleTouchpad() {
    touchpadMode = !touchpadMode;
    notifyListeners();
  }

  // --- Sleep timer -----------------------------------------------------------
  VoidCallback? showSleepTimerSheet;

  void startSleepTimer(Duration duration) {
    sleepTimer.onExpired = () => power(false);
    sleepTimer.start(duration);
    notifyListeners();
  }

  /// The live ATVRS channel for the current connection (if ATVRS-based).
  /// Tracked here so we can read negotiatedFeatures for the settings UI.
  adapters.AtvChannel? _liveAtvChannel;

  /// Auto-detected feature map: feature name → detection source description.
  Map<String, String> get detectedFeatures {
    final map = <String, String>{};
    final adapterId = _adapter.id;
    final caps = _adapter.capabilities();

    if (adapterId == 'android_tv' || adapterId == 'fire_tv') {
      final f = _liveAtvChannel?.negotiatedFeatures ?? 0;
      if (f > 0) {
        map['D-pad / Keys'] =
            (f & 2 != 0) ? 'ATVRS handshake (bit 2)' : 'Not reported';
        map['Keyboard (IME)'] =
            (f & 4 != 0) ? 'ATVRS handshake (bit 4)' : 'Not reported';
        map['Volume'] =
            (f & 64 != 0) ? 'ATVRS handshake (bit 64)' : 'Not reported';
        map['Power'] =
            (f & 32 != 0) ? 'ATVRS handshake (bit 32)' : 'Not reported';
        map['App Launch'] =
            (f & 512 != 0) ? 'ATVRS handshake (bit 512)' : 'Not reported';
        map['Ping/Keepalive'] =
            (f & 1 != 0) ? 'ATVRS handshake (bit 1)' : 'Not reported';
        map['Features'] = 'Negotiated with TV';
      } else {
        map['Status'] = 'Waiting for handshake...';
      }
    } else if (adapterId == 'tizen') {
      map['D-pad / Keys'] = 'Tizen WebSocket (SendRemoteKey)';
      map['Keyboard'] = 'Tizen WebSocket (SendInputString)';
      map['Volume'] = 'Tizen key codes (KEY_VOLUP/DOWN)';
      map['Power'] = 'Tizen key codes (KEY_POWER)';
      map['Wake'] = 'WoWLAN (native)';
    } else if (adapterId == 'webos') {
      map['D-pad / Keys'] = 'webOS WebSocket API';
      map['Volume'] = 'webOS ssap://audio/*';
      map['App Launch'] = 'webOS ssap://system.launcher/*';
    } else if (adapterId == 'bravia_simple_ip' || adapterId == 'bravia') {
      map['D-pad / Keys'] = 'Simple IP (port 20060)';
      map['Volume'] = 'Simple IP readback';
      map['Keyboard'] = _atvrs?.isConnected == true
          ? 'ATVRS sidecar (port 6466)'
          : 'Requires ATVRS pairing';
      map['State Readback'] = 'Simple IP volume/power stream';
    } else if (adapterId == 'roku') {
      map['D-pad / Keys'] = 'Roku ECP (port 8060)';
      map['App Launch'] = 'Roku ECP /launch/{appId}';
      map['Keyboard'] = 'Roku ECP /keypress/Lit_*';
    } else if (adapterId == 'hisense') {
      map['D-pad / Keys'] = 'Hisense VIDAA MQTT (sendkey)';
      map['Volume'] = 'Hisense VIDAA MQTT (volume)';
      map['App Launch'] = 'Hisense VIDAA MQTT (launchapp)';
    } else if (adapterId == 'dlna') {
      map['Volume'] = 'UPnP RenderingControl';
      map['Media Casting'] = 'UPnP AVTransport';
    } else {
      for (final entry in {
        'D-pad': caps.keys.isNotEmpty,
        'Keyboard': caps.canType,
        'Volume': caps.supports(core.Key.volumeUp),
        'App Launch': caps.appLaunch,
      }.entries) {
        map[entry.key] = entry.value ? 'Protocol default' : 'Not available';
      }
    }
    return map;
  }

  // --- Casting state (FR-7.1) -----------------------------------------------
  final adapters.MediaServer _mediaServer = adapters.MediaServer();
  core.MediaCaster? _caster;
  bool _castExplicit = false;
  core.CastSession castSession = core.CastSession.idle;
  bool get canCast => _caster != null;
  bool dlnaProbeComplete = false;
  String castDeviceName = '';
  bool isCastConnecting = false;
  String? castConnectionError;
  String castProtocol = '';
  String? _castTargetHost;
  adapters.HlsProxyServer? _hlsAdProxy;

  // --- Screen mirroring (FR-7.2) -------------------------------------------
  final ScreenMirrorBridge _mirrorBridge = ScreenMirrorBridge();
  adapters.LiveStreamServer? _hlsServer;
  bool isMirroring = false;
  String? mirrorError;
  String mirrorMode = '';
  String? mirrorReceiverUrl;

  String get transportLabel {
    switch (_adapter.transport) {
      case core.Transport.network:
        return 'Network';
      case core.Transport.infrared:
        return 'IR Blaster';
      case core.Transport.bridge:
        return 'WiFi-IR Bridge';
    }
  }

  String get transportBadge {
    switch (_adapter.transport) {
      case core.Transport.network:
        return 'IP Link';
      case core.Transport.infrared:
        return 'Smart IR';
      case core.Transport.bridge:
        return 'WiFi-IR';
    }
  }

  Future<void> startScan() async {
    if (_disposed || scanState == ScanState.scanning) return;
    scanState = ScanState.scanning;
    scanError = null;
    notifyListeners();
    try {
      await acquireMulticastLock();
      lastScanResult = await _engine.scan(timeout: const Duration(seconds: 6));
      discoveredDevices = lastScanResult!.devices;
    } on Object {
      scanError = 'Device scan failed. Check WiFi permissions and try again.';
      // The user-facing error is intentionally stable across platform errors.
    } finally {
      try {
        await releaseMulticastLock();
      } on Object {
        // A failed cleanup must not leave the controller stuck in "scanning".
      }
    }
    if (_disposed) return;
    scanState = ScanState.done;
    notifyListeners();
  }

  void selectDevice(core.DiscoveredDevice d, {bool clearOverride = true}) {
    if (clearOverride) forcedAdapterId = null;
    deviceName = _shortDeviceName(d.device.displayName);
    _selectedDevice = d;
    connectionError = null;
    lastCommandError = null;
    isConnecting = true;
    isConnected = false;
    _consecutiveFailures = 0;
    if (forcedAdapterId == null) protocolProbe = null;
    notifyListeners();
    final generation = ++_connectionGeneration;
    unawaited(_connectToDevice(d, generation));
  }

  Future<void> _connectToDevice(core.DiscoveredDevice d, int generation) async {
    final previous = _adapter;
    if (!_castExplicit) {
      _caster = null;
      castDeviceName = '';
      _castTargetHost = null;
    }
    unawaited(_mediaServer.stop());
    castSession = core.CastSession.idle;
    _stateSub?.cancel();
    _stateSub = null;
    tvVolume = -1;
    try {
      final next = await _createAdapter(d);
      try {
        await previous.disconnect();
      } on Object {
        // Best-effort cleanup; the new selection should still be attempted.
      }
      if (_disposed || generation != _connectionGeneration) return;
      _adapter = next;
      await next.connect();
      if (_disposed || generation != _connectionGeneration) {
        await next.disconnect();
        return;
      }
      isConnected = true;
      connectionError = null;

      // For BRAVIA, _atvrs provides the keyboard channel alongside SimpleIP.
      // For non-BRAVIA ATVRS adapters, the adapter's own channel handles
      // port 6466, so we only need _atvrs for pairing (port 6467).
      if (d.adapterId == 'bravia') {
        final atvrs = _atvrs;
        if (atvrs != null) {
          try {
            await atvrs.connect();
          } on Object {
            // Not paired yet — UI will prompt via needsAtvrsPairing.
          }
        }
      }

      // Subscribe to TV state readback (volume, mute, power) if supported.
      _stateSub?.cancel();
      _stateSub = null;
      if (next.capabilities().stateReadback) {
        _stateSub = next.readState().listen((delta) {
          if (_disposed || generation != _connectionGeneration) return;
          var changed = false;
          if (delta.volume != null && delta.volume != tvVolume) {
            tvVolume = delta.volume!;
            changed = true;
          }
          if (delta.muted != null && delta.muted != isMuted) {
            isMuted = delta.muted!;
            changed = true;
          }
          if (delta.power != null) {
            final on = delta.power == core.PowerState.on;
            if (on != isPoweredOn) {
              isPoweredOn = on;
              changed = true;
            }
          }
          if (changed) notifyListeners();
        });
      }

      // Probe all reachable protocols in the background for the settings page.
      if (forcedAdapterId == null) {
        unawaited(probeProtocols());
      }

      // Probe for DLNA casting capability in the background, unless the user
      // has explicitly picked a separate cast device.
      if (!_castExplicit) {
        if (next is core.MediaCaster) {
          _caster = next as core.MediaCaster;
          castDeviceName = d.device.displayName;
          _castTargetHost = d.device.host;
        } else {
          unawaited(_probeDlnaCaster(d, generation));
        }
      }
    } on StateError catch (e) {
      if (!_disposed && generation == _connectionGeneration) {
        debugPrint('[SANKETA] Connection StateError (${d.adapterId}): $e');
        isConnected = false;
        connectionError = _humanConnectionError(e.message, d);
      }
    } on Object catch (e, st) {
      if (!_disposed && generation == _connectionGeneration) {
        debugPrint('[SANKETA] Connection error (${d.adapterId}): $e\n$st');
        isConnected = false;
        connectionError = _humanConnectionError('$e', d);
      }
    } finally {
      if (!_disposed && generation == _connectionGeneration) {
        isConnecting = false;
        notifyListeners();
      }
    }
  }

  void retryConnection() {
    final d = _selectedDevice;
    if (d != null) selectDevice(d);
  }

  adapters.BraviaAtvrs? _atvrs;

  Future<core.ControlAdapter> _createAdapter(core.DiscoveredDevice d) async {
    final host = d.device.host;
    if (host == null) {
      _liveAtvChannel = null;
      return DemoAdapter(_record);
    }

    final cert = await _ensureDeviceCert();
    _atvrs = null;
    _liveAtvChannel = null;
    switch (d.adapterId) {
      case 'bravia':
        _atvrs = _makePairingHelper(host, cert);
        return adapters.SimpleIpAdapter(
          host: host,
          atvrs: _atvrs,
          dial: adapters.DialClient(
            appsBaseUrl: _dialBaseUrl(d, host),
          ),
        );
      case 'roku':
        return adapters.RokuAdapter(host: host);
      case 'vizio':
        return adapters.VizioAdapter(host: host);
      case 'webos':
        return adapters.WebosAdapter(
          channel: adapters.LiveWsChannel(
            url: 'wss://$host:3001',
            fallbackUrl: 'ws://$host:3000',
          ),
        );
      case 'tizen':
        final name = Uri.encodeComponent(
            base64Encode(utf8.encode('Sanketa')));
        return adapters.TizenAdapter(
          channel: adapters.LiveWsChannel(
            url: 'wss://$host:8002/api/v2/channels/'
                'samsung.remote.control?name=$name',
            fallbackUrl: 'ws://$host:8001/api/v2/channels/'
                'samsung.remote.control?name=$name',
          ),
        );
      case 'android_tv':
        _atvrs = _makePairingHelper(host, cert);
        final ch = adapters.LiveAtvChannel(
          host: host,
          certPem: cert.certPem,
          keyPem: cert.keyPem,
        );
        _liveAtvChannel = ch;
        return adapters.AndroidTvAdapter(channel: ch);
      case 'fire_tv':
        _atvrs = _makePairingHelper(host, cert);
        final ch = adapters.LiveAtvChannel(
          host: host,
          certPem: cert.certPem,
          keyPem: cert.keyPem,
        );
        _liveAtvChannel = ch;
        return adapters.FireTvAdapter(channel: ch);
      case 'philips':
        return adapters.PhilipsAdapter(host: host);
      case 'panasonic':
        return adapters.PanasonicAdapter(host: host);
      case 'hisense':
        return adapters.HisenseAdapter(host: host);
      case 'broadlink':
        // BroadLink WiFi-IR bridge. Requires a codeset (selected via the IR
        // wizard). If no codeset is active, fall through to a default.
        final blCodeset = activeIrEntry;
        if (blCodeset != null) {
          final cs = await irService.loadCodeset(blCodeset);
          final macStr = d.metadata['mac'] ?? '';
          final devType = int.tryParse(
                d.metadata['broadlink_type']?.replaceFirst('0x', '') ?? '',
                radix: 16,
              ) ??
              0;
          final model = adapters.classifyDeviceType(devType) ??
              adapters.BroadLinkModel.rmMini3;
          final mac = macStr.split(':').map((s) => int.tryParse(s, radix: 16) ?? 0);
          final blDevice = adapters.BroadLinkDevice(
            host: host,
            mac: Uint8List.fromList(mac.toList()),
            deviceType: devType,
            model: model,
            name: d.device.friendlyName,
          );
          return adapters.BroadLinkAdapter(device: blDevice, codeset: cs);
        }
        return DemoAdapter(_record);
      case 'dlna':
        if (await _isAtvrsReachable(host)) {
          _atvrs = _makePairingHelper(host, cert);
          final ch = adapters.LiveAtvChannel(
            host: host,
            certPem: cert.certPem,
            keyPem: cert.keyPem,
          );
          _liveAtvChannel = ch;
          return adapters.AndroidTvAdapter(channel: ch);
        }
        final location = d.metadata['location'];
        if (location != null) {
          return _createDlnaFromLocation(host, location);
        }
        return _createDlnaFallback(host);
      case null:
      default:
        _atvrs = _makePairingHelper(host, cert);
        final ch = adapters.LiveAtvChannel(
          host: host,
          certPem: cert.certPem,
          keyPem: cert.keyPem,
        );
        _liveAtvChannel = ch;
        return adapters.AndroidTvAdapter(channel: ch);
    }
  }

  adapters.BraviaAtvrs _makePairingHelper(
    String host,
    ({String certPem, String keyPem}) cert,
  ) =>
      adapters.BraviaAtvrs(
        host: host,
        certPem: cert.certPem,
        keyPem: cert.keyPem,
        onDisconnect: _onAtvrsDisconnect,
      );

  /// Quick TCP probe to see if ATVRS (Android TV Remote Service) is running.
  static Future<bool> _isAtvrsReachable(String host) async {
    try {
      final socket = await Socket.connect(host, 6466,
          timeout: const Duration(milliseconds: 500));
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  Uri _dialBaseUrl(core.DiscoveredDevice d, String host) {
    final discovered = d.metadata['application-url'];
    if (discovered != null && discovered.isNotEmpty) {
      final normalized =
          discovered.endsWith('/') ? discovered : '$discovered/';
      return Uri.parse(normalized);
    }
    return Uri.parse('http://$host:8008/apps/');
  }

  core.ControlAdapter _createDlnaFromLocation(String host, String location) {
    // Synchronous fallback: parse well-known Sony/generic paths from location.
    final uri = Uri.parse(location);
    final basePath = uri.path.substring(0, uri.path.lastIndexOf('/') + 1);
    return adapters.DlnaAdapter(
      avTransportControlUrl:
          uri.replace(path: '${basePath}upnp/control/AVTransport'),
      renderingControlUrl:
          uri.replace(path: '${basePath}upnp/control/RenderingControl'),
    );
  }

  core.ControlAdapter _createDlnaFallback(String host) {
    // Guess standard DLNA paths. The UPnP probe in _probeDlnaCaster will
    // find the correct URLs asynchronously for the caster.
    return adapters.DlnaAdapter(
      avTransportControlUrl:
          Uri.parse('http://$host:52323/upnp/control/AVTransport'),
      renderingControlUrl:
          Uri.parse('http://$host:52323/upnp/control/RenderingControl'),
    );
  }

  bool get needsAtvrsPairing {
    if (_atvrs == null) return false;
    // For BRAVIA, _atvrs IS the keyboard channel — pairing needed when it's
    // not connected. For non-BRAVIA (AndroidTvAdapter/FireTvAdapter), the
    // adapter handles port 6466 directly, and _atvrs is only for pairing.
    // Show the banner when the adapter failed to connect (not_paired).
    if (_adapter is adapters.SimpleIpAdapter) {
      return !_atvrs!.isConnected;
    }
    return !isConnected && connectionError != null;
  }

  bool get pairingIsForFullControl => _adapter is! adapters.SimpleIpAdapter;

  String? pairingError;

  void _onAtvrsDisconnect() {
    if (!_disposed) notifyListeners();
  }

  /// Probe all protocols reachable on the connected device's IP.
  Future<void> probeProtocols() async {
    final host = _selectedDevice?.device.host;
    if (host == null) return;
    isProbing = true;
    notifyListeners();

    bool atvrs = false, simpleIp = false, dlna = false;
    bool googleCast = false, airplay = false, webos = false;
    bool tizen = false, roku = false;
    bool panasonic = false, philips = false, hisense = false;
    final dial = _selectedDevice!.metadata['application-url'] != null;

    // Run TCP probes in parallel.
    final results = await Future.wait([
      _tcpProbe(host, 6466),  // ATVRS
      _tcpProbe(host, 20060), // Sony Simple IP
      _tcpProbe(host, 3000),  // webOS
      _tcpProbe(host, 8001).then((ok) async => ok || await _tcpProbe(host, 8002)), // Tizen
      _tcpProbe(host, 8060),  // Roku ECP
      adapters.probeGoogleCast(host), // Google Cast (port 8009 TLS)
      _tcpProbe(host, 55000), // Panasonic Viera
      _tcpProbe(host, 1925).then((ok) async => ok || await _tcpProbe(host, 1926)), // Philips JointSpace
      _tcpProbe(host, 36669).then((ok) async => ok || await _tcpProbe(host, 36670)), // Hisense VIDAA MQTT
    ]);

    atvrs = results[0];
    simpleIp = results[1];
    webos = results[2];
    tizen = results[3];
    roku = results[4];
    googleCast = results[5];
    panasonic = results[6];
    philips = results[7];
    hisense = results[8];

    // DLNA/UPnP probe is slightly heavier.
    final probe = adapters.UpnpProbe();
    final urls = await probe.probeHost(host);
    dlna = urls != null;

    // AirPlay probe.
    final ap = adapters.AirPlayCaster(host: host);
    airplay = await ap.isReachable();

    if (_disposed) return;
    protocolProbe = ProtocolProbe(
      atvrs: atvrs,
      simpleIp: simpleIp,
      dlna: dlna,
      googleCast: googleCast,
      airplay: airplay,
      dial: dial,
      webos: webos,
      tizen: tizen,
      roku: roku,
      panasonic: panasonic,
      philips: philips,
      hisense: hisense,
    );
    isProbing = false;
    notifyListeners();
  }

  static Future<bool> _tcpProbe(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port,
          timeout: const Duration(milliseconds: 800));
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  /// Switch the active protocol/adapter for the current device.
  Future<void> switchAdapter(String adapterId) async {
    final dev = _selectedDevice;
    if (dev == null) return;
    forcedAdapterId = adapterId;
    final overridden = core.DiscoveredDevice(
      device: dev.device,
      badges: dev.badges,
      sources: dev.sources,
      adapterId: adapterId,
      confident: dev.confident,
      metadata: dev.metadata,
    );
    selectDevice(overridden, clearOverride: false);
  }

  void toggleHaptic() {
    hapticEnabled = !hapticEnabled;
    notifyListeners();
  }

  void toggleAutoReconnect() {
    autoReconnect = !autoReconnect;
    notifyListeners();
  }

  Future<bool> pairAtvrs(Future<String> Function() requestPin) async {
    final atvrs = _atvrs;
    if (atvrs == null) return false;
    pairingError = null;

    final isNonBravia = _adapter is! adapters.SimpleIpAdapter;

    // For non-BRAVIA, try reconnecting the adapter's own channel first — the
    // TV may still have our client cert from a previous session.
    if (isNonBravia) {
      try {
        await _adapter.disconnect();
        await _adapter.connect();
        isConnected = true;
        connectionError = null;
        if (!_disposed) notifyListeners();
        return true;
      } on Object {
        // Need full pairing.
      }
    } else {
      if (await atvrs.ensureConnected()) {
        if (!_disposed) notifyListeners();
        return true;
      }
    }

    // Run full cert-exchange pairing on port 6467.
    var ok = atvrs.isPaired || await atvrs.pair(requestPin);
    if (!ok) {
      final err = atvrs.lastPairError;
      if (err == 'cancelled') {
        pairingError = null;
      } else {
        pairingError = err ?? 'Pairing failed. Check the code and try again.';
      }
      if (!_disposed) notifyListeners();
      return false;
    }

    if (isNonBravia) {
      // Some TVs need a few seconds to register the newly paired cert, or
      // may show a "Allow remote?" prompt that the user must accept.
      // Retry up to 5 times with escalating delays.
      var connected = false;
      for (var attempt = 1; attempt <= 5 && !connected; attempt++) {
        await Future<void>.delayed(Duration(seconds: attempt));
        debugPrint('[SANKETA] post-pair reconnect attempt $attempt/5');
        try {
          await _adapter.disconnect();
          await _adapter.connect();
          connected = true;
          isConnected = true;
          connectionError = null;
        } on Object catch (e) {
          debugPrint('[SANKETA] post-pair attempt $attempt failed: $e');
          if (attempt == 5) {
            pairingError =
                'Pairing completed but the TV still rejected the connection. '
                'Check if a prompt appeared on the TV to allow remote access, '
                'then tap Retry.';
            ok = false;
          }
        }
      }
    } else {
      try {
        await atvrs.connect();
      } on Object {
        pairingError = 'Paired successfully, but the keyboard channel didn\'t connect. Try reconnecting.';
        ok = false;
      }
    }
    if (!_disposed) notifyListeners();
    return ok;
  }

  String _humanConnectionError(String raw, core.DiscoveredDevice d) {
    if (raw == 'auth_failed') {
      return 'Authentication failed. The Pre-Shared Key does not match your TV.';
    }
    if (raw == 'not_paired') {
      return 'TV requires pairing. Tap "Pair Now" to enter the code shown on your TV.';
    }
    if (raw == 'unreachable' || raw.contains('Connection refused')) {
      if (d.adapterId == 'bravia') {
        return 'Could not reach the TV on port 20060. '
            'On the TV, open Settings → Network → IP Control '
            'and turn on Simple IP Control.';
      }
      return 'Could not reach ${d.device.displayName}. '
          'Make sure the TV is on and connected to the same WiFi network.';
    }
    return 'Could not connect to ${d.device.displayName}. Check that the TV is on and reachable.';
  }

  Future<void> selectIrDevice(IrDeviceEntry entry) async {
    final codeset = await irService.loadCodeset(entry);
    if (_disposed) return;
    ++_connectionGeneration;
    final previous = _adapter;
    unawaited(previous.disconnect().catchError((Object _) {}));
    activeIrEntry = entry;
    deviceName = entry.displayName;
    connectionError = null;
    lastCommandError = null;
    _consecutiveFailures = 0;
    _atvrs = null;
    _selectedDevice = null;
    _adapter = ir.IrControlAdapter(
      codeset: codeset,
      transmitter: _irTransmitter,
    );
    isConnected = true;
    isConnecting = false;
    notifyListeners();
  }

  /// Sends the candidate's toggle-power command without making it active.
  /// The user confirms the visible result before [selectIrDevice] saves it.
  Future<core.CommandResult> testIrDevice(IrDeviceEntry entry) async {
    ir.IrControlAdapter? candidate;
    try {
      final codeset = await irService.loadCodeset(entry);
      candidate = ir.IrControlAdapter(
        codeset: codeset,
        transmitter: _irTransmitter,
      );
      await candidate.connect();
      return await candidate.power(on: false);
    } on Object catch (error) {
      return core.CommandResult.failure('$error');
    } finally {
      await candidate?.disconnect();
    }
  }

  void addManualDevice(String host) {
    final endpoint = core.DiscoveredEndpoint(
      source: core.DiscoverySource.manual,
      host: host,
      friendlyName: host,
    );
    _engine.registry.ingest(endpoint);
    notifyListeners();
  }

  void _record(String action) {
    if (_disposed) return;
    actionLog.insert(0, action);
    if (actionLog.length > 12) actionLog.removeLast();
    notifyListeners();
  }

  void key(core.Key k, {core.PressType press = core.PressType.tap}) {
    if (parentalControls.isKeyBlocked(k)) return;
    debugPrint('[SANKETA] key pressed: ${k.name} press=$press');
    if (hapticEnabled) HapticFeedback.lightImpact();
    if (k == core.Key.mute) {
      isMuted = !isMuted;
      notifyListeners();
    }
    macroService.recordStep('key', argument: k.name);
    unawaited(_sendCommand(_adapter.sendKey(k, press: press)));
  }

  Future<void> _sendCommand(
    Future<core.CommandResult> future, {
    bool showFirstFailure = false,
  }) async {
    core.CommandResult result;
    try {
      result = await future;
    } on Object catch (e) {
      result = core.CommandResult.failure('$e');
    }
    if (_disposed) return;
    debugPrint('[SANKETA] command result: ok=${result.ok} error=${result.error}');
    if (result.ok) {
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        lastCommandError = null;
        notifyListeners();
      }
    } else {
      _consecutiveFailures++;
      if (showFirstFailure || _consecutiveFailures >= 2) {
        lastCommandError = _humanCommandError(result.error);
        notifyListeners();
      }
    }
  }

  String _humanCommandError(String? raw) {
    if (raw == null) return 'Commands are not reaching the TV.';
    if (raw == 'not_paired') {
      return 'TV requires pairing. Tap "Pair Now" to enter the code shown on your TV.';
    }
    if (raw.contains('ATVRS sidecar not connected') ||
        raw.contains('re-pair required')) {
      return 'Text features need pairing. Open Settings and pair the TV.';
    }
    if (raw.contains('ATVRS connection lost')) {
      return 'TV connection dropped. Reconnecting — try again in a moment.';
    }
    if (raw.contains('not supported') ||
        raw.contains('not yet supported') ||
        raw.contains('not implemented')) {
      return 'This feature is not available for your TV.';
    }
    if (raw.contains('Connection refused') || raw.contains('SocketException')) {
      return 'Lost connection to the TV. Check that it is still on.';
    }
    if (raw.contains('403') || raw.contains('http 403')) {
      return 'TV rejected the command. IP control may need to be re-enabled in TV settings.';
    }
    if (raw.contains('TV denied remote access')) {
      return 'TV denied access. Allow Sanketa on the TV and reconnect.';
    }
    if (raw.contains('authorization timed out')) {
      return 'TV did not respond. Press "Allow" on the TV screen.';
    }
    return 'Commands are not reaching the TV. Check the connection.';
  }

  void clearCommandError() {
    lastCommandError = null;
    _consecutiveFailures = 0;
    notifyListeners();
  }

  void power(bool on) {
    if (hapticEnabled) HapticFeedback.mediumImpact();
    isPoweredOn = on;
    notifyListeners();
    unawaited(_sendCommand(_adapter.power(on: on)));
  }

  void setSource(String source) {
    if (hapticEnabled) HapticFeedback.selectionClick();
    currentSource = source;
    unawaited(_sendCommand(_adapter.setInput(core.InputRef(id: source))));
    notifyListeners();
  }

  void launch(String appName) {
    if (hapticEnabled) HapticFeedback.lightImpact();
    unawaited(_launchWithFeedback(appName));
  }

  Future<void> _launchWithFeedback(String appName) async {
    launchResult = null;
    notifyListeners();
    core.CommandResult result;
    try {
      result = await _adapter
          .launchApp(core.AppRef(id: appName, name: appName));
    } on Object catch (e) {
      result = core.CommandResult.failure('$e');
    }
    if (_disposed) return;
    if (!result.ok) {
      final humanError = _humanCommandError(result.error);
      launchResult = 'error:$humanError';
      lastCommandError = humanError;
      _consecutiveFailures++;
    } else {
      launchResult = 'ok:$appName opened on TV — switch to Remote to browse';
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        lastCommandError = null;
      }
    }
    notifyListeners();
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (_disposed) return;
      if (launchResult != null) {
        launchResult = null;
        notifyListeners();
      }
    });
  }

  void type(String s) {
    if (hapticEnabled) HapticFeedback.selectionClick();
    tvText += s;
    _record('text: $s');
    _enqueueTextOp(core.TextOp.insert(s));
  }

  void backspace() {
    if (hapticEnabled) HapticFeedback.selectionClick();
    if (tvText.isNotEmpty) tvText = tvText.substring(0, tvText.length - 1);
    notifyListeners();
    _enqueueTextOp(const core.TextOp.delete());
  }

  void clearText() {
    tvText = '';
    notifyListeners();
    _enqueueTextOp(const core.TextOp.clear());
  }

  void submit() {
    tvText = '';
    notifyListeners();
    _enqueueTextOp(const core.TextOp.submit());
  }

  void _enqueueTextOp(core.TextOp op) {
    _textOpChain = _textOpChain.then((_) =>
        _sendCommand(_adapter.sendText(op), showFirstFailure: true));
  }

  void addRecentSearch(String query) {
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 10) recentSearches.removeLast();
    notifyListeners();
  }

  void toggleCaps() {
    capsLock = !capsLock;
    notifyListeners();
  }

  void toggleNumbers() {
    numberMode = !numberMode;
    capsLock = false;
    notifyListeners();
  }

  void setNavIndex(int index) {
    navIndex = index;
    notifyListeners();
  }

  // --- Casting (FR-7.1) -----------------------------------------------------

  Future<void> _probeDlnaCaster(
      core.DiscoveredDevice d, int generation) async {
    dlnaProbeComplete = false;
    final host = d.device.host!;

    // Try Google Cast first (port 8009 TLS handshake).
    final castOk = await adapters.probeGoogleCast(host);
    if (_disposed || generation != _connectionGeneration || _castExplicit) {
      return;
    }
    if (castOk) {
      final caster = adapters.GoogleCastAdapter(host: host);
      final connected = await caster.connect();
      if (_disposed || generation != _connectionGeneration || _castExplicit) {
        if (connected) await caster.disconnect();
        return;
      }
      if (connected) {
        _caster = caster;
        castDeviceName = d.device.displayName;
        _castTargetHost = host;
        castProtocol = 'Google Cast';
        dlnaProbeComplete = true;
        notifyListeners();
        return;
      }
    }

    // DLNA probe.
    final probe = adapters.UpnpProbe();
    final urls = await probe.probeHost(host);
    if (_disposed || generation != _connectionGeneration) return;
    if (_castExplicit) return;
    if (urls != null) {
      _caster = adapters.DlnaAdapter(
        avTransportControlUrl: urls.avTransportControlUrl,
        renderingControlUrl: urls.renderingControlUrl,
      );
      castDeviceName = d.device.displayName;
      _castTargetHost = host;
      castProtocol = 'DLNA';
      dlnaProbeComplete = true;
      notifyListeners();
      return;
    }

    // AirPlay probe.
    final airplay = adapters.AirPlayCaster(host: host);
    final airplayOk = await airplay.isReachable();
    if (_disposed || generation != _connectionGeneration) return;
    if (_castExplicit) return;
    if (airplayOk) {
      _caster = airplay;
      castDeviceName = d.device.displayName;
      _castTargetHost = host;
      castProtocol = 'AirPlay';
      dlnaProbeComplete = true;
      notifyListeners();
      return;
    }

    dlnaProbeComplete = true;
    notifyListeners();
  }

  Future<void> connectCastDevice(core.DiscoveredDevice d) async {
    castDeviceName = _shortDeviceName(d.device.displayName);
    isCastConnecting = true;
    castConnectionError = null;
    castProtocol = '';
    notifyListeners();

    final host = d.device.host;
    if (host == null) {
      isCastConnecting = false;
      castConnectionError =
          'No network address for $castDeviceName. Try scanning again.';
      notifyListeners();
      return;
    }

    try {
      final castOk = await adapters.probeGoogleCast(host);
      if (_disposed) return;

      if (castOk) {
        final caster = adapters.GoogleCastAdapter(host: host);
        final connected = await caster.connect();
        if (_disposed) return;
        if (connected) {
          _caster = caster;
          _castExplicit = true;
          _castTargetHost = host;
          castProtocol = 'Google Cast';
          isCastConnecting = false;
          castConnectionError = null;
          notifyListeners();
          return;
        }
      }

      final probe = adapters.UpnpProbe();
      final urls = await probe.probeHost(host);
      if (_disposed) return;

      if (urls != null) {
        _caster = adapters.DlnaAdapter(
          avTransportControlUrl: urls.avTransportControlUrl,
          renderingControlUrl: urls.renderingControlUrl,
        );
        _castExplicit = true;
        _castTargetHost = host;
        castProtocol = 'DLNA';
        isCastConnecting = false;
        castConnectionError = null;
        notifyListeners();
        return;
      }

      // AirPlay probe — try AirPlay 1 HTTP /server-info.
      final airplay = adapters.AirPlayCaster(host: host);
      final airplayOk = await airplay.isReachable();
      if (_disposed) return;

      if (airplayOk) {
        _caster = airplay;
        _castExplicit = true;
        _castTargetHost = host;
        castProtocol = 'AirPlay';
        isCastConnecting = false;
        castConnectionError = null;
        notifyListeners();
        return;
      }

      isCastConnecting = false;
      castConnectionError =
          'No cast receiver found on $castDeviceName. '
          'Make sure the device is powered on.';
      notifyListeners();
    } on Object {
      if (!_disposed) {
        isCastConnecting = false;
        castConnectionError =
            'Could not reach the device. Check that it is powered on and connected to WiFi.';
        notifyListeners();
      }
    }
  }

  void disconnectCastDevice() {
    final caster = _caster;
    if (caster is adapters.GoogleCastAdapter) {
      unawaited(caster.disconnect().catchError((Object _) {}));
    }
    _caster = null;
    _castExplicit = false;
    _castTargetHost = null;
    castDeviceName = '';
    castConnectionError = null;
    castProtocol = '';
    unawaited(_mediaServer.stop());
    unawaited(_hlsAdProxy?.stop());
    _hlsAdProxy = null;
    castSession = core.CastSession.idle;
    notifyListeners();
  }

  Future<void> castFile(String filePath, String fileName) async {
    final caster = _caster;
    if (caster == null) return;

    castSession = core.CastSession(
      phase: core.CastPhase.loading,
      fileName: fileName,
      mimeType: adapters.MediaServer.inferMime(filePath),
    );
    notifyListeners();

    try {
      final lanIp = await adapters.findLanIp(targetHost: _castTargetHost);
      if (lanIp == null) {
        castSession = castSession.copyWith(
          phase: core.CastPhase.error,
          error: 'Could not find a local network address. Check your WiFi connection.',
        );
        notifyListeners();
        return;
      }

      final url = await _mediaServer.serve(
        filePath: filePath,
        lanIp: lanIp,
        mimeType: castSession.mimeType,
      );

      final result = await caster.castUri(
        url,
        mimeType: castSession.mimeType,
        title: fileName,
      );

      if (_disposed) return;
      if (result.ok) {
        castSession = castSession.copyWith(phase: core.CastPhase.playing);
      } else {
        await _mediaServer.stop();
        castSession = castSession.copyWith(
          phase: core.CastPhase.error,
          error: result.error ?? 'The TV could not play this file. Try a different format.',
        );
      }
    } on Object {
      await _mediaServer.stop();
      castSession = castSession.copyWith(
        phase: core.CastPhase.error,
        error: 'Couldn\'t reach the TV for casting. Make sure your phone and TV are on the same WiFi network.',
      );
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> castUri(String url, {String? title, String? mimeType}) async {
    final caster = _caster;
    if (caster == null) {
      castSession = const core.CastSession(
        phase: core.CastPhase.error,
        error: 'No cast device connected. Connect to a TV first.',
      );
      notifyListeners();
      return;
    }
    castSession = core.CastSession(
      phase: core.CastPhase.loading,
      fileName: title ?? url.split('/').last,
      mimeType: mimeType ?? 'video/mp2t',
    );
    notifyListeners();
    try {
      var castUrl = url;

      // HLS ad filtering disabled — kept for future use.
      // if (_isHlsUrl(url)) { ... }

      final result = await caster.castUri(
        castUrl,
        mimeType: castSession.mimeType,
        title: castSession.fileName,
      );
      if (_disposed) return;
      if (result.ok) {
        castSession = castSession.copyWith(phase: core.CastPhase.playing);
      } else {
        castSession = castSession.copyWith(
          phase: core.CastPhase.error,
          error: 'Could not play the stream on the TV.',
        );
      }
    } on Object {
      if (_disposed) return;
      castSession = castSession.copyWith(
        phase: core.CastPhase.error,
        error: 'Playback error. Check the stream URL and TV connection.',
      );
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> launchApp(String packageName, String label) async {
    launch(label.isNotEmpty ? label : packageName);
  }

  String? get tvHost => _selectedDevice?.device.host;

  Future<core.CommandResult> launchUrl(String url) async {
    if (_selectedDevice == null) {
      return const core.CommandResult.failure('No TV connected');
    }
    try {
      return await _adapter.launchApp(core.AppRef(id: url, name: url));
    } on Object catch (e) {
      return core.CommandResult.failure('$e');
    }
  }

  Future<void> pauseCast() async {
    final caster = _caster;
    if (caster == null || castSession.phase != core.CastPhase.playing) return;
    final r = await caster.castPause();
    if (r.ok) {
      castSession = castSession.copyWith(phase: core.CastPhase.paused);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> resumeCast() async {
    final caster = _caster;
    if (caster == null || castSession.phase != core.CastPhase.paused) return;
    final r = await caster.castResume();
    if (r.ok) {
      castSession = castSession.copyWith(phase: core.CastPhase.playing);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> stopCast() async {
    final caster = _caster;
    if (caster != null && castSession.isActive) {
      await caster.castStop();
    }
    await _mediaServer.stop();
    castSession = core.CastSession.idle;
    if (!_disposed) notifyListeners();
  }

  // --- Screen mirroring controls -------------------------------------------

  /// Low-latency mirror via WebSocket + TV browser (DIAL/ATVRS appLinkLaunch).
  ///
  /// Flow: phone captures screen → WS server broadcasts H.264+AAC frames →
  /// HTTP server serves receiver HTML → TV browser opens receiver URL →
  /// JMuxer decodes in real-time. Latency: ~200-500ms vs 3-6s for HLS.
  Future<void> startWsMirror() async {
    if (!isConnected) {
      mirrorError = 'Connect to a TV first from the Devices tab.';
      notifyListeners();
      return;
    }

    mirrorError = null;
    mirrorMode = '';
    mirrorReceiverUrl = null;
    notifyListeners();

    debugPrint('[WsMirror] Starting capture in WS mode...');

    final wsResult = await _mirrorBridge.startMirror(mode: MirrorMode.ws);
    if (wsResult == null) {
      debugPrint('[WsMirror] Permission denied');
      mirrorError = 'Screen capture permission was denied.';
      notifyListeners();
      return;
    }

    debugPrint('[WsMirror] Native started: wsPort=${wsResult.wsPort}');

    try {
      final host = _selectedDevice?.device.host ?? _castTargetHost;
      final lanIp = await adapters.findLanIp(targetHost: host);
      debugPrint('[WsMirror] LAN IP=$lanIp');
      if (lanIp == null) {
        await _mirrorBridge.stopMirror();
        mirrorError =
            'Could not find a local network address. Check your WiFi connection.';
        notifyListeners();
        return;
      }

      _hlsServer = adapters.LiveStreamServer(segmentDir: wsResult.segmentDir);
      await _hlsServer!.start(lanIp, wsPort: wsResult.wsPort);
      debugPrint('[WsMirror] HTTP server on port ${_hlsServer!.port}');

      final receiverUrl = _hlsServer!.receiverUrl(lanIp);
      mirrorReceiverUrl = receiverUrl;
      debugPrint('[WsMirror] Receiver URL=$receiverUrl');

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (_disposed) return;

      debugPrint('[WsMirror] Launching receiver on TV via appLinkLaunch...');
      final launchResult = await _adapter.launchApp(
        core.AppRef(id: receiverUrl, name: 'Screen Mirror'),
      );
      debugPrint('[WsMirror] Launch result: ok=${launchResult.ok} error=${launchResult.error}');

      if (_disposed) return;

      if (launchResult.ok) {
        isMirroring = true;
        mirrorMode = 'WebSocket';
        castSession = core.CastSession(
          phase: core.CastPhase.playing,
          fileName: 'Screen Mirror',
          mimeType: 'text/html',
        );
        debugPrint('[WsMirror] Low-latency mirror active');
      } else {
        debugPrint('[WsMirror] appLinkLaunch failed, falling back to HLS cast...');
        await _fallbackHlsMirror(wsResult, lanIp);
        return;
      }
    } on Object catch (e, st) {
      debugPrint('[WsMirror] Exception: $e\n$st');
      await _mirrorBridge.stopMirror();
      await _hlsServer?.stop();
      _hlsServer = null;
      mirrorError = 'Screen mirroring couldn\'t start. Check that your phone and TV are on the same network.';
    }
    if (!_disposed) notifyListeners();
  }

  /// HLS cast fallback — cascades through Google Cast → DLNA → AirPlay.
  Future<void> _fallbackHlsMirror(
      MirrorStartResult wsResult, String lanIp) async {
    debugPrint('[Mirror-HLS] Falling back to HLS cast...');
    mirrorMode = 'HLS';

    final m3u8Url = 'http://$lanIp:${_hlsServer!.port}/live/stream.m3u8';
    var ready = false;
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_disposed) return;
      final latestFile = File('${wsResult.segmentDir}/latest.txt');
      if (latestFile.existsSync()) {
        final idx = int.tryParse(latestFile.readAsStringSync().trim());
        if (idx != null && idx >= 2) {
          ready = true;
          break;
        }
      }
    }
    if (!ready) {
      await _mirrorBridge.stopMirror();
      await _hlsServer?.stop();
      _hlsServer = null;
      mirrorError =
          'Screen capture started but no video segments were produced. Try again.';
      if (!_disposed) notifyListeners();
      return;
    }

    // Try existing caster first (Google Cast or already-connected DLNA).
    final caster = _caster;
    if (caster != null) {
      final result = await caster.castUri(
        m3u8Url,
        mimeType: 'application/x-mpegurl',
        title: 'Screen Mirror',
      );
      if (result.ok) {
        _finishHlsMirror(caster is adapters.DlnaAdapter ? 'DLNA' : 'Cast');
        return;
      }
      debugPrint('[Mirror-HLS] Primary caster failed: ${result.error}');
    }

    // Probe DLNA on the TV host.
    final host = _selectedDevice?.device.host ?? _castTargetHost;
    if (host != null) {
      final dlna = await _probeDlnaForMirror(host);
      if (_disposed) return;
      if (dlna != null) {
        final result = await dlna.castUri(
          m3u8Url,
          mimeType: 'application/x-mpegurl',
          title: 'Screen Mirror',
        );
        if (result.ok) {
          _caster ??= dlna;
          _finishHlsMirror('DLNA');
          return;
        }
        debugPrint('[Mirror-HLS] DLNA failed: ${result.error}');
      }

      // Probe AirPlay on the TV host.
      final airplay = adapters.AirPlayCaster(host: host);
      final airplayOk = await airplay.isReachable();
      if (_disposed) return;
      if (airplayOk) {
        final result = await airplay.castUri(
          m3u8Url,
          mimeType: 'application/x-mpegurl',
          title: 'Screen Mirror',
        );
        if (result.ok) {
          _caster ??= airplay;
          _finishHlsMirror('AirPlay');
          return;
        }
        debugPrint('[Mirror-HLS] AirPlay failed: ${result.error}');
      }
    }

    // All paths exhausted.
    await _mirrorBridge.stopMirror();
    await _hlsServer?.stop();
    _hlsServer = null;
    mirrorError =
        'No cast receiver responded. Make sure Google Cast, DLNA, or AirPlay is enabled on the TV.';
    if (!_disposed) notifyListeners();
  }

  void _finishHlsMirror(String protocol) {
    isMirroring = true;
    mirrorMode = protocol;
    castSession = core.CastSession(
      phase: core.CastPhase.playing,
      fileName: 'Screen Mirror',
      mimeType: 'application/x-mpegurl',
    );
    debugPrint('[Mirror-HLS] Mirroring active via $protocol');
    if (!_disposed) notifyListeners();
  }

  Future<adapters.DlnaAdapter?> _probeDlnaForMirror(String host) async {
    try {
      final probe = adapters.UpnpProbe();
      final urls = await probe.probeHost(host);
      if (urls == null) return null;
      return adapters.DlnaAdapter(
        avTransportControlUrl: urls.avTransportControlUrl,
        renderingControlUrl: urls.renderingControlUrl,
      );
    } on Object {
      return null;
    }
  }

  /// Legacy HLS-only mirror (kept as explicit fallback).
  Future<void> startMirror() async {
    final caster = _caster;
    if (caster == null) {
      mirrorError = 'No cast device connected. Connect a TV first.';
      notifyListeners();
      return;
    }

    mirrorError = null;
    mirrorMode = '';
    mirrorReceiverUrl = null;
    notifyListeners();

    debugPrint('[Mirror] Starting capture in WS mode...');

    final wsResult = await _mirrorBridge.startMirror(mode: MirrorMode.ws);
    if (wsResult == null) {
      debugPrint('[Mirror] Permission denied');
      mirrorError = 'Screen capture permission was denied.';
      notifyListeners();
      return;
    }

    debugPrint('[Mirror] Native started: dir=${wsResult.segmentDir} wsPort=${wsResult.wsPort}');

    try {
      final lanIp = await adapters.findLanIp(targetHost: _castTargetHost);
      debugPrint('[Mirror] LAN IP=$lanIp');
      if (lanIp == null) {
        await _mirrorBridge.stopMirror();
        mirrorError =
            'Could not find a local network address. Check your WiFi connection.';
        notifyListeners();
        return;
      }

      _hlsServer = adapters.LiveStreamServer(segmentDir: wsResult.segmentDir);
      final m3u8Url = await _hlsServer!.start(lanIp, wsPort: wsResult.wsPort);
      debugPrint('[Mirror] HLS server on port ${_hlsServer!.port}, m3u8=$m3u8Url');

      if (wsResult.wsPort != null && wsResult.wsPort! > 0) {
        mirrorReceiverUrl = _hlsServer!.receiverUrl(lanIp);
        debugPrint('[Mirror] WS receiver=$mirrorReceiverUrl');
      }

      mirrorMode = 'HLS';
      var ready = false;
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_disposed) return;
        final latestFile = File('${wsResult.segmentDir}/latest.txt');
        if (latestFile.existsSync()) {
          final idx = int.tryParse(
            latestFile.readAsStringSync().trim(),
          );
          if (i % 4 == 0 || (idx != null && idx >= 2)) {
            debugPrint('[Mirror] Segment check [$i] latest=$idx');
          }
          if (idx != null && idx >= 2) {
            ready = true;
            break;
          }
        } else if (i % 4 == 0) {
          debugPrint('[Mirror] Segment check [$i] latest.txt missing');
        }
      }
      if (!ready) {
        debugPrint('[Mirror] Not ready after 10s — aborting');
        await _mirrorBridge.stopMirror();
        await _hlsServer?.stop();
        _hlsServer = null;
        mirrorError =
            'Screen capture started but no video segments were produced. Try again.';
        if (!_disposed) notifyListeners();
        return;
      }

      debugPrint('[Mirror] Casting HLS: $m3u8Url');
      final result = await caster.castUri(
        m3u8Url,
        mimeType: 'application/x-mpegurl',
        title: 'Screen Mirror',
      );
      debugPrint('[Mirror] Cast result: ok=${result.ok} error=${result.error}');

      if (_disposed) return;
      if (result.ok) {
        isMirroring = true;
        castSession = core.CastSession(
          phase: core.CastPhase.playing,
          fileName: 'Screen Mirror',
          mimeType: 'application/x-mpegurl',
        );
        debugPrint('[Mirror] Mirroring active');
      } else {
        await _mirrorBridge.stopMirror();
        await _hlsServer?.stop();
        _hlsServer = null;
        mirrorError = result.error ??
            'The TV could not start screen mirroring. Try again.';
        debugPrint('[Mirror] Cast failed: $mirrorError');
      }
    } on Object catch (e, st) {
      debugPrint('[Mirror] Exception: $e\n$st');
      await _mirrorBridge.stopMirror();
      await _hlsServer?.stop();
      _hlsServer = null;
      mirrorError = 'Screen mirroring couldn\'t start. Check that your phone and TV are on the same network.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> openMiracast() async {
    try {
      const channel = MethodChannel('com.sanketa/screen_mirror');
      final result = await channel.invokeMethod<bool>('openMiracast');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stopMirror() async {
    isMirroring = false;
    mirrorError = null;
    mirrorMode = '';
    mirrorReceiverUrl = null;
    await _mirrorBridge.stopMirror();
    await _hlsServer?.stop();
    _hlsServer = null;
    final caster = _caster;
    if (caster != null && castSession.isActive) {
      await caster.castStop();
    }
    castSession = core.CastSession.idle;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_connectionGeneration;
    sleepTimer.dispose();
    macroService.dispose();
    layoutService.dispose();
    parentalControls.dispose();
    voiceControl.dispose();
    final caster = _caster;
    if (caster is adapters.GoogleCastAdapter) {
      unawaited(caster.disconnect().catchError((Object _) {}));
    }
    unawaited(_mediaServer.stop());
    unawaited(_hlsAdProxy?.stop());
    unawaited(_hlsServer?.stop());
    unawaited(_mirrorBridge.stopMirror());
    _stateSub?.cancel();
    unawaited(_deviceSub?.cancel());
    unawaited(_adapter.disconnect().catchError((Object _) {}));
    unawaited(_engine.registry.dispose());
    super.dispose();
  }

  static String _shortDeviceName(String name) {
    final re = RegExp(r'-[0-9a-f]{20,}$');
    return name.replaceAll(re, '');
  }
}


class RemoteScope extends InheritedNotifier<RemoteController> {
  const RemoteScope({
    super.key,
    required RemoteController controller,
    required super.child,
  }) : super(notifier: controller);

  static RemoteController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemoteScope>()!.notifier!;
}
