import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ShareIntentService extends ChangeNotifier {
  static const _channel = MethodChannel('com.sanketa/share_intent');

  String? _pendingUrl;
  String? get pendingUrl => _pendingUrl;

  ShareIntentService() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> checkInitial() async {
    try {
      _pendingUrl =
          await _channel.invokeMethod<String>('getInitialSharedUrl');
      if (_pendingUrl != null) notifyListeners();
    } on MissingPluginException {
      // Not on Android — no-op.
    }
  }

  void consume() {
    _pendingUrl = null;
    notifyListeners();
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'onSharedUrl') {
      _pendingUrl = call.arguments as String?;
      notifyListeners();
    }
  }
}
