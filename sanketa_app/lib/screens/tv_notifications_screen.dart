import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Notification {
  _Notification({
    required this.app,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.read = false,
  });

  final String app;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  bool read;
}

class TvNotificationsScreen extends StatefulWidget {
  const TvNotificationsScreen({super.key});

  @override
  State<TvNotificationsScreen> createState() => _TvNotificationsScreenState();
}

class _TvNotificationsScreenState extends State<TvNotificationsScreen> {
  bool _mirrorPhone = false;
  bool _showOnTv = true;

  final _notifications = [
    _Notification(app: 'YouTube', title: 'New upload', body: 'MKBHD posted: "iPhone 17 Review"', time: '2m ago', icon: Icons.play_circle),
    _Notification(app: 'System', title: 'Update available', body: 'Android TV 14 update ready to install', time: '15m ago', icon: Icons.system_update),
    _Notification(app: 'Google Cast', title: 'Cast ready', body: 'Living Room TV is available for casting', time: '1h ago', icon: Icons.cast, read: true),
    _Notification(app: 'Netflix', title: 'New season', body: 'Stranger Things Season 5 is now streaming', time: '3h ago', icon: Icons.movie),
    _Notification(app: 'Spotify', title: 'Now playing', body: 'Playing "Blinding Lights" on Living Room TV', time: '4h ago', icon: Icons.music_note, read: true),
    _Notification(app: 'Storage', title: 'Low storage', body: 'Only 1.2 GB remaining on internal storage', time: '1d ago', icon: Icons.storage),
  ];

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
  }

  void _dismiss(int index) {
    setState(() => _notifications.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Notifications',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600, size: 11)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _summaryCard(),
          const SizedBox(height: AppSpacing.md),
          _togglesSection(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Notifications ($_unreadCount unread)',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              const Spacer(),
              Text('${_notifications.length} total',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          ..._notifications.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _notifCard(e.value, e.key),
          )),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_unreadCount > 0 ? AppColors.primary : AppColors.surfaceContainerLow)
          .withValues(alpha: _unreadCount > 0 ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(
        color: hex(_unreadCount > 0 ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: 0.2),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Stack(
            children: [
              Center(child: Icon(Icons.notifications, size: 24, color: hex(AppColors.primary))),
              if (_unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: hex(AppColors.error),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$_unreadCount',
                          style: gfont(AppType.labelMonoSm, color: Colors.white, size: 9, weight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_unreadCount > 0 ? '$_unreadCount New Notifications' : 'All Caught Up',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('From your Living Room TV',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _togglesSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        _toggleRow(Icons.phone_android, 'Mirror phone notifications to TV', _mirrorPhone,
            (v) => setState(() => _mirrorPhone = v)),
        const SizedBox(height: 6),
        _toggleRow(Icons.tv, 'Show TV notifications on phone', _showOnTv,
            (v) => setState(() => _showOnTv = v)),
      ],
    ),
  );

  Widget _toggleRow(IconData icon, String label, bool value, void Function(bool) onChanged) => Row(
    children: [
      Icon(icon, size: 18, color: hex(AppColors.primary)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 12)),
      ),
      SizedBox(
        height: 32,
        child: Switch(
          value: value,
          activeTrackColor: hex(AppColors.primary),
          onChanged: onChanged,
        ),
      ),
    ],
  );

  Widget _notifCard(_Notification n, int index) => Dismissible(
    key: ValueKey('$index-${n.title}'),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => _dismiss(index),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: hex(AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(Icons.delete, color: hex(AppColors.error)),
    ),
    child: GestureDetector(
      onTap: () => setState(() => n.read = true),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(n.read ? AppColors.surfaceContainerLow : AppColors.primary)
              .withValues(alpha: n.read ? 1 : 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(n.read ? AppColors.outlineVariant : AppColors.primary)
                .withValues(alpha: n.read ? 0.15 : 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(n.icon, size: 16, color: hex(AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(n.app,
                          style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600, size: 10)),
                      const Spacer(),
                      Text(n.time,
                          style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
                      if (!n.read) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: hex(AppColors.primary), shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  Text(n.title,
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface),
                          weight: n.read ? FontWeight.w400 : FontWeight.w600, size: 12)),
                  Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
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
            'View and manage notifications from your TV. Swipe left to dismiss. Mirror phone notifications to your TV or pull TV alerts to your phone.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
