import 'dart:async';

import 'package:sanketa_adapters/src/common/ws_channel.dart';

/// A scriptable fake WebSocket channel for adapter tests.
///
/// - [emitAfterConnect]: frames pushed to `messages` right after `connect()`
///   (models Tizen's `ms.channel.connect` token event).
/// - [autoReplies]: when a sent frame contains a key substring, the mapped
///   frame is pushed back (models webOS's `registered` response).
class FakeWsChannel implements WsChannel {
  FakeWsChannel({
    this.emitAfterConnect = const [],
    this.autoReplies = const {},
  });

  final List<String> emitAfterConnect;
  final Map<String, String> autoReplies;

  bool _open = false;
  final List<String> sent = [];
  final StreamController<String> _ctrl = StreamController<String>();

  @override
  bool get isOpen => _open;

  @override
  Future<void> connect() async {
    _open = true;
    for (final m in emitAfterConnect) {
      _ctrl.add(m);
    }
  }

  @override
  Future<void> close() async {
    _open = false;
    // Never await: a single-subscription controller with no listener never
    // completes close().
    if (!_ctrl.isClosed) unawaited(_ctrl.close());
  }

  @override
  void send(String message) {
    sent.add(message);
    autoReplies.forEach((needle, reply) {
      if (message.contains(needle)) _ctrl.add(reply);
    });
  }

  @override
  Stream<String> get messages => _ctrl.stream;

  void push(String message) => _ctrl.add(message);
}
