import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ContentFilterScreen extends StatefulWidget {
  const ContentFilterScreen({super.key});

  @override
  State<ContentFilterScreen> createState() => _ContentFilterScreenState();
}

class _ContentFilterScreenState extends State<ContentFilterScreen> {
  bool _loading = true;
  bool _enabled = true;
  int _ratingLevel = 2;

  static final _categories = <_FilterCategory>[
    _FilterCategory(name: 'Violence', icon: Icons.warning, blocked: true, color: AppColors.error),
    _FilterCategory(name: 'Adult Content', icon: Icons.no_adult_content, blocked: true, color: AppColors.error),
    _FilterCategory(name: 'Horror', icon: Icons.mood_bad, blocked: false, color: AppColors.alertAmber),
    _FilterCategory(name: 'Gambling', icon: Icons.casino, blocked: true, color: AppColors.error),
    _FilterCategory(name: 'Drugs', icon: Icons.local_pharmacy, blocked: true, color: AppColors.alertAmber),
    _FilterCategory(name: 'Strong Language', icon: Icons.speaker_notes_off, blocked: false, color: AppColors.secondary),
  ];

  static const _ratings = ['All', 'TV-G', 'TV-PG', 'TV-14', 'TV-MA'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/content_filter.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = data['enabled'] as bool? ?? true;
        _ratingLevel = data['ratingLevel'] as int? ?? 2;
        final blocked = data['blocked'] as List<dynamic>? ?? [];
        for (var i = 0; i < blocked.length && i < _categories.length; i++) {
          _categories[i].blocked = blocked[i] as bool? ?? false;
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'ratingLevel': _ratingLevel,
      'blocked': _categories.map((c) => c.blocked).toList(),
    }));
  }

  int get _blockedCount => _categories.where((c) => c.blocked).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Content Filter',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _masterToggle(),
          const SizedBox(height: AppSpacing.md),
          _ratingPicker(),
          const SizedBox(height: AppSpacing.md),
          _categoriesList(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _masterToggle() => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _enabled = !_enabled);
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(_enabled ? AppColors.signalEmerald : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.3 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.shield,
                  size: 32,
                  color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Content Filter',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(_enabled ? 'Active — filtering content' : 'Disabled',
                        style: gfont(AppType.bodySm,
                            color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline),
                            size: 11)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _enabled ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ratingPicker() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max Rating',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _ratings.asMap().entries.map((e) {
                final active = e.key == _ratingLevel;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _ratingLevel = e.key);
                      _save();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: e.key < 4 ? 4 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.12 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(e.value,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 9)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _categoriesList() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._categories.asMap().entries.map((e) {
              final c = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => c.blocked = !c.blocked);
                    _save();
                  },
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18, color: hex(c.color)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.name,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hex(c.blocked ? AppColors.error : AppColors.signalEmerald)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(c.blocked ? 'Blocked' : 'Allowed',
                            style: gfont(AppType.bodySm,
                                color: hex(c.blocked ? AppColors.error : AppColors.signalEmerald),
                                weight: FontWeight.w600,
                                size: 9)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );

  Widget _statsRow() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('$_blockedCount', 'Blocked'),
            _stat('${_categories.length - _blockedCount}', 'Allowed'),
            _stat(_ratings[_ratingLevel], 'Max Rating'),
          ],
        ),
      );

  Widget _stat(String val, String label) => Column(
        children: [
          Text(val,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.primary),
                  weight: FontWeight.w700,
                  size: 14)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
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
                'Filter TV content by category and rating. Block violence, adult content, gambling, and more. Set a maximum rating level for family-friendly viewing. All filter settings stay on your device.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _FilterCategory {
  String name;
  IconData icon;
  bool blocked;
  int color;

  _FilterCategory({
    required this.name,
    required this.icon,
    required this.blocked,
    required this.color,
  });
}
