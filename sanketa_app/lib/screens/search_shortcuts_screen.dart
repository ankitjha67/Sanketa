import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';
import '../widgets/search_shortcuts_widget.dart';

class SearchShortcutsScreen extends StatefulWidget {
  const SearchShortcutsScreen({super.key});

  @override
  State<SearchShortcutsScreen> createState() => _SearchShortcutsScreenState();
}

class _SearchShortcutsScreenState extends State<SearchShortcutsScreen> {
  final _widgetKey = GlobalKey<SearchShortcutsWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Search Shortcuts',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: SearchShortcutsWidget(key: _widgetKey),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hex(AppColors.primaryContainer),
        onPressed: () => _widgetKey.currentState?.showAddDialog(),
        child: Icon(Icons.add, color: hex(AppColors.onPrimaryContainer)),
      ),
    );
  }
}
