import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('com.sanketa/screen_mirror');

enum MirrorMode { hls, ws }

class MirrorStartResult {
  const MirrorStartResult({required this.segmentDir, this.wsPort});
  final String segmentDir;
  final int? wsPort;
}

class ScreenMirrorBridge {
  int? _resultCode;
  String? _dataUri;
  String? _segmentDir;
  bool _active = false;

  bool get isActive => _active;
  String? get segmentDir => _segmentDir;

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'requestPermission',
      );
      if (result == null) return false;
      _resultCode = result['resultCode'] as int?;
      _dataUri = result['dataUri'] as String?;
      return _resultCode != null;
    } on PlatformException {
      return false;
    }
  }

  Future<MirrorStartResult?> startMirror({
    int width = 720,
    int height = 1280,
    int dpi = 1,
    MirrorMode mode = MirrorMode.ws,
  }) async {
    if (_resultCode == null) {
      final ok = await requestPermission();
      if (!ok) return null;
    }

    _segmentDir ??=
        '${Directory.systemTemp.path}/sanketa_screen_mirror';

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startMirror',
        {
          'width': width,
          'height': height,
          'dpi': dpi,
          'segmentDir': _segmentDir,
          'resultCode': _resultCode,
          'dataUri': _dataUri,
          'mode': mode == MirrorMode.ws ? 'ws' : 'hls',
        },
      );
      if (result == null) return null;
      _active = true;
      final dir = result['segmentDir'] as String? ?? _segmentDir!;
      _segmentDir = dir;
      final wsPort = result['wsPort'] as int?;
      return MirrorStartResult(segmentDir: dir, wsPort: wsPort);
    } on PlatformException {
      return null;
    }
  }

  Future<void> stopMirror() async {
    _active = false;
    _resultCode = null;
    _dataUri = null;
    try {
      await _channel.invokeMethod<void>('stopMirror');
    } on PlatformException {
      // Best-effort.
    }
  }
}
