import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _doSearch(RemoteController c) {
    final query = _textController.text.trim();
    if (query.isEmpty) return;
    for (final ch in query.characters) {
      c.type(ch);
    }
    c.submit();
    c.addRecentSearch(query);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Column(
      children: [
        _header(c),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchBar(c),
                    const SizedBox(height: AppSpacing.xl),
                    _searchShortcuts(c),
                    const SizedBox(height: AppSpacing.xl),
                    _quickApps(c),
                    const SizedBox(height: AppSpacing.xl),
                    _recentSearches(c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(RemoteController c) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                Icon(Icons.search, size: 24, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(c.isConnected ? 'Search on ${c.deviceName}' : 'Search',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 16,
                          weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _searchBar(RemoteController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border:
            Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: hex(AppColors.outline)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Search movies, shows, apps...',
                hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _doSearch(c),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _doSearch(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text('Go',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onPrimaryContainer),
                      weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchShortcuts(RemoteController c) {
    const shortcuts = [
      ('Netflix', 'Netflix', Icons.play_circle_fill),
      ('YouTube', 'YouTube', Icons.smart_display),
      ('Prime Video', 'Prime Video', Icons.movie),
      ('Disney+', 'Disney+', Icons.star),
      ('Spotify', 'Spotify', Icons.music_note),
      ('Settings', 'Settings', Icons.settings),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SEARCH SHORTCUTS',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        Text('Tap to search directly on TV',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurfaceVariant))),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (label, query, icon) in shortcuts)
              _shortcutChip(label, query, icon, c),
          ],
        ),
      ],
    );
  }

  Widget _shortcutChip(
      String label, String query, IconData icon, RemoteController c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        for (final ch in query.characters) {
          c.type(ch);
        }
        c.submit();
        c.addRecentSearch(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: hex(AppColors.primaryContainer)),
            const SizedBox(width: 4),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500,
                    size: 12)),
          ],
        ),
      ),
    );
  }

  Widget _quickApps(RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK LAUNCH',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _appChip('Netflix', AppColors.netflix, c),
            _appChip('YouTube', AppColors.youTube, c),
            _appChip('Prime Video', AppColors.prime, c),
            _appChip('Disney+', AppColors.disney, c),
          ],
        ),
        if (c.lastCommandError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(c.lastCommandError!,
              style: gfont(AppType.bodySm, color: hex(AppColors.error))),
        ],
      ],
    );
  }

  Widget _appChip(String name, int color, RemoteController c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        c.launch(name);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Launching $name${c.isConnected ? ' on ${c.deviceName}' : ''}',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            duration: const Duration(seconds: 1),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: panel(
            fill: AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: 0.3),
        child: Text(name,
            style: gfont(AppType.bodySm,
                color: hex(color), weight: FontWeight.w700)),
      ),
    );
  }

  Widget _recentSearches(RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        if (c.recentSearches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: panel(
                fill: AppColors.surfaceContainerLowest,
                radius: AppRadii.md,
                borderOpacity: 0.2),
            child: Column(
              children: [
                Icon(Icons.history,
                    size: 32, color: hex(AppColors.outlineVariant)),
                const SizedBox(height: AppSpacing.sm),
                Text('Your recent searches will appear here',
                    textAlign: TextAlign.center,
                    style:
                        gfont(AppType.bodySm, color: hex(AppColors.outline))),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: panel(
                fill: AppColors.surfaceContainerLowest,
                radius: AppRadii.md,
                borderOpacity: 0.2),
            child: Column(
              children: [
                for (final query in c.recentSearches)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _textController.text = query;
                      _doSearch(c);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              size: 16, color: hex(AppColors.outline)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(query,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface))),
                          ),
                          Icon(Icons.north_west,
                              size: 14,
                              color: hex(AppColors.outlineVariant)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
