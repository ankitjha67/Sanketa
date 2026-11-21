import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanketa_adapters/sanketa_adapters.dart' as adapters;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class AppLauncherScreen extends StatefulWidget {
  const AppLauncherScreen({super.key});

  @override
  State<AppLauncherScreen> createState() => _AppLauncherScreenState();
}

class _AppLauncherScreenState extends State<AppLauncherScreen> {
  adapters.AdbClient? _adb;
  List<adapters.TvApp> _apps = [];
  bool _loading = true;
  bool _showSystem = false;
  String _search = '';
  String? _error;
  final _searchController = TextEditingController();

  // Pinned/favorite apps stored by package name
  final Set<String> _pinned = {};

  bool _started = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _loadApps();
    }
  }

  Future<void> _loadApps() async {
    final c = RemoteScope.of(context);
    final host = c.tvHost ?? c.selectedDevice?.device.host;
    if (host == null || host.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No TV connected. Go back and connect first.';
      });
      return;
    }

    try {
      _adb = adapters.AdbClient(host: host, port: 5555);
      final ok = await _adb!.connect();
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'Could not connect via ADB. Enable ADB over WiFi.';
        });
        return;
      }
      final apps = await _adb!.getInstalledApps();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load apps. $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _adb?.disconnect();
    _searchController.dispose();
    super.dispose();
  }

  List<adapters.TvApp> get _filteredApps {
    var apps = _showSystem ? _apps : _apps.where((a) => !a.isSystem).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      apps = apps
          .where((a) =>
              a.label.toLowerCase().contains(q) ||
              a.packageName.toLowerCase().contains(q))
          .toList();
    }
    // Pinned first
    apps.sort((a, b) {
      final aPinned = _pinned.contains(a.packageName);
      final bPinned = _pinned.contains(b.packageName);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return a.label.compareTo(b.label);
    });
    return apps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Apps',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              _showSystem ? Icons.apps : Icons.apps_outage,
              color: hex(AppColors.onSurfaceVariant),
            ),
            tooltip: _showSystem ? 'Hide system apps' : 'Show system apps',
            onPressed: () => setState(() => _showSystem = !_showSystem),
          ),
          if (!_loading)
            IconButton(
              icon:
                  Icon(Icons.refresh, color: hex(AppColors.onSurfaceVariant)),
              onPressed: () {
                setState(() => _loading = true);
                _loadApps();
              },
            ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: hex(AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        Text('Loading apps from TV...',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
      ]));
    }

    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text(_error!,
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), size: 13)),
        ]),
      ));
    }

    final apps = _filteredApps;

    return Column(children: [
      _searchAndStats(),
      Expanded(
        child: apps.isEmpty
            ? Center(
                child: Text('No apps match your search.',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant))))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: apps.length,
                itemBuilder: (ctx, i) => _appTile(apps[i]),
              ),
      ),
    ]);
  }

  Widget _searchAndStats() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Column(children: [
          TextField(
            controller: _searchController,
            onChanged: (q) => setState(() => _search = q),
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurface), size: 14),
            decoration: InputDecoration(
              hintText: 'Search apps...',
              hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: hex(AppColors.surfaceContainerHigh),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.base),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  Icon(Icons.search, size: 18, color: hex(AppColors.outline)),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text(
              '${_filteredApps.length} apps'
              '${_showSystem ? '' : ' (user)'}',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 10),
            ),
            const Spacer(),
            Text(
              '${_pinned.length} pinned',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 10),
            ),
          ]),
        ]),
      );

  Widget _appTile(adapters.TvApp app) {
    final isPinned = _pinned.contains(app.packageName);
    return GestureDetector(
      onTap: () => _launchApp(app),
      onLongPress: () => setState(() {
        if (isPinned) {
          _pinned.remove(app.packageName);
        } else {
          _pinned.add(app.packageName);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(
            fill: isPinned
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLowest,
            radius: AppRadii.md,
            borderOpacity: isPinned ? 0.4 : 0.15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child: Text(
                  _appInitials(app.label),
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurfaceVariant),
                      size: 16,
                      weight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              app.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  size: 11,
                  weight: FontWeight.w500),
            ),
            if (app.isSystem) ...[
              const SizedBox(height: 2),
              Text('SYSTEM',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.outline), size: 8)),
            ],
            if (isPinned) ...[
              const SizedBox(height: 2),
              Icon(Icons.push_pin,
                  size: 10, color: hex(AppColors.primary)),
            ],
          ],
        ),
      ),
    );
  }

  String _appInitials(String label) {
    final words = label.split(RegExp(r'[\s._-]+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) {
      return '${words.first[0]}${words.elementAt(1)[0]}'.toUpperCase();
    }
    return label.isNotEmpty ? label[0].toUpperCase() : '?';
  }

  Future<void> _launchApp(adapters.TvApp app) async {
    final c = RemoteScope.of(context);
    // Try via existing launchApp on the adapter first
    try {
      await c.launchApp(app.packageName, app.label);
    } on Object {
      // Fall back to ADB launch
      try {
        await _adb?.launchApp(app.packageName);
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not launch ${app.label}'),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
          ));
        }
      }
    }
  }
}
