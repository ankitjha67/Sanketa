import 'package:flutter/material.dart';

import 'control/remote_controller.dart';
import 'screens/remote_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const SanketaApp());

class SanketaApp extends StatefulWidget {
  const SanketaApp({super.key});

  @override
  State<SanketaApp> createState() => _SanketaAppState();
}

class _SanketaAppState extends State<SanketaApp> {
  final RemoteController _controller = RemoteController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SANKETA',
        debugShowCheckedModeBanner: false,
        theme: sanketaDarkTheme(),
        home: RemoteScope(controller: _controller, child: const RemoteScreen()),
      );
}
