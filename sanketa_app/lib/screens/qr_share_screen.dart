import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class QrShareScreen extends StatefulWidget {
  const QrShareScreen({super.key});

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  Map<String, dynamic>? _exportData;
  bool _loading = true;
  bool _includeProfiles = true;
  bool _includeChannels = true;
  bool _includeMappings = true;
  bool _includeLayouts = true;

  @override
  void initState() {
    super.initState();
    _gatherData();
  }

  Future<void> _gatherData() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final data = <String, dynamic>{
        'version': 1,
        'exported': DateTime.now().toIso8601String(),
      };

      final files = <(String, String)>[
        ('remote_profiles.json', 'profiles'),
        ('favourite_channels.json', 'channels'),
        ('button_mappings.json', 'mappings'),
        ('gesture_shortcuts.json', 'gestures'),
        ('night_mode.json', 'nightMode'),
        ('quick_text_templates.json', 'quickTexts'),
        ('hdmi_inputs.json', 'hdmiInputs'),
        ('scheduled_actions.json', 'schedules'),
        ('picture_settings.json', 'pictureSettings'),
        ('sound_settings.json', 'soundSettings'),
      ];

      for (final (filename, key) in files) {
        final f = File('${dir.path}/$filename');
        if (await f.exists()) {
          data[key] = jsonDecode(await f.readAsString());
        }
      }

      _exportData = data;
    } on Object {
      _exportData = {'version': 1, 'error': 'Could not read settings'};
    }
    if (mounted) setState(() => _loading = false);
  }

  String _buildSharePayload() {
    final payload = <String, dynamic>{
      'version': 1,
      'exported': DateTime.now().toIso8601String(),
    };
    if (_includeProfiles && _exportData?['profiles'] != null) {
      payload['profiles'] = _exportData!['profiles'];
    }
    if (_includeChannels && _exportData?['channels'] != null) {
      payload['channels'] = _exportData!['channels'];
    }
    if (_includeMappings) {
      if (_exportData?['mappings'] != null) {
        payload['mappings'] = _exportData!['mappings'];
      }
      if (_exportData?['gestures'] != null) {
        payload['gestures'] = _exportData!['gestures'];
      }
    }
    if (_includeLayouts) {
      if (_exportData?['nightMode'] != null) {
        payload['nightMode'] = _exportData!['nightMode'];
      }
      if (_exportData?['pictureSettings'] != null) {
        payload['pictureSettings'] = _exportData!['pictureSettings'];
      }
      if (_exportData?['soundSettings'] != null) {
        payload['soundSettings'] = _exportData!['soundSettings'];
      }
    }
    return jsonEncode(payload);
  }

  void _copyToClipboard() {
    final payload = _buildSharePayload();
    Clipboard.setData(ClipboardData(text: payload));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Configuration copied to clipboard'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  Future<void> _exportToFile() async {
    final payload = _buildSharePayload();
    final dir = await getApplicationSupportDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${exportDir.path}/sanketa_config_$timestamp.json');
    await file.writeAsString(payload);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Exported to ${file.path}'),
          duration: const Duration(seconds: 3),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  int _countItems() {
    var count = 0;
    if (_includeProfiles) count += (_exportData?['profiles'] as List?)?.length ?? 0;
    if (_includeChannels) count += (_exportData?['channels'] as List?)?.length ?? 0;
    if (_includeMappings) {
      count += (_exportData?['mappings'] as List?)?.length ?? 0;
      count += (_exportData?['gestures'] as List?)?.length ?? 0;
    }
    if (_includeLayouts) {
      if (_exportData?['nightMode'] != null) count++;
      if (_exportData?['pictureSettings'] != null) count++;
      if (_exportData?['soundSettings'] != null) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Share Setup',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _summaryCard(),
                const SizedBox(height: AppSpacing.lg),
                _selectionSection(),
                const SizedBox(height: AppSpacing.lg),
                _shareButtons(),
                const SizedBox(height: AppSpacing.lg),
                _importSection(),
                const SizedBox(height: AppSpacing.lg),
                _infoCard(),
              ],
            ),
    );
  }

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: panel(radius: AppRadii.lg, borderOpacity: 0.2),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.share, size: 28, color: hex(AppColors.primary)),
        ),
        const SizedBox(height: 12),
        Text('Share Your Setup',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '${_countItems()} items selected for sharing',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
        ),
      ],
    ),
  );

  Widget _selectionSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Include in Export',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _checkRow(Icons.people, 'Remote Profiles',
            '${(_exportData?['profiles'] as List?)?.length ?? 0} profiles',
            _includeProfiles, (v) => setState(() => _includeProfiles = v)),
        _checkRow(Icons.star, 'Favourite Channels',
            '${(_exportData?['channels'] as List?)?.length ?? 0} channels',
            _includeChannels, (v) => setState(() => _includeChannels = v)),
        _checkRow(Icons.tune, 'Button & Gesture Mappings',
            '${((_exportData?['mappings'] as List?)?.length ?? 0) + ((_exportData?['gestures'] as List?)?.length ?? 0)} mappings',
            _includeMappings, (v) => setState(() => _includeMappings = v)),
        _checkRow(Icons.settings, 'Settings & Presets',
            'Night mode, picture, sound',
            _includeLayouts, (v) => setState(() => _includeLayouts = v)),
      ],
    ),
  );

  Widget _checkRow(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(value ? AppColors.primary : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hex(value ? AppColors.primary : AppColors.outlineVariant),
                  ),
                ),
                child: value
                    ? Icon(Icons.check, size: 14, color: hex(AppColors.onPrimary))
                    : null,
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: hex(AppColors.outline)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
                    Text(subtitle,
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shareButtons() => Column(
    children: [
      GestureDetector(
        onTap: _copyToClipboard,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primaryContainer).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.copy, size: 16, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Copy to Clipboard',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _exportToFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.file_download, size: 16, color: hex(AppColors.onSurface)),
              const SizedBox(width: 8),
              Text('Export to File',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _importSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Import Configuration',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _importFromClipboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.content_paste, size: 16, color: hex(AppColors.outline)),
                const SizedBox(width: 10),
                Text('Import from Clipboard',
                    style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  void _importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Clipboard is empty'),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
          ));
      }
      return;
    }
    try {
      final config = jsonDecode(data.text!) as Map<String, dynamic>;
      if (config['version'] != 1) throw const FormatException('Unknown version');

      final dir = await getApplicationSupportDirectory();
      final mapping = <String, String>{
        'profiles': 'remote_profiles.json',
        'channels': 'favourite_channels.json',
        'mappings': 'button_mappings.json',
        'gestures': 'gesture_shortcuts.json',
        'nightMode': 'night_mode.json',
        'pictureSettings': 'picture_settings.json',
        'soundSettings': 'sound_settings.json',
        'quickTexts': 'quick_text_templates.json',
        'hdmiInputs': 'hdmi_inputs.json',
        'schedules': 'scheduled_actions.json',
      };

      var imported = 0;
      for (final entry in mapping.entries) {
        if (config.containsKey(entry.key)) {
          await File('${dir.path}/${entry.value}')
              .writeAsString(jsonEncode(config[entry.key]));
          imported++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Imported $imported configuration sections'),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
          ));
        _gatherData();
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Invalid configuration data on clipboard'),
            backgroundColor: hex(AppColors.error),
          ));
      }
    }
  }

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
            'Share your remote configuration with another phone. Export includes only your settings and preferences, never connection credentials or personal data.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
