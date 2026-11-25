import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

class VoiceCommand {
  const VoiceCommand(this.label, this.keys, {this.isText = false});
  final String label;
  final List<core.Key> keys;
  final bool isText;
}

class VoiceControlService extends ChangeNotifier {
  static const _channel = MethodChannel('com.sanketa.voice');

  bool _listening = false;
  String _transcript = '';
  String? _error;
  VoiceCommand? _lastCommand;

  bool get isListening => _listening;
  String get transcript => _transcript;
  String? get error => _error;
  VoiceCommand? get lastCommand => _lastCommand;
  bool get isAvailable => _available;
  bool _available = false;

  Future<void> checkAvailability() async {
    try {
      _available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _available = false;
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;
    _transcript = '';
    _error = null;
    notifyListeners();

    try {
      _channel.setMethodCallHandler(_onPlatformCallback);
      await _channel.invokeMethod<void>('start');
    } on PlatformException catch (e) {
      _error = e.message ?? 'Speech recognition not available on this device';
      _listening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // ignore
    }
    _listening = false;
    notifyListeners();
  }

  Future<dynamic> _onPlatformCallback(MethodCall call) async {
    switch (call.method) {
      case 'onResult':
        _transcript = call.arguments as String? ?? '';
        notifyListeners();
      case 'onDone':
        _listening = false;
        _lastCommand = matchCommand(_transcript);
        notifyListeners();
      case 'onError':
        _error = call.arguments as String?;
        _listening = false;
        notifyListeners();
    }
  }

  static final _commandMap = <String, VoiceCommand>{
    'power off': const VoiceCommand('Power Off', [core.Key.power]),
    'turn off': const VoiceCommand('Power Off', [core.Key.power]),
    'power on': const VoiceCommand('Power On', [core.Key.power]),
    'turn on': const VoiceCommand('Power On', [core.Key.power]),
    'volume up': const VoiceCommand('Volume Up', [core.Key.volumeUp]),
    'louder': const VoiceCommand('Volume Up', [core.Key.volumeUp]),
    'volume down': const VoiceCommand('Volume Down', [core.Key.volumeDown]),
    'quieter': const VoiceCommand('Volume Down', [core.Key.volumeDown]),
    'mute': const VoiceCommand('Mute', [core.Key.mute]),
    'unmute': const VoiceCommand('Unmute', [core.Key.mute]),
    'home': const VoiceCommand('Home', [core.Key.home]),
    'go home': const VoiceCommand('Home', [core.Key.home]),
    'back': const VoiceCommand('Back', [core.Key.back]),
    'go back': const VoiceCommand('Back', [core.Key.back]),
    'menu': const VoiceCommand('Menu', [core.Key.menu]),
    'select': const VoiceCommand('OK', [core.Key.ok]),
    'okay': const VoiceCommand('OK', [core.Key.ok]),
    'enter': const VoiceCommand('OK', [core.Key.ok]),
    'up': const VoiceCommand('Up', [core.Key.up]),
    'down': const VoiceCommand('Down', [core.Key.down]),
    'left': const VoiceCommand('Left', [core.Key.left]),
    'right': const VoiceCommand('Right', [core.Key.right]),
    'play': const VoiceCommand('Play', [core.Key.play]),
    'pause': const VoiceCommand('Pause', [core.Key.pause]),
    'stop': const VoiceCommand('Stop', [core.Key.stop]),
    'rewind': const VoiceCommand('Rewind', [core.Key.rewind]),
    'fast forward': const VoiceCommand('Fast Forward', [core.Key.fastForward]),
    'channel up': const VoiceCommand('Channel Up', [core.Key.channelUp]),
    'next channel': const VoiceCommand('Channel Up', [core.Key.channelUp]),
    'channel down': const VoiceCommand('Channel Down', [core.Key.channelDown]),
    'previous channel':
        const VoiceCommand('Channel Down', [core.Key.channelDown]),
    'guide': const VoiceCommand('Guide', [core.Key.guide]),
    'info': const VoiceCommand('Info', [core.Key.info]),
    'subtitle': const VoiceCommand('Subtitle', [core.Key.subtitle]),
    'subtitles': const VoiceCommand('Subtitle', [core.Key.subtitle]),
  };

  VoiceCommand? matchCommand(String transcript) {
    if (transcript.isEmpty) return null;
    final lower = transcript.toLowerCase().trim();

    final exact = _commandMap[lower];
    if (exact != null) return exact;

    for (final entry in _commandMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    return VoiceCommand(transcript, [], isText: true);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
