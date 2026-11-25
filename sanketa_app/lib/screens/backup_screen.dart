import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/backup_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backup = BackupService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _backup.loadBackupList().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Backup & Restore',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: !_loaded
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(hex(AppColors.primaryContainer))))
          : ListenableBuilder(
              listenable: _backup,
              builder: (_, _) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _createBackupCard(),
                      const SizedBox(height: AppSpacing.md),
                      _whatIsBackedUp(),
                      const SizedBox(height: AppSpacing.md),
                      _backupListSection(),
                      const SizedBox(height: AppSpacing.md),
                      _privacyNote(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _createBackupCard() => GestureDetector(
        onTap: _backup.isBusy ? null : _createBackup,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: panel(
              borderColor: AppColors.primaryContainer, borderOpacity: 0.3),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: _backup.isBusy
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                hex(AppColors.primaryContainer))))
                    : Icon(Icons.backup,
                        size: 28, color: hex(AppColors.primaryContainer)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Create Backup',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 16,
                      weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Save all your settings and data',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
            ],
          ),
        ),
      );

  Widget _whatIsBackedUp() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What gets backed up',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            _dataRow(Icons.play_circle_outline, 'Macros'),
            _dataRow(Icons.bookmark, 'Search shortcuts'),
            _dataRow(Icons.dashboard_customize, 'Custom layouts'),
            _dataRow(Icons.shield, 'Parental control settings'),
            _dataRow(Icons.bar_chart, 'Usage history'),
          ],
        ),
      );

  Widget _dataRow(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.primaryContainer)),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface))),
          ],
        ),
      );

  Widget _backupListSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Backups',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            if (_backup.backups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('No backups yet',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant))),
              )
            else
              for (final b in _backup.backups) _backupTile(b),
          ],
        ),
      );

  Widget _backupTile(BackupEntry b) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 18, color: hex(AppColors.outlineVariant)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w500)),
                  Text(
                      '${_formatDate(b.created)} — ${b.sizeLabel}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _restoreBackup(b),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.primaryContainer)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text('Restore',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primaryContainer),
                        size: 11,
                        weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () async {
                await _backup.deleteBackup(b.path);
              },
              child: Icon(Icons.delete_outline,
                  size: 18, color: hex(AppColors.error)),
            ),
          ],
        ),
      );

  Widget _privacyNote() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration:
            panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 18, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Backups are stored locally on your device. '
                'No data is sent to any server.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  void _createBackup() {
    final ctrl = TextEditingController(
        text: 'Backup ${DateTime.now().day}/${DateTime.now().month}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Name your backup',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: TextField(
          controller: ctrl,
          style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: 'Backup name',
            hintStyle: gfont(AppType.bodySm,
                color: hex(AppColors.outlineVariant)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final name = ctrl.text.trim();
              if (name.isNotEmpty) _backup.createBackup(name);
            },
            child: Text('Create',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _restoreBackup(BackupEntry b) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Restore backup?',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: Text(
          'This will overwrite your current settings with '
          'the data from "${b.name}". This cannot be undone.',
          style: gfont(AppType.bodySm,
              color: hex(AppColors.onSurfaceVariant)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await _backup.restoreBackup(b.path);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Restored $count file(s). Restart the app to apply.'),
                backgroundColor: hex(AppColors.surfaceContainerHigh),
              ));
            },
            child: Text('Restore',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
