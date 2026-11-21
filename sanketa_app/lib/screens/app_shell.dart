import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'cast_screen.dart';
import 'devices_screen.dart';
import 'remote_screen.dart';
import 'search_screen.dart';
import 'tools_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Press back again to exit',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            duration: const Duration(seconds: 2),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ));
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: c.navIndex,
            children: const [
              RemoteScreen(),
              SearchScreen(),
              CastScreen(),
              ToolsScreen(),
              DevicesScreen(),
            ],
          ),
        ),
        bottomNavigationBar:
            _BottomNavBar(navIndex: c.navIndex, onTap: c.setNavIndex),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.navIndex, required this.onTap});

  final int navIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        border: Border(top: BorderSide(color: hex(AppColors.outlineVariant))),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  _tab(0, Icons.settings_remote, 'Remote'),
                  _tab(1, Icons.search, 'Search'),
                  _tab(2, Icons.cast, 'Cast'),
                  _tab(3, Icons.build_rounded, 'Tools'),
                  _tab(4, Icons.devices, 'Devices'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final active = navIndex == index;
    final color =
        active ? hex(AppColors.primaryContainer) : hex(AppColors.onSurfaceVariant);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          height: AppSpacing.touchTargetMin,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(label, style: gfont(AppType.labelMonoSm, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
