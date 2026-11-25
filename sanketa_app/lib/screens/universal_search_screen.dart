import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _recentSearches = <String>[];
  String _selectedTarget = 'tv';

  static const _targets = <String, (String, IconData)>{
    'tv': ('TV Search', Icons.tv),
    'youtube': ('YouTube', Icons.play_circle_filled),
    'netflix': ('Netflix', Icons.movie),
    'prime': ('Prime Video', Icons.video_library),
    'disney': ('Disney+', Icons.castle),
    'spotify': ('Spotify', Icons.music_note),
  };

  static const _quickCategories = <(String, IconData, String)>[
    ('Movies', Icons.movie, 'movies'),
    ('TV Shows', Icons.tv, 'tv shows'),
    ('Music', Icons.music_note, 'music'),
    ('Sports', Icons.sports, 'sports'),
    ('News', Icons.newspaper, 'news'),
    ('Kids', Icons.child_care, 'kids'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendSearch(String query) {
    if (query.trim().isEmpty) return;
    final c = RemoteScope.of(context);
    c.type(query.trim());
    c.key(core.Key.ok);

    setState(() {
      _recentSearches.remove(query.trim());
      _recentSearches.insert(0, query.trim());
      if (_recentSearches.length > 20) {
        _recentSearches.removeLast();
      }
    });

    _controller.clear();

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Searching "${query.trim()}" on ${_targets[_selectedTarget]!.$1}'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _openApp(String target) {
    final c = RemoteScope.of(context);
    c.key(core.Key.home);
    setState(() => _selectedTarget = target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Universal Search',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _searchBar(),
          _targetSelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                if (_recentSearches.isNotEmpty) ...[
                  _recentSection(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _quickCategoriesSection(),
                const SizedBox(height: AppSpacing.lg),
                _infoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
    child: Container(
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(Icons.search, size: 20, color: hex(AppColors.outline)),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _sendSearch,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Search on your TV...',
                hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _controller.clear()),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.close, size: 18, color: hex(AppColors.outline)),
              ),
            ),
          GestureDetector(
            onTap: () => _sendSearch(_controller.text),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(Icons.send, size: 16, color: hex(AppColors.onPrimaryContainer)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _targetSelector() => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _targets.entries.map((e) {
          final active = _selectedTarget == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _openApp(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primaryContainer : AppColors.outlineVariant)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.$2, size: 14,
                        color: hex(active ? AppColors.primary : AppColors.onSurface)),
                    const SizedBox(width: 6),
                    Text(e.value.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? AppColors.primary : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 12)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _recentSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('Recent',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _recentSearches.clear()),
            child: Text('Clear',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...List.generate(
        _recentSearches.length > 5 ? 5 : _recentSearches.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () => _sendSearch(_recentSearches[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLowest),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: hex(AppColors.outlineVariant)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_recentSearches[i],
                        style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
                  ),
                  Icon(Icons.north_west, size: 12, color: hex(AppColors.outlineVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _quickCategoriesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Quick Categories',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: _quickCategories.map((cat) => GestureDetector(
          onTap: () => _sendSearch(cat.$3),
          child: Container(
            decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.$2, size: 20, color: hex(AppColors.primary)),
                const SizedBox(height: 4),
                Text(cat.$1,
                    style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 11)),
              ],
            ),
          ),
        )).toList(),
      ),
    ],
  );

  Widget _infoCard() => Container(
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
            'Type a search query and select which app to search in. The query is typed on your TV and submitted.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
