import 'package:flutter/material.dart';

import 'control/remote_controller.dart';
import 'native/method_channel_ir_bridge.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() => runApp(const SanketaApp());

class SanketaApp extends StatefulWidget {
  const SanketaApp({super.key});

  @override
  State<SanketaApp> createState() => _SanketaAppState();
}

class _SanketaAppState extends State<SanketaApp> {
  final RemoteController _controller = RemoteController(
    irBridge: const MethodChannelIrBridge(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RemoteScope(
    controller: _controller,
    child: MaterialApp(
      title: 'Sanketa',
      debugShowCheckedModeBanner: false,
      theme: sanketaDarkTheme(),
      home: const AppShell(),
    ),
  );
}
