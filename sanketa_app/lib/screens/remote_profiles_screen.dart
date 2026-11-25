import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class RemoteProfile {
  RemoteProfile({
    required this.id,
    required this.name,
    required this.icon,
    this.settings = const {},
  });

  final String id;
  String name;
  String icon;
  Map<String, dynamic> settings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'settings': settings,
  };

  factory RemoteProfile.fromJson(Map<String, dynamic> j) => RemoteProfile(
    id: j['id'] as String,
    name: j['name'] as String,
    icon: j['icon'] as String,
    settings: (j['settings'] as Map<String, dynamic>?) ?? {},
  );
}

class RemoteProfilesScreen extends StatefulWidget {
  const RemoteProfilesScreen({super.key});

  @override
  State<RemoteProfilesScreen> createState() => _RemoteProfilesScreenState();
}

class _RemoteProfilesScreenState extends State<RemoteProfilesScreen> {
  List<RemoteProfile> _profiles = [];
  String? _activeId;
  bool _loading = true;

  static const _iconOptions = <String, IconData>{
    'person': Icons.person,
    'child': Icons.child_care,
    'elderly': Icons.elderly,
    'gaming': Icons.sports_esports,
    'work': Icons.work,
    'movie': Icons.movie,
    'music': Icons.music_note,
    'night': Icons.bedtime,
  };

  static const _settingsDefs = <String, (String, String, IconData)>{
    'simpleMode': ('Simple Mode', '6-button remote for easy access', Icons.grid_view),
    'hapticFeedback': ('Haptic Feedback', 'Vibrate on button press', Icons.vibration),
    'largeTapTargets': ('Large Buttons', '64dp touch targets for accessibility', Icons.zoom_in),
    'volumeButtons': ('Hardware Volume', 'Phone volume buttons control TV', Icons.phone_android),
    'autoConnect': ('Auto-Connect', 'Reconnect to TV automatically', Icons.wifi),
    'confirmPower': ('Confirm Power', 'Ask before power off', Icons.warning_amber),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_profiles.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['profiles'] as List;
        _profiles = list.map((e) => RemoteProfile.fromJson(e as Map<String, dynamic>)).toList();
        _activeId = data['activeId'] as String?;
      } else {
        _profiles = [
          RemoteProfile(
            id: 'default',
            name: 'Default',
            icon: 'person',
            settings: {
              'simpleMode': false,
              'hapticFeedback': true,
              'largeTapTargets': false,
              'volumeButtons': true,
              'autoConnect': true,
              'confirmPower': false,
            },
          ),
          RemoteProfile(
            id: 'kids',
            name: 'Kids',
            icon: 'child',
            settings: {
              'simpleMode': true,
              'hapticFeedback': true,
              'largeTapTargets': true,
              'volumeButtons': false,
              'autoConnect': true,
              'confirmPower': true,
            },
          ),
        ];
        _activeId = 'default';
      }
    } on Object {
      _profiles = [
        RemoteProfile(
          id: 'default',
          name: 'Default',
          icon: 'person',
          settings: {'hapticFeedback': true, 'autoConnect': true, 'volumeButtons': true},
        ),
      ];
      _activeId = 'default';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'profiles': _profiles.map((p) => p.toJson()).toList(),
      'activeId': _activeId,
    }));
  }

  void _activateProfile(RemoteProfile p) {
    setState(() => _activeId = p.id);
    _save();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Switched to "${p.name}" profile'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _addProfile() {
    final nameCtrl = TextEditingController();
    String selectedIcon = 'person';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLowest),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          title: Text('New Profile',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Profile name',
                  hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                  isDense: true,
                  filled: true,
                  fillColor: hex(AppColors.surfaceContainerHigh),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.entries.map((e) {
                  final active = selectedIcon == e.key;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = e.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.3 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: hex(active ? AppColors.primaryContainer : AppColors.outlineVariant)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(e.value, size: 18,
                          color: hex(active ? AppColors.primary : AppColors.outline)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  setState(() => _profiles.add(RemoteProfile(
                    id: id,
                    name: name,
                    icon: selectedIcon,
                    settings: {
                      'simpleMode': false,
                      'hapticFeedback': true,
                      'largeTapTargets': false,
                      'volumeButtons': true,
                      'autoConnect': true,
                      'confirmPower': false,
                    },
                  )));
                  _save();
                  Navigator.pop(ctx);
                }
              },
              child: Text('Create',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primaryContainer), weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _editSettings(int index) {
    final profile = _profiles[index];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      builder: (ctx) => _ProfileSettingsSheet(
        profile: profile,
        onChanged: (settings) {
          setState(() => _profiles[index].settings = settings);
          _save();
        },
      ),
    );
  }

  void _removeProfile(int index) {
    if (_profiles[index].id == _activeId && _profiles.length > 1) {
      final other = _profiles.where((p) => p.id != _profiles[index].id).first;
      _activeId = other.id;
    }
    setState(() => _profiles.removeAt(index));
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
        title: Text('Remote Profiles',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addProfile,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : _profiles.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _profiles.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _profiles.length) return _infoCard();
                    return _profileTile(_profiles[i], i);
                  },
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No profiles',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Create profiles for different users or scenarios — a simple remote for kids, a gaming layout for you.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _addProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Add Profile',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _profileTile(RemoteProfile profile, int index) {
    final isActive = _activeId == profile.id;
    final iconData = _iconOptions[profile.icon] ?? Icons.person;
    final enabledCount = profile.settings.values.where((v) => v == true).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _activateProfile(profile),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: panel(
            fill: isActive ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: isActive ? 0.4 : 0.15,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hex(isActive ? AppColors.primaryContainer : AppColors.outlineVariant)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: isActive
                      ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4), width: 1.5)
                      : null,
                ),
                child: Icon(iconData, size: 22,
                    color: hex(isActive ? AppColors.primary : AppColors.outline)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(profile.name,
                            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text('ACTIVE',
                                style: gfont(AppType.labelMonoSm,
                                    color: hex(AppColors.signalEmerald), size: 8)),
                          ),
                        ],
                      ],
                    ),
                    Text('$enabledCount settings enabled',
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editSettings(index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.settings, size: 16, color: hex(AppColors.outlineVariant)),
                ),
              ),
              if (_profiles.length > 1)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _removeProfile(index),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 16, color: hex(AppColors.outlineVariant)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.tertiary).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profiles let different people use the remote their way. Kids get Simple Mode, gamers get quick access, everyone gets their own preferences.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileSettingsSheet extends StatefulWidget {
  const _ProfileSettingsSheet({required this.profile, required this.onChanged});

  final RemoteProfile profile;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<_ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<_ProfileSettingsSheet> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.profile.settings);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.profile.name} Settings',
              style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.lg),
          ..._RemoteProfilesScreenState._settingsDefs.entries.map((e) {
            final value = _settings[e.key] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _settings[e.key] = !value);
                  widget.onChanged(_settings);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLowest),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(e.value.$3, size: 18,
                          color: hex(value ? AppColors.primary : AppColors.outline)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.$1,
                                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                            Text(e.value.$2,
                                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 20,
                        decoration: BoxDecoration(
                          color: hex(value ? AppColors.primary : AppColors.surfaceContainerHigh),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 150),
                          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: hex(value ? AppColors.onPrimary : AppColors.outline),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}
