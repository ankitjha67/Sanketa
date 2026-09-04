import 'package:flutter/widgets.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

import 'demo_adapter.dart';

/// Holds the active [core.ControlAdapter] and the small bit of UI state the
/// Remote screen needs (current source, the live TV text buffer, an action log).
/// Every button routes through here into the contract — brand-blind.
class RemoteController extends ChangeNotifier {
  RemoteController() {
    _adapter = DemoAdapter(_record);
  }

  late final core.ControlAdapter _adapter;
  core.ControlAdapter get adapter => _adapter;
  core.CapabilityMap get caps => _adapter.capabilities();

  final List<String> actionLog = <String>[];
  String currentSource = 'HDMI 1';
  String tvText = 'Stranger Thi';

  void _record(String action) {
    actionLog.insert(0, action);
    if (actionLog.length > 12) actionLog.removeLast();
    notifyListeners();
  }

  void key(core.Key k, {core.PressType press = core.PressType.tap}) =>
      _adapter.sendKey(k, press: press);

  void power(bool on) => _adapter.power(on: on);

  void setSource(String source) {
    currentSource = source;
    _adapter.setInput(core.InputRef(id: source));
    notifyListeners();
  }

  void launch(String appName) =>
      _adapter.launchApp(core.AppRef(id: appName, name: appName));

  // --- The hero: live text sync ---
  void type(String s) {
    tvText += s;
    _adapter.sendText(core.TextOp.insert(s));
    notifyListeners();
  }

  void backspace() {
    if (tvText.isNotEmpty) tvText = tvText.substring(0, tvText.length - 1);
    _adapter.sendText(const core.TextOp.delete());
    notifyListeners();
  }

  void clearText() {
    tvText = '';
    _adapter.sendText(const core.TextOp.clear());
    notifyListeners();
  }

  void submit() => _adapter.sendText(const core.TextOp.submit());
}

/// Exposes the [RemoteController] to the widget tree.
class RemoteScope extends InheritedNotifier<RemoteController> {
  const RemoteScope({
    super.key,
    required RemoteController controller,
    required super.child,
  }) : super(notifier: controller);

  static RemoteController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RemoteScope>()!
      .notifier!;
}
