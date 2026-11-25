import 'dart:async';

import 'package:flutter/widgets.dart';

class SleepTimerService extends ChangeNotifier {
  Duration? _remaining;
  Duration _total = Duration.zero;
  Timer? _tick;
  VoidCallback? onExpired;

  bool get isActive => _remaining != null;
  Duration? get remaining => _remaining;

  double get progress {
    if (_remaining == null || _total.inSeconds == 0) return 0;
    final elapsed = _total.inSeconds - _remaining!.inSeconds;
    return (elapsed / _total.inSeconds).clamp(0.0, 1.0);
  }

  String get label {
    final r = _remaining;
    if (r == null) return '';
    final h = r.inHours;
    final m = r.inMinutes.remainder(60);
    final s = r.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '0:${s.toString().padLeft(2, '0')}';
  }

  void start(Duration duration) {
    _tick?.cancel();
    _total = duration;
    _remaining = duration;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void cancel() {
    _tick?.cancel();
    _tick = null;
    _remaining = null;
    _total = Duration.zero;
    notifyListeners();
  }

  void addTime(Duration extra) {
    if (_remaining == null) return;
    _remaining = _remaining! + extra;
    _total += extra;
    notifyListeners();
  }

  void _onTick() {
    if (_remaining == null) return;
    final next = _remaining! - const Duration(seconds: 1);
    if (next.inSeconds <= 0) {
      _tick?.cancel();
      _tick = null;
      _remaining = null;
      _total = Duration.zero;
      notifyListeners();
      onExpired?.call();
    } else {
      _remaining = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
