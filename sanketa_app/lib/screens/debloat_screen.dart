import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../services/debloat_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class DebloatScreen extends StatefulWidget {
  const DebloatScreen({super.key});

  @override
  State<DebloatScreen> createState() => _DebloatScreenState();
}

class _DebloatScreenState extends State<DebloatScreen> {
  final _service = DebloatService();
  String _filter = 'all';
  bool _safeOnly = true;
  String _searchQuery = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final c = RemoteScope.of(context);
      final host = c.tvHost;
      _service.loadDatabase().then((_) {
        if (mounted && host != null && host.isNotEmpty) {
          _service.connectToTv(host);
        }
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    _service.dispose();
    super.dispose();
  }

  String _brandFromDevice(RemoteController c) {
    final device = c.selectedDevice?.device;
    if (device == null) return '';
    return switch (device.brand) {
      core.BrandFamily.tizen => 'samsung',
      core.BrandFamily.webOs => 'lg',
      core.BrandFamily.bravia => 'sony',
      core.BrandFamily.fireTv => 'fire_tv',
      core.BrandFamily.roku => 'roku',
      core.BrandFamily.hisense => 'hisense',
      core.BrandFamily.panasonic => 'panasonic',
      core.BrandFamily.vizio => 'vizio',
      core.BrandFamily.tcl => 'tcl',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      body: SafeArea(
        child: Column(children: [
          _header(context),
          Expanded(child: _body()),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
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
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.arrow_back,
                    size: 24, color: hex(AppColors.onSurface)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.cleaning_services,
                  size: 20, color: hex(AppColors.primaryContainer)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('TV Debloat',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 16,
                        weight: FontWeight.w600)),
              ),
              if (_service.isConnected)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: hex(AppColors.onSurfaceVariant)),
                  onSelected: _handleMenu,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'disable_all',
                        child: Text('Disable all safe')),
                    const PopupMenuItem(
                        value: 'restore_all', child: Text('Restore all')),
                  ],
                ),
              _statBadge(),
            ]),
          ),
        ),
      );

  Widget _statBadge() {
    final label = _service.isConnected
        ? '${_service.disabledCount} disabled'
        : 'Not connected';
    final color = _service.isConnected
        ? hex(AppColors.primaryContainer)
        : hex(AppColors.outline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(label,
          style: gfont(AppType.labelMonoSm, color: color, size: 11)),
    );
  }

  Widget _body() {
    if (_service.isConnecting) return _connecting();
    if (!_service.isConnected && _service.allEntries.isEmpty) {
      return _notConnected();
    }
    return _packageList();
  }

  Widget _connecting() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: hex(AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Text('Connecting via ADB...',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
        ]),
      );

  Widget _notConnected() {
    final c = RemoteScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.link_off, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('ADB Connection Required',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 16,
                  weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _service.connectionError ??
                'Connect to an Android TV first, then enable ADB over WiFi.\n\n'
                    'Settings > Device Preferences > About > Build (tap 7x) > '
                    'Developer Options > ADB Debugging ON',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant), size: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              final host = c.tvHost;
              if (host != null && host.isNotEmpty) {
                _service.connectToTv(host);
              } else {
                _showManualIpDialog();
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(c.tvHost != null ? 'Retry Connection' : 'Enter TV IP'),
            style: FilledButton.styleFrom(
              backgroundColor: hex(AppColors.primaryContainer),
              foregroundColor: hex(AppColors.onPrimaryContainer),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _packageList() {
    final c = RemoteScope.of(context);
    final brand = _brandFromDevice(c);
    var entries = brand.isNotEmpty
        ? _service.entriesForBrand(brand)
        : _service.allEntries;
    if (_safeOnly) entries = entries.where((e) => e.safeToDisable).toList();
    if (_filter != 'all') {
      final cat = core.BloatCategory.fromJson(_filter);
      entries = entries.where((e) => e.category == cat).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.package.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }

    final grouped = _service.groupByCategory(entries);

    return Column(children: [
      if (_service.isConnected) _connectionBadge(),
      _searchAndFilters(brand),
      if (_service.operationError != null) _errorBar(),
      Expanded(
        child: entries.isEmpty
            ? _emptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                itemCount: grouped.length,
                itemBuilder: (ctx, i) {
                  final cat = grouped.keys.elementAt(i);
                  return _CategorySection(
                    category: cat,
                    entries: grouped[cat]!,
                    service: _service,
                  );
                },
              ),
      ),
    ]);
  }

  Widget _connectionBadge() => Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(
            fill: AppColors.surfaceContainerLowest,
            radius: AppRadii.md,
            borderOpacity: 0.2),
        child: Row(children: [
          const PulseDot(color: Colors.green, size: 8),
          const SizedBox(width: AppSpacing.sm),
          Text('Connected via ADB',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.onSurface), size: 11)),
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Safe only',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11)),
            SizedBox(
              height: 24,
              width: 36,
              child: Switch(
                value: _safeOnly,
                onChanged: (v) => setState(() => _safeOnly = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ]),
      );

  Widget _searchAndFilters(String brand) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: panel(
                fill: AppColors.surfaceContainerLowest,
                radius: AppRadii.md,
                borderOpacity: 0.3),
            child: Row(children: [
              Icon(Icons.search,
                  size: 18, color: hex(AppColors.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface)),
                  decoration: InputDecoration(
                    hintText: 'Search packages...',
                    hintStyle: gfont(AppType.bodySm,
                        color: hex(AppColors.outlineVariant)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          _filterChips(),
        ]),
      );

  Widget _filterChips() {
    const cats = [
      ('all', 'All'),
      ('ads', 'Ads'),
      ('telemetry', 'Telemetry'),
      ('bloatware', 'Bloatware'),
      ('google_unused', 'Google'),
      ('oem_launcher', 'OEM'),
    ];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (id, label) in cats)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: _filter == id
                            ? hex(AppColors.onPrimary)
                            : hex(AppColors.onSurfaceVariant))),
                selected: _filter == id,
                onSelected: (_) => setState(() => _filter = id),
                selectedColor: hex(AppColors.primary),
                backgroundColor: hex(AppColors.surfaceContainerHigh),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorBar() => Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border:
              Border.all(color: hex(AppColors.error).withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: hex(AppColors.error)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_service.operationError!,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface), size: 12))),
        ]),
      );

  Widget _emptyState() => Center(
        child: Text('No bloatware entries match this filter.',
            style:
                gfont(AppType.bodySm, color: hex(AppColors.onSurfaceVariant))),
      );

  void _handleMenu(String action) {
    final c = RemoteScope.of(context);
    final brand = _brandFromDevice(c);
    final entries = brand.isNotEmpty
        ? _service.entriesForBrand(brand)
        : _service.allEntries;
    if (action == 'disable_all') {
      _service.disableAllSafe(entries);
    } else if (action == 'restore_all') {
      _service.restoreAll(entries);
    }
  }

  void _showManualIpDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter TV IP Address'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '192.168.1.x',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                _service.connectToTv(ip);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  const _CategorySection({
    required this.category,
    required this.entries,
    required this.service,
  });

  final core.BloatCategory category;
  final List<core.BloatwareEntry> entries;
  final DebloatService service;

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  String get _label => switch (widget.category) {
        core.BloatCategory.ads => 'Ads & Tracking',
        core.BloatCategory.telemetry => 'Telemetry & Analytics',
        core.BloatCategory.bloatware => 'Bloatware',
        core.BloatCategory.googleUnused => 'Unused Google Services',
        core.BloatCategory.oemLauncher => 'OEM Launchers',
      };

  IconData get _icon => switch (widget.category) {
        core.BloatCategory.ads => Icons.ads_click,
        core.BloatCategory.telemetry => Icons.analytics_outlined,
        core.BloatCategory.bloatware => Icons.delete_sweep,
        core.BloatCategory.googleUnused => Icons.apps_outage,
        core.BloatCategory.oemLauncher => Icons.home_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [
            Icon(_icon, size: 16, color: hex(AppColors.primaryContainer)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(_label,
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 13,
                      weight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text('${widget.entries.length}',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.onSurfaceVariant), size: 10)),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 18,
              color: hex(AppColors.onSurfaceVariant),
            ),
          ]),
        ),
        if (_expanded)
          ...widget.entries.map((e) => _PackageTile(
                entry: e,
                service: widget.service,
              )),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.entry, required this.service});

  final core.BloatwareEntry entry;
  final DebloatService service;

  Color _severityColor() => switch (entry.severity) {
        core.BloatSeverity.high => const Color(0xFFEF4444),
        core.BloatSeverity.medium => const Color(0xFFF59E0B),
        core.BloatSeverity.low => const Color(0xFF10B981),
      };

  String _severityLabel() => switch (entry.severity) {
        core.BloatSeverity.high => 'HIGH',
        core.BloatSeverity.medium => 'MED',
        core.BloatSeverity.low => 'LOW',
      };

  @override
  Widget build(BuildContext context) {
    final installed = service.isPackageInstalled(entry.package);
    final enabled = service.isPackageEnabled(entry.package);
    final operating = service.isOperating(entry.package);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(
        fill: !enabled
            ? AppColors.surfaceContainerHighest
            : AppColors.surfaceContainerLowest,
        radius: AppRadii.md,
        borderOpacity: 0.2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(entry.name,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  _badge(_severityLabel(), _severityColor()),
                  if (!entry.safeToDisable) ...[
                    const SizedBox(width: 4),
                    _badge('UNSAFE', hex(AppColors.error)),
                  ],
                  if (!installed) ...[
                    const SizedBox(width: 4),
                    _badge('N/A', hex(AppColors.outline)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(entry.package,
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.outline), size: 10)),
                const SizedBox(height: 2),
                Text(entry.description,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant), size: 11)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (operating)
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: hex(AppColors.primary)))
          else if (installed && entry.safeToDisable)
            GestureDetector(
              onTap: () {
                if (enabled) {
                  service.disablePackage(entry);
                } else {
                  service.enablePackage(entry);
                }
              },
              child: Container(
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  color: !enabled
                      ? hex(AppColors.primaryContainer)
                      : hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: !enabled
                        ? hex(AppColors.primaryContainer)
                        : hex(AppColors.outlineVariant).withValues(alpha: 0.5),
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: !enabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: !enabled
                          ? hex(AppColors.onPrimary)
                          : hex(AppColors.onSurfaceVariant)
                              .withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
          else if (!entry.safeToDisable)
            Icon(Icons.lock_outline,
                size: 16, color: hex(AppColors.outlineVariant)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700, color: color)),
      );
}
