import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class TofuCertStore {
  TofuCertStore({required this.persistPath});

  final String persistPath;
  final Map<String, String> _pins = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final file = File(persistPath);
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) {
        for (final e in json.entries) {
          if (e.value is String) _pins[e.key] = e.value as String;
        }
      }
    } on Object {
      // Corrupt file — start fresh.
    }
  }

  Future<void> _save() async {
    final file = File(persistPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(_pins));
  }

  bool isKnown(String host) => _pins.containsKey(host);

  bool verify(X509Certificate cert, String host) {
    final hash = sha256.convert(cert.der).toString();
    final saved = _pins[host];
    if (saved == null) {
      _pins[host] = hash;
      _save();
      return true;
    }
    return saved == hash;
  }

  Future<void> resetHost(String host) async {
    _pins.remove(host);
    await _save();
  }

  String? pinFor(String host) => _pins[host];
}
