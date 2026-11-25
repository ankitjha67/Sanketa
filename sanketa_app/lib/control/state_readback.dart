import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

/// Tracks the latest state deltas from the connected adapter (FR-3.4).
///
/// Not all adapters support state readback — this service silently ignores
/// adapters that emit nothing. The UI should check [hasState] before showing
/// readback data, and [honestyLabel] for the right copy (FR-4.5).
class StateReadbackService extends ChangeNotifier {
  StreamSubscription<core.StateDelta>? _sub;
  bool _disposed = false;

  core.StateDelta? _latest;
  String? _adapterId;
  bool _adapterReportsState = false;

  core.StateDelta? get latest => _latest;
  bool get hasState => _latest != null;

  /// True only if the adapter actively reports state (not write-only).
  bool get adapterReportsState => _adapterReportsState;

  /// FR-4.5: honesty label for the current adapter's state capability.
  String get honestyLabel {
    if (_adapterId == null) return 'No device connected';
    if (!_adapterReportsState) {
      return 'This TV does not report its state — '
          'what you see are your commands, not confirmed changes.';
    }
    return 'Live state from TV';
  }

  /// Begin listening to the adapter's state stream. Call when adapter connects.
  void attach(String adapterId, Stream<core.StateDelta> stateStream,
      {bool reportsState = false}) {
    _sub?.cancel();
    _adapterId = adapterId;
    _adapterReportsState = reportsState;
    _latest = null;
    _sub = stateStream.listen(
      (delta) {
        if (_disposed) return;
        _latest = delta;
        notifyListeners();
      },
      onError: (_) {},
      onDone: () {
        if (_disposed) return;
        _adapterReportsState = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// Stop listening. Call when adapter disconnects.
  void detach() {
    _sub?.cancel();
    _sub = null;
    _latest = null;
    _adapterId = null;
    _adapterReportsState = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
