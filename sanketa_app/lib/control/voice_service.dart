import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  String _transcript = '';
  bool _available = false;

  bool get isListening => _listening;
  String get transcript => _transcript;
  bool get isAvailable => _available;

  Future<void> checkAvailability() async {
    _available = await _speech.initialize(
      onError: (_) {
        _listening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  void startListening() {
    if (!_available) return;
    _listening = true;
    _transcript = '';
    notifyListeners();
    _speech.listen(
      onResult: (result) {
        _transcript = result.recognizedWords;
        notifyListeners();
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void stopListening() {
    _speech.stop();
    _listening = false;
    notifyListeners();
  }

  void clear() {
    _transcript = '';
    _listening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
