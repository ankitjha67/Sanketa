import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _ThemeOption {
  _ThemeOption({required this.id, required this.name, required this.bg, required this.fg, required this.accent});
  final String id;
  final String name;
  final Color bg;
  final Color fg;
  final Color accent;
}

final _themes = <_ThemeOption>[
  _ThemeOption(id: 'dark', name: 'Dark', bg: const Color(0xFF121212), fg: const Color(0xFFE0E0E0), accent: const Color(0xFF7C4DFF)),
  _ThemeOption(id: 'light', name: 'Light', bg: const Color(0xFFF5F5F5), fg: const Color(0xFF212121), accent: const Color(0xFF6200EA)),
  _ThemeOption(id: 'amoled', name: 'AMOLED', bg: const Color(0xFF000000), fg: const Color(0xFFFFFFFF), accent: const Color(0xFF00E676)),
  _ThemeOption(id: 'ocean', name: 'Ocean', bg: const Color(0xFF0D1B2A), fg: const Color(0xFFE0E1DD), accent: const Color(0xFF48CAE4)),
  _ThemeOption(id: 'sunset', name: 'Sunset', bg: const Color(0xFF1A1423), fg: const Color(0xFFF0E6FF), accent: const Color(0xFFFF6B6B)),
  _ThemeOption(id: 'forest', name: 'Forest', bg: const Color(0xFF0B1D0E), fg: const Color(0xFFDCE8D6), accent: const Color(0xFF4CAF50)),
];

class RemoteThemesScreen extends StatefulWidget {
  const RemoteThemesScreen({super.key});

  @override
  State<RemoteThemesScreen> createState() => _RemoteThemesScreenState();
}

class _RemoteThemesScreenState extends State<RemoteThemesScreen> {
  String _selectedTheme = 'dark';
  int _accentHue = 270;
  bool _useCustomAccent = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_themes.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedTheme = j['selectedTheme'] as String? ?? 'dark';
        _accentHue = j['accentHue'] as int? ?? 270;
        _useCustomAccent = j['useCustomAccent'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'selectedTheme': _selectedTheme,
      'accentHue': _accentHue,
      'useCustomAccent': _useCustomAccent,
    }));
  }

  _ThemeOption get _current =>
      _themes.firstWhere((t) => t.id == _selectedTheme, orElse: () => _themes.first);

  Color get _effectiveAccent => _useCustomAccent
      ? HSLColor.fromAHSL(1, _accentHue.toDouble(), 0.7, 0.55).toColor()
      : _current.accent;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Themes',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _themePicker(),
          const SizedBox(height: AppSpacing.lg),
          _accentSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final theme = _current;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.fg.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text('Remote Preview',
              style: TextStyle(color: theme.fg, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _previewBtn(Icons.power_settings_new, theme),
              const SizedBox(width: 10),
              _previewBtn(Icons.volume_up, theme),
              const SizedBox(width: 10),
              _previewBtn(Icons.home, theme),
              const SizedBox(width: 10),
              _previewBtn(Icons.arrow_back, theme),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: _effectiveAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: _effectiveAccent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text('Accent Colour',
                  style: TextStyle(color: _effectiveAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBtn(IconData icon, _ThemeOption theme) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: theme.fg.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      border: Border.all(color: theme.fg.withValues(alpha: 0.15)),
    ),
    child: Icon(icon, size: 18, color: theme.fg.withValues(alpha: 0.8)),
  );

  Widget _themePicker() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _themes.map((t) {
            final active = _selectedTheme == t.id;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedTheme = t.id);
                _save();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: active ? hex(AppColors.primary) : t.fg.withValues(alpha: 0.2),
                    width: active ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(t.name,
                          style: TextStyle(color: t.fg, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    if (active)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.check_circle, size: 14, color: hex(AppColors.primary)),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _accentSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _useCustomAccent = !_useCustomAccent);
            _save();
          },
          child: Row(
            children: [
              Text('Custom Accent Colour',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              const Spacer(),
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(_useCustomAccent ? AppColors.primary : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: _useCustomAccent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hex(_useCustomAccent ? AppColors.onPrimary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_useCustomAccent) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _effectiveAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _effectiveAccent,
                    inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                    thumbColor: _effectiveAccent,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _accentHue.toDouble(),
                    min: 0,
                    max: 360,
                    divisions: 36,
                    onChanged: (v) {
                      setState(() => _accentHue = v.round());
                      _save();
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text('$_accentHue°',
                    textAlign: TextAlign.center,
                    style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final hue = i * 30.0;
                final color = HSLColor.fromAHSL(1, hue, 0.7, 0.55).toColor();
                return GestureDetector(
                  onTap: () {
                    setState(() => _accentHue = hue.round());
                    _save();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _accentHue == hue.round()
                          ? Border.all(color: hex(AppColors.onSurface), width: 2)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
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
            'Personalise the remote app appearance. Theme preferences are saved locally and do not affect the TV.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
