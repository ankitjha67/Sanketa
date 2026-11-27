import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _dndEnabled = false;
  int _filterIdx = 0;

  static const _filters = ['All', 'Alerts', 'Updates', 'System', 'Apps'];

  final _notifications = <_TvNotification>[
    _TvNotification(
      title: 'Firmware Update Available',
      body: 'Version 4.2.1 is ready to install. Improvements to HDR and audio.',
      category: 'Updates',
      icon: Icons.system_update,
      color: AppColors.primary,
      time: '2 min ago',
      read: false,
    ),
    _TvNotification(
      title: 'Storage Almost Full',
      body: 'Only 1.2 GB remaining on internal storage. Free up space.',
      category: 'Alerts',
      icon: Icons.storage,
      color: AppColors.error,
      time: '15 min ago',
      read: false,
    ),
    _TvNotification(
      title: 'Netflix',
      body: 'New season of Stranger Things now streaming.',
      category: 'Apps',
      icon: Icons.play_arrow,
      color: AppColors.signalEmerald,
      time: '1 hr ago',
      read: true,
    ),
    _TvNotification(
      title: 'Energy Saving Mode',
      body: 'TV has been idle for 2 hours. Auto-standby in 30 minutes.',
      category: 'System',
      icon: Icons.eco,
      color: AppColors.alertAmber,
      time: '2 hr ago',
      read: true,
    ),
    _TvNotification(
      title: 'Bluetooth Connected',
      body: 'JBL Flip 6 paired successfully as audio output.',
      category: 'System',
      icon: Icons.bluetooth_connected,
      color: AppColors.secondary,
      time: '3 hr ago',
      read: true,
    ),
    _TvNotification(
      title: 'YouTube',
      body: 'Your subscribed channel uploaded a new video.',
      category: 'Apps',
      icon: Icons.smart_display,
      color: AppColors.error,
      time: '5 hr ago',
      read: true,
    ),
    _TvNotification(
      title: 'HDMI 2 Connected',
      body: 'PlayStation 5 detected on HDMI 2.',
      category: 'System',
      icon: Icons.input,
      color: AppColors.tertiary,
      time: '1 day ago',
      read: true,
    ),
    _TvNotification(
      title: 'Software Patch',
      body: 'Security patch applied. No restart required.',
      category: 'Updates',
      icon: Icons.security,
      color: AppColors.signalEmerald,
      time: '2 days ago',
      read: true,
    ),
  ];

  List<_TvNotification> get _filtered => _filterIdx == 0
      ? _notifications
      : _notifications
          .where((n) => n.category == _filters[_filterIdx])
          .toList();

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ));
  }

  void _dismiss(int idx) {
    final actual = _notifications.indexOf(_filtered[idx]);
    if (actual >= 0) {
      setState(() => _notifications.removeAt(actual));
      HapticFeedback.selectionClick();
    }
  }

  void _openOnTv(_TvNotification notif) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.home);
    HapticFeedback.mediumImpact();
    setState(() => notif.read = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Opening: ${notif.title}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Notifications',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all, color: hex(AppColors.primary)),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _dndToggle(),
          const SizedBox(height: AppSpacing.md),
          _filterChips(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          if (_filtered.isEmpty)
            _emptyState()
          else
            ..._filtered.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _notificationCard(e.key, e.value),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_active,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('TV Notifications',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Manage alerts, updates, and app notifications from your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _dndToggle() => GestureDetector(
        onTap: () {
          setState(() => _dndEnabled = !_dndEnabled);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_dndEnabled
                    ? AppColors.error
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _dndEnabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_dndEnabled
                      ? AppColors.error
                      : AppColors.outlineVariant)
                  .withValues(alpha: _dndEnabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _dndEnabled
                    ? Icons.do_not_disturb_on
                    : Icons.do_not_disturb_off,
                size: 22,
                color: hex(
                    _dndEnabled ? AppColors.error : AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Do Not Disturb',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text(
                      _dndEnabled
                          ? 'TV notifications silenced'
                          : 'All notifications enabled',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_dndEnabled
                          ? AppColors.error
                          : AppColors.signalEmerald)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_dndEnabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_dndEnabled
                            ? AppColors.error
                            : AppColors.signalEmerald),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _filterChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.asMap().entries.map((e) {
            final active = e.key == _filterIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filterIdx = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.secondary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.secondary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Text(e.value,
                      style: gfont(AppType.bodySm,
                          color: hex(active
                              ? AppColors.secondary
                              : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Total', '${_filtered.length}', AppColors.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Unread', '$_unreadCount', AppColors.error)),
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
                    color: hex(c), size: 20, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _notificationCard(int idx, _TvNotification notif) =>
      GestureDetector(
        onTap: () => _openOnTv(notif),
        onLongPress: () => _dismiss(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(notif.color)
                .withValues(alpha: notif.read ? 0.04 : 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(notif.color)
                    .withValues(alpha: notif.read ? 0.12 : 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hex(notif.color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(notif.icon,
                    size: 18, color: hex(notif.color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: notif.read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  size: 13)),
                        ),
                        if (!notif.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hex(AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notif.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                hex(notif.color).withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(notif.category,
                              style: gfont(AppType.bodySm,
                                  color: hex(notif.color), size: 8)),
                        ),
                        const SizedBox(width: 6),
                        Text(notif.time,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.notifications_none,
                size: 48, color: hex(AppColors.outline)),
            const SizedBox(height: 8),
            Text('No notifications',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w500)),
          ],
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
                'Tap a notification to open on TV. Long-press to dismiss. '
                'Sample data — no live connection.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _TvNotification {
  final String title;
  final String body;
  final String category;
  final IconData icon;
  final int color;
  final String time;
  bool read;
  _TvNotification({
    required this.title,
    required this.body,
    required this.category,
    required this.icon,
    required this.color,
    required this.time,
    required this.read,
  });
}
