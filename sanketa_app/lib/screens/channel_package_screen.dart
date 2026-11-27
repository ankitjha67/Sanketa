import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelPackageScreen extends StatefulWidget {
  const ChannelPackageScreen({super.key});

  @override
  State<ChannelPackageScreen> createState() => _ChannelPackageScreenState();
}

class _ChannelPackageScreenState extends State<ChannelPackageScreen> {
  bool _loading = true;
  final _subscribed = <int>{0, 2};

  static final _packages = <_Package>[
    _Package(
      name: 'Basic HD',
      channels: 85,
      price: 199,
      icon: Icons.tv,
      color: AppColors.primary,
      highlights: ['50 SD + 35 HD', 'Local news', 'Basic sports'],
    ),
    _Package(
      name: 'Sports Plus',
      channels: 45,
      price: 349,
      icon: Icons.sports_cricket,
      color: AppColors.signalEmerald,
      highlights: ['All live sports', 'ESPN bundle', '4K sports'],
    ),
    _Package(
      name: 'Movie Max',
      channels: 60,
      price: 299,
      icon: Icons.movie,
      color: AppColors.alertAmber,
      highlights: ['Premium movies', 'HBO + Showtime', 'On-demand'],
    ),
    _Package(
      name: 'Kids Zone',
      channels: 25,
      price: 149,
      icon: Icons.child_care,
      color: AppColors.secondary,
      highlights: ['Cartoon Network', 'Disney Jr', 'Parental lock'],
    ),
    _Package(
      name: 'News 24/7',
      channels: 30,
      price: 179,
      icon: Icons.newspaper,
      color: AppColors.tertiary,
      highlights: ['CNN + BBC', 'Local news HD', 'Business channels'],
    ),
    _Package(
      name: 'Premium All',
      channels: 250,
      price: 799,
      icon: Icons.diamond,
      color: AppColors.error,
      highlights: ['All channels', '4K + HDR', 'On-demand library'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_packages.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _subscribed
          ..clear()
          ..addAll(list.cast<int>());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_subscribed.toList()));
  }

  void _togglePackage(int idx) {
    setState(() {
      if (_subscribed.contains(idx)) {
        _subscribed.remove(idx);
      } else {
        _subscribed.add(idx);
      }
    });
    HapticFeedback.mediumImpact();
    _save();
  }

  void _openOnTv() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Opening packages on TV'),
        duration: Duration(seconds: 2),
      ));
  }

  int get _totalChannels {
    var total = 0;
    for (final idx in _subscribed) {
      total += _packages[idx].channels;
    }
    return total;
  }

  int get _totalPrice {
    var total = 0;
    for (final idx in _subscribed) {
      total += _packages[idx].price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Packages',
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
                const SizedBox(height: AppSpacing.md),
                _statsRow(),
                const SizedBox(height: AppSpacing.md),
                ..._packages.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _packageCard(e.key, e.value),
                    )),
                const SizedBox(height: AppSpacing.md),
                _openButton(),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2, size: 48,
                color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Channel Packages',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Browse and manage your TV channel subscriptions',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Subscribed', '${_subscribed.length}', AppColors.signalEmerald)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Channels', '$_totalChannels', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Monthly', '₹$_totalPrice', AppColors.alertAmber)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 16, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _packageCard(int idx, _Package pkg) {
    final active = _subscribed.contains(idx);
    return GestureDetector(
      onTap: () => _togglePackage(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? pkg.color : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? pkg.color : AppColors.outlineVariant)
                .withValues(alpha: active ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hex(pkg.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(pkg.icon, size: 24, color: hex(pkg.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(pkg.name,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 14)),
                      const Spacer(),
                      Text('₹${pkg.price}/mo',
                          style: gfont(AppType.bodySm,
                              color: hex(pkg.color),
                              weight: FontWeight.w700,
                              size: 12)),
                    ],
                  ),
                  Text('${pkg.channels} channels',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: pkg.highlights.map((h) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: hex(pkg.color).withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(h,
                              style: gfont(AppType.bodySm,
                                  color: hex(pkg.color), size: 8)),
                        )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(active
                        ? AppColors.signalEmerald
                        : AppColors.outline)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(active ? 'Active' : 'Add',
                  style: gfont(AppType.bodySm,
                      color: hex(active
                          ? AppColors.signalEmerald
                          : AppColors.outline),
                      weight: FontWeight.w700,
                      size: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _openButton() => GestureDetector(
        onTap: _openOnTv,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.secondary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tv, size: 20, color: hex(AppColors.secondary)),
              const SizedBox(width: 8),
              Text('Open on TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.secondary),
                      weight: FontWeight.w600)),
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
                'Browse channel packages. Tap to subscribe or unsubscribe. '
                'Prices are samples. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Package {
  final String name;
  final int channels;
  final int price;
  final IconData icon;
  final int color;
  final List<String> highlights;
  _Package({
    required this.name,
    required this.channels,
    required this.price,
    required this.icon,
    required this.color,
    required this.highlights,
  });
}
