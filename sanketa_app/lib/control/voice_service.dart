import 'package:flutter/widgets.dart';

class VoiceService extends ChangeNotifier {
  bool _listening = false;
  String _transcript = '';
  bool _available = false;

  bool get isListening => _listening;
  String get transcript => _transcript;
  bool get isAvailable => _available;

  Future<void> checkAvailability() async {
    // Speech recognition requires a platform plugin (speech_to_text).
    // Stub until the native bridge is wired — mirrors F4/F5 "not connected"
    // pattern. The UI shows an honest empty state.
    _available = false;
    notifyListeners();
  }

  void startListening() {
    if (!_available) return;
    _listening = true;
    _transcript = '';
    notifyListeners();
  }

  void stopListening() {
    _listening = false;
    notifyListeners();
  }

  void updateTranscript(String text) {
    _transcript = text;
    notifyListeners();
  }

  void clear() {
    _transcript = '';
    _listening = false;
    notifyListeners();
  }
}
