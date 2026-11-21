import 'dart:async';
import 'dart:typed_data';

import 'package:sanketa_adapters/src/android_tv/atv_channel.dart';
import 'package:sanketa_core/sanketa_core.dart';

class FakeAtvChannel implements AtvChannel {
  FakeAtvChannel({this.autoAck = false, this.fakeFeatures = 0});

  final bool autoAck;
  final int fakeFeatures;
  bool _open = false;
  final List<Uint8List> sentRaw = [];
  final List<Key> sentKeys = [];
  final List<String> sentTexts = [];
  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();

  @override
  bool get isOpen => _open;

  @override
  bool get gotError => false;

  @override
  int get negotiatedFeatures => fakeFeatures;

  @override
  Future<void> connect() async => _open = true;

  @override
  Future<void> close() async {
    _open = false;
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }

  @override
  void sendMessage(List<int> body) {
    sentRaw.add(Uint8List.fromList(body));
    if (autoAck) _incoming.add(Uint8List.fromList(const [0x00]));
  }

  @override
  Stream<Uint8List> get messages => _incoming.stream;

  void push(Uint8List data) => _incoming.add(data);
}
