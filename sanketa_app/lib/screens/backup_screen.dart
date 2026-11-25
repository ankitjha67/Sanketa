import 'package:file_picker/file_picker.dart';
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
                      _warningBanner(),
                      const SizedBox(height: AppSpacing.md),
                      _createBackupCard(),
                      const SizedBox(height: AppSpacing.md),
                      _importSection(),
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

  // ── warning ─────────────────────────────────────────────────

  Widget _warningBanner() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
          fill: AppColors.surfaceContainer,
          borderColor: AppColors.error,
          borderOpacity: 0.4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 20, color: hex(AppColors.error)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Your passphrase cannot be recovered. If you forget it, '
                'the backup cannot be decrypted.',
                style: gfont(AppType.bodySm, color: hex(AppColors.error)),
              ),
            ),
          ],
        ),
      );

  // ── create backup ───────────────────────────────────────────

  Widget _createBackupCard() => GestureDetector(
        onTap: _backup.isBusy ? null : _showCreateDialog,
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
              Text('Create Encrypted Backup',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 16,
                      weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('AES-256 encrypted with your passphrase',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
            ],
          ),
        ),
      );

  // ── import from file ────────────────────────────────────────

  Widget _importSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hex(AppColors.secondary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(Icons.download_rounded,
                      size: 18, color: hex(AppColors.secondary)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Import Backup',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select an encrypted .sanketa file from another device '
              'and enter the passphrase used when it was created.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant)),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: hex(AppColors.secondary),
                  side: BorderSide(
                    color:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _pickAndImport,
                icon: Icon(Icons.folder_open_rounded,
                    size: 18, color: hex(AppColors.secondary)),
                label: Text('Select Backup File',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface))),
              ),
            ),
          ],
        ),
      );

  // ── what gets backed up ─────────────────────────────────────

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
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 14, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Pairing secrets stay in Keystore and are never exported.',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald), size: 10),
                  ),
                ),
              ],
            ),
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

  // ── saved backup list ───────────────────────────────────────

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
                  Text('${_formatDate(b.created)} — ${b.sizeLabel}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _restoreFromList(b),
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

  // ── privacy note ────────────────────────────────────────────

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

  // ── dialogs & actions ───────────────────────────────────────

  void _showCreateDialog() {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Create Encrypted Backup',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a passphrase to encrypt your backup. '
                'You will need it to restore.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant)),
              ),
              const SizedBox(height: AppSpacing.md),
              _dialogField(passCtrl, 'Passphrase', obscure: true),
              const SizedBox(height: AppSpacing.sm),
              _dialogField(confirmCtrl, 'Confirm passphrase', obscure: true),
            ],
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
              final pass = passCtrl.text;
              final confirm = confirmCtrl.text;
              if (pass.isEmpty) {
                _snack('Enter a passphrase', error: true);
                return;
              }
              if (pass.length < 4) {
                _snack('Passphrase too short (min 4 characters)', error: true);
                return;
              }
              if (pass != confirm) {
                _snack('Passphrases do not match', error: true);
                return;
              }
              Navigator.pop(ctx);
              _doExport(pass);
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

  Future<void> _doExport(String passphrase) async {
    try {
      final path = await _backup.exportBackup(passphrase);
      if (!mounted) return;
      _snack('Backup created: ${path.split('/').last.split('\\').last}');
    } on Object {
      if (mounted) _snack('Backup failed', error: true);
    }
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;

    if (!filePath.endsWith('.sanketa')) {
      _snack('Please select a .sanketa backup file', error: true);
      return;
    }

    if (!mounted) return;
    _showRestoreDialog(filePath);
  }

  void _restoreFromList(BackupEntry b) => _showRestoreDialog(b.path);

  void _showRestoreDialog(String filePath) {
    final passCtrl = TextEditingController();
    final fileName = filePath.split('/').last.split('\\').last;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Restore Backup',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the passphrase for "$fileName". '
                'This will overwrite your current settings.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant)),
              ),
              const SizedBox(height: AppSpacing.md),
              _dialogField(passCtrl, 'Passphrase', obscure: true),
            ],
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
              final pass = passCtrl.text;
              if (pass.isEmpty) {
                _snack('Enter the passphrase', error: true);
                return;
              }
              Navigator.pop(ctx);
              _doImport(filePath, pass);
            },
            child: Text('Restore',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _doImport(String filePath, String passphrase) async {
    try {
      final ok = await _backup.importBackup(filePath, passphrase);
      if (!mounted) return;
      if (ok) {
        _snack('Backup restored — restart the app to apply');
      } else {
        _snack('Wrong passphrase or invalid backup', error: true);
      }
    } on Object {
      if (mounted) _snack('Restore failed', error: true);
    }
  }

  // ── helpers ─────────────────────────────────────────────────

  Widget _dialogField(TextEditingController c, String hint,
          {bool obscure = false}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              gfont(AppType.bodySm, color: hex(AppColors.outlineVariant)),
        ),
      );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
      backgroundColor: error
          ? hex(AppColors.error).withValues(alpha: 0.9)
          : hex(AppColors.surfaceContainerHigh),
    ));
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
