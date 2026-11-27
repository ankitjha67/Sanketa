import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class NetworkBlockScreen extends StatefulWidget {
  const NetworkBlockScreen({super.key});

  @override
  State<NetworkBlockScreen> createState() => _NetworkBlockScreenState();
}

class _NetworkBlockScreenState extends State<NetworkBlockScreen> {
  bool _loading = true;
  bool _firewallEnabled = true;
  bool _whitelistMode = false;

  List<_BlockedApp> _apps = [];

  static final _defaults = <_BlockedApp>[
    _BlockedApp(name: 'YouTube', icon: Icons.play_circle, blocked: false),
    _BlockedApp(name: 'Netflix', icon: Icons.movie, blocked: false),
    _BlockedApp(name: 'Disney+', icon: Icons.castle, blocked: false),
    _BlockedApp(name: 'Prime Video', icon: Icons.video_library, blocked: false),
    _BlockedApp(name: 'Hulu', icon: Icons.live_tv, blocked: false),
    _BlockedApp(name: 'TikTok', icon: Icons.music_note, blocked: true),
    _BlockedApp(name: 'Facebook', icon: Icons.people, blocked: true),
    _BlockedApp(name: 'Instagram', icon: Icons.camera_alt, blocked: true),
    _BlockedApp(name: 'Twitter', icon: Icons.chat_bubble, blocked: false),
    _BlockedApp(name: 'Spotify', icon: Icons.headphones, blocked: false),
  ];

  int get _blockedCount => _apps.where((a) => a.blocked).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/network_block.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _firewallEnabled = j['firewallEnabled'] as bool? ?? true;
        _whitelistMode = j['whitelistMode'] as bool? ?? false;
        final list = j['apps'] as List? ?? [];
        _apps = list
            .map((e) => _BlockedApp.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _apps = _defaults
            .map((a) => _BlockedApp(
                name: a.name, icon: a.icon, blocked: a.blocked))
            .toList();
      }
    } catch (_) {
      _apps = _defaults
          .map((a) =>
              _BlockedApp(name: a.name, icon: a.icon, blocked: a.blocked))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'firewallEnabled': _firewallEnabled,
      'whitelistMode': _whitelistMode,
      'apps': _apps.map((a) => a.toJson()).toList(),
    }));
  }

  void _toggleApp(int idx) {
    setState(() => _apps[idx].blocked = !_apps[idx].blocked);
    HapticFeedback.selectionClick();
    _save();
  }

  void _toggleFirewall() {
    setState(() => _firewallEnabled = !_firewallEnabled);
    HapticFeedback.mediumImpact();
    _save();
  }

  void _toggleWhitelist() {
    setState(() => _whitelistMode = !_whitelistMode);
    HapticFeedback.selectionClick();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Network Block',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.lg),
                _firewallToggle(),
                const SizedBox(height: AppSpacing.md),
                _whitelistToggle(),
                const SizedBox(height: AppSpacing.lg),
                _statsRow(),
                const SizedBox(height: AppSpacing.md),
                ..._apps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _appCard(e.key, e.value),
                    )),
                const SizedBox(height: AppSpacing.lg),
                _infoCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.shield, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('App Firewall',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Block specific apps from accessing the internet on your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _firewallToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department,
                size: 20,
                color: hex(_firewallEnabled
                    ? AppColors.error
                    : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Master Firewall',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(
                      _firewallEnabled
                          ? 'Blocking active'
                          : 'All apps allowed',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleFirewall,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_firewallEnabled
                          ? AppColors.error
                          : AppColors.outlineVariant)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _firewallEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hex(_firewallEnabled
                          ? AppColors.error
                          : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _whitelistToggle() => GestureDetector(
        onTap: _toggleWhitelist,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.checklist,
                  size: 20,
                  color: hex(_whitelistMode
                      ? AppColors.signalEmerald
                      : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Whitelist Mode',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text(
                        _whitelistMode
                            ? 'Only allow selected apps'
                            : 'Block selected apps',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_whitelistMode
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_whitelistMode ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_whitelistMode
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(child: _statBadge('Blocked', '$_blockedCount', AppColors.error)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Allowed', '${_apps.length - _blockedCount}', AppColors.signalEmerald)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge('Total', '${_apps.length}', AppColors.primary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(c).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 20, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _appCard(int idx, _BlockedApp app) => GestureDetector(
        onTap: () => _toggleApp(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(app.blocked
                    ? AppColors.error
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: app.blocked ? 0.06 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(app.blocked
                      ? AppColors.error
                      : AppColors.outlineVariant)
                  .withValues(alpha: app.blocked ? 0.25 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(app.icon,
                  size: 22,
                  color: hex(app.blocked
                      ? AppColors.error
                      : AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(app.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 13)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(app.blocked
                          ? AppColors.error
                          : AppColors.signalEmerald)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(app.blocked ? 'BLOCKED' : 'ALLOWED',
                    style: gfont(AppType.bodySm,
                        color: hex(app.blocked
                            ? AppColors.error
                            : AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Block apps from internet access on your TV. '
                'Enable Whitelist Mode to allow only selected apps. '
                'All rules are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _BlockedApp {
  String name;
  IconData icon;
  bool blocked;

  _BlockedApp({
    required this.name,
    required this.icon,
    required this.blocked,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'blocked': blocked,
      };

  factory _BlockedApp.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String? ?? '';
    final match = _NetworkBlockScreenState._defaults
        .where((d) => d.name == name);
    return _BlockedApp(
      name: name,
      icon: match.isNotEmpty ? match.first.icon : Icons.apps,
      blocked: j['blocked'] as bool? ?? false,
    );
  }
}
