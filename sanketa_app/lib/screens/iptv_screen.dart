import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'package:url_launcher/url_launcher.dart';

import '../control/remote_controller.dart';
import '../services/iptv_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

class IptvScreen extends StatefulWidget {
  const IptvScreen({super.key});

  @override
  State<IptvScreen> createState() => _IptvScreenState();
}

class _IptvScreenState extends State<IptvScreen>
    with SingleTickerProviderStateMixin {
  final _service = IptvService();
  late final TabController _tabs;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  core.IptvSource? _lastSource;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _service.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    _service.dispose();
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Free TV',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: hex(AppColors.primary),
          unselectedLabelColor: hex(AppColors.onSurfaceVariant),
          indicatorColor: hex(AppColors.primary),
          labelStyle: gfont(AppType.bodySm, size: 13, weight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Countries'),
            Tab(text: 'Languages'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Column(children: [
        if (_service.currentSourceId != null &&
            _service.currentSourceId!.isNotEmpty)
          _searchBar(),
        Expanded(
          child: _service.currentSourceId == null ||
                  _service.currentSourceId!.isEmpty
              ? TabBarView(
                  controller: _tabs,
                  children: [
                    _sourceGrid(core.IptvCatalog.byCategory),
                    _sourceGrid(core.IptvCatalog.byCountry),
                    _sourceGrid(core.IptvCatalog.byLanguage),
                    _favoritesView(),
                  ],
                )
              : _channelList(),
        ),
      ]),
    );
  }

  Widget _searchBar() => Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              _service.loadSource(
                  const core.IptvSource(id: '', name: '', url: ''));
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: Icon(Icons.arrow_back,
                size: 20, color: hex(AppColors.onSurfaceVariant)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), size: 14),
              decoration: InputDecoration(
                hintText: 'Search channels...',
                hintStyle:
                    gfont(AppType.bodySm, color: hex(AppColors.outline)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                filled: true,
                fillColor: hex(AppColors.surfaceContainerHigh),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search,
                    size: 18, color: hex(AppColors.outline)),
              ),
            ),
          ),
        ]),
      );

  Widget _sourceGrid(List<core.IptvSource> sources) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sources.length,
      itemBuilder: (ctx, i) => _sourceCard(sources[i]),
    );
  }

  void _retry() {
    if (_lastSource != null) {
      _service.loadSource(_lastSource!);
    }
  }

  Widget _sourceCard(core.IptvSource source) {
    return GestureDetector(
      onTap: () {
        _lastSource = source;
        _service.loadSource(source);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(
            fill: AppColors.surfaceContainerLowest,
            radius: AppRadii.md,
            borderOpacity: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(source.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    size: 14,
                    weight: FontWeight.w500)),
            if (source.description != null) ...[
              const SizedBox(height: 2),
              Text(source.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant), size: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _channelList() {
    if (_service.isLoading && _service.channels.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: hex(AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        Text('Loading channels...',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
      ]));
    }

    if (_service.error != null && _service.channels.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text(_service.error!,
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: hex(AppColors.primaryContainer),
              foregroundColor: hex(AppColors.onPrimaryContainer),
            ),
          ),
        ]),
      ));
    }

    final filtered = _searchQuery.isEmpty
        ? _service.channels
        : _service.search(_searchQuery);

    if (filtered.isEmpty) {
      return Center(
          child: Text('No channels found.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))));
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(children: [
          Text('${filtered.length} channels',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 11)),
          const Spacer(),
          if (_service.isLoading)
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: hex(AppColors.primary))),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _channelTile(filtered[i]),
        ),
      ),
    ]);
  }

  Widget _channelTile(core.IptvChannel channel) {
    final isFav = _service.isFavorite(channel);
    return GestureDetector(
      onLongPress: () => _showChannelOptions(channel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
          tileColor: hex(AppColors.surfaceContainerLowest),
          leading: _channelLogo(channel),
          title: Text(channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  size: 13,
                  weight: FontWeight.w500)),
          subtitle: channel.groupTitle != null
              ? Text(channel.groupTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant), size: 11))
              : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () => _service.toggleFavorite(channel),
              child: Icon(isFav ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFav
                      ? hex(AppColors.tertiary)
                      : hex(AppColors.outlineVariant)),
            ),
            const SizedBox(width: 6),
            _actionPill(
              icon: Icons.play_arrow,
              label: 'Watch',
              color: hex(AppColors.tertiary),
              onTap: () => _watchChannel(channel),
            ),
            const SizedBox(width: 4),
            _actionPill(
              icon: Icons.cast,
              label: 'Cast',
              color: hex(AppColors.primary),
              onTap: () => _castChannel(channel),
            ),
          ]),
        ),
      ),
    );
  }

  void _showChannelOptions(core.IptvChannel channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerHigh),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(channel.name,
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 16,
                    weight: FontWeight.w600)),
          ),
          ListTile(
            leading: Icon(Icons.play_arrow, color: hex(AppColors.tertiary)),
            title: Text('Watch in app',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            subtitle: Text('Play with built-in player',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 12)),
            onTap: () {
              Navigator.pop(context);
              _watchChannel(channel);
            },
          ),
          ListTile(
            leading:
                Icon(Icons.open_in_new, color: hex(AppColors.onSurfaceVariant)),
            title: Text('Open in external player',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            subtitle: Text('VLC, MX Player, etc.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 12)),
            onTap: () {
              Navigator.pop(context);
              _openExternal(channel);
            },
          ),
          ListTile(
            leading: Icon(Icons.cast, color: hex(AppColors.primary)),
            title: Text('Cast to TV',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            subtitle: Text('Send to connected TV',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 12)),
            onTap: () {
              Navigator.pop(context);
              _castChannel(channel);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ]),
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.base),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: color, size: 11, weight: FontWeight.w500)),
        ]),
      ),
    );
  }

  void _watchChannel(core.IptvChannel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)),
    );
  }

  void _openExternal(core.IptvChannel channel) async {
    final uri = Uri.parse(channel.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No video player found. Install VLC or MX Player.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ),
      );
    }
  }

  Widget _channelLogo(core.IptvChannel channel) {
    if (channel.tvgLogo != null && channel.tvgLogo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          channel.tvgLogo!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholderLogo(channel),
        ),
      );
    }
    return _placeholderLogo(channel);
  }

  Widget _placeholderLogo(core.IptvChannel channel) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurfaceVariant),
                size: 16,
                weight: FontWeight.w600),
          ),
        ),
      );

  Widget _favoritesView() {
    final favs = _service.favoriteChannels;
    if (favs.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_border, size: 48, color: hex(AppColors.outlineVariant)),
        const SizedBox(height: AppSpacing.md),
        Text('No favorites yet',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant))),
        const SizedBox(height: AppSpacing.sm),
        Text('Browse a category and tap the star to add channels.',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.outline), size: 12)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: favs.length,
      itemBuilder: (ctx, i) => _channelTile(favs[i]),
    );
  }

  void _castChannel(core.IptvChannel channel) {
    final c = RemoteScope.of(context);
    if (!c.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connect to a TV first',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ),
      );
      return;
    }
    final isHls = channel.url.toLowerCase().endsWith('.m3u8') ||
        channel.url.toLowerCase().contains('.m3u8?');
    c.castUri(
      channel.url,
      title: channel.name,
      mimeType: isHls ? 'application/x-mpegURL' : null,
    );
    Navigator.pop(context);
  }
}
