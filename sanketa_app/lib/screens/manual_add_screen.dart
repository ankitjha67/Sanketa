import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ManualAddScreen extends StatefulWidget {
  const ManualAddScreen({super.key});

  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  core.BrandFamily? _selectedBrand;
  bool _adding = false;

  static const _defaultPorts = <core.BrandFamily, int>{
    core.BrandFamily.androidTv: 6466,
    core.BrandFamily.tizen: 8002,
    core.BrandFamily.webOs: 3001,
    core.BrandFamily.roku: 8060,
    core.BrandFamily.bravia: 80,
    core.BrandFamily.fireTv: 5555,
    core.BrandFamily.vizio: 7345,
    core.BrandFamily.panasonic: 55000,
    core.BrandFamily.philips: 1925,
    core.BrandFamily.hisense: 36669,
    core.BrandFamily.appleTv: 7000,
    core.BrandFamily.dlna: 8080,
  };

  static const _brandLabels = <core.BrandFamily, String>{
    core.BrandFamily.androidTv: 'Android TV',
    core.BrandFamily.tizen: 'Samsung (Tizen)',
    core.BrandFamily.webOs: 'LG (webOS)',
    core.BrandFamily.roku: 'Roku',
    core.BrandFamily.bravia: 'Sony (Bravia)',
    core.BrandFamily.fireTv: 'Amazon Fire TV',
    core.BrandFamily.vizio: 'Vizio (SmartCast)',
    core.BrandFamily.panasonic: 'Panasonic',
    core.BrandFamily.philips: 'Philips',
    core.BrandFamily.hisense: 'Hisense (VIDAA)',
    core.BrandFamily.tcl: 'TCL',
    core.BrandFamily.appleTv: 'Apple TV',
    core.BrandFamily.dlna: 'DLNA / UPnP',
    core.BrandFamily.genericIr: 'IR Remote Only',
    core.BrandFamily.other: 'Other / Unknown',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Device',
          style: gfont(AppType.headlineMd,
              color: hex(AppColors.onSurface),
              size: 18,
              weight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: hex(AppColors.primaryContainer),
          unselectedLabelColor: hex(AppColors.onSurfaceVariant),
          indicatorColor: hex(AppColors.primaryContainer),
          labelStyle: gfont(AppType.bodySm, weight: FontWeight.w600),
          unselectedLabelStyle: gfont(AppType.bodySm),
          tabs: const [
            Tab(text: 'IP Address'),
            Tab(text: 'Brand'),
            Tab(text: 'QR Code'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: TabBarView(
            controller: _tab,
            children: [
              _ipTab(),
              _brandTab(),
              _qrTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ── IP Address tab ───────────────────────────────────────────

  Widget _ipTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Enter your TV\'s IP address'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Find this in your TV\'s Network Settings.',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.xl),
          _inputField(
            controller: _ipCtrl,
            label: 'IP Address',
            hint: '192.168.1.100',
            keyboard: TextInputType.url,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _inputField(
            controller: _portCtrl,
            label: 'Port (optional)',
            hint: _selectedBrand != null
                ? '${_defaultPorts[_selectedBrand] ?? "auto"}'
                : 'auto-detect',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.md),
          _inputField(
            controller: _nameCtrl,
            label: 'Display Name (optional)',
            hint: 'Living Room TV',
          ),
          const SizedBox(height: AppSpacing.md),
          _brandDropdown(),
          const SizedBox(height: AppSpacing.xl),
          _addButton(onTap: _addByIp),
        ],
      ),
    );
  }

  void _addByIp() {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    final port = int.tryParse(_portCtrl.text.trim());
    final name = _nameCtrl.text.trim();

    _doAdd(
      host: ip,
      port: port ?? (_selectedBrand != null ? _defaultPorts[_selectedBrand] : null),
      name: name.isNotEmpty ? name : null,
    );
  }

  // ── Brand tab ────────────────────────────────────────────────

  Widget _brandTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Select your TV brand'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We\'ll use the right protocol and default port.',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.xl),
          _brandDropdown(),
          const SizedBox(height: AppSpacing.md),
          _inputField(
            controller: _modelCtrl,
            label: 'Model (optional)',
            hint: 'UN55TU7000',
          ),
          const SizedBox(height: AppSpacing.md),
          _inputField(
            controller: _ipCtrl,
            label: 'IP Address',
            hint: '192.168.1.100',
            keyboard: TextInputType.url,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_selectedBrand != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color:
                      hex(AppColors.primaryContainer).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: hex(AppColors.primaryContainer)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Default port: ${_defaultPorts[_selectedBrand] ?? "none"}'
                      '${_protocolHint(_selectedBrand!) ?? ""}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primaryContainer)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          _addButton(onTap: _addByBrand),
        ],
      ),
    );
  }

  void _addByBrand() {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty || _selectedBrand == null) return;
    final model = _modelCtrl.text.trim();

    _doAdd(
      host: ip,
      port: _defaultPorts[_selectedBrand],
      name: model.isNotEmpty
          ? '${_brandLabels[_selectedBrand]} $model'
          : _brandLabels[_selectedBrand],
    );
  }

  // ── QR Code tab (placeholder) ────────────────────────────────

  Widget _qrTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 56,
              color: hex(AppColors.onSurfaceVariant).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'QR Code Pairing',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scan a QR code displayed on your TV to connect instantly. '
            'Some TVs show this in Settings → Remote & Accessories.',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodyMd,
                color: hex(AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Coming soon',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.tertiary), weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── shared widgets ───────────────────────────────────────────

  Widget _sectionHeader(String text) => Text(
        text,
        style: gfont(AppType.headlineMd,
            color: hex(AppColors.onSurface),
            size: 16,
            weight: FontWeight.w600),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant),
                weight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
            filled: true,
            fillColor: hex(AppColors.surfaceContainerHigh),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: hex(AppColors.primaryContainer)),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brand',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant),
                weight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<core.BrandFamily>(
              value: _selectedBrand,
              isExpanded: true,
              hint: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('Select brand',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.outline))),
              ),
              dropdownColor: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              icon: Icon(Icons.expand_more,
                  color: hex(AppColors.onSurfaceVariant)),
              items: core.BrandFamily.values.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(
                    _brandLabels[b] ?? b.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface)),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedBrand = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _adding ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _adding
              ? hex(AppColors.primaryContainer).withValues(alpha: 0.5)
              : hex(AppColors.primaryContainer),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Center(
          child: _adding
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: hex(AppColors.onPrimary),
                  ),
                )
              : Text(
                  'Add Device',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onPrimary),
                      weight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  String? _protocolHint(core.BrandFamily brand) {
    switch (brand) {
      case core.BrandFamily.androidTv:
        return ' • Android TV Remote v2';
      case core.BrandFamily.tizen:
        return ' • Samsung WebSocket';
      case core.BrandFamily.webOs:
        return ' • LG SSAP';
      case core.BrandFamily.roku:
        return ' • Roku ECP';
      case core.BrandFamily.bravia:
        return ' • Sony IRCC / REST';
      case core.BrandFamily.fireTv:
        return ' • ADB over network';
      case core.BrandFamily.vizio:
        return ' • SmartCast API';
      case core.BrandFamily.philips:
        return ' • JointSpace API';
      case core.BrandFamily.hisense:
        return ' • VIDAA MQTT';
      case core.BrandFamily.genericIr:
        return ' • Infrared blaster';
      default:
        return null;
    }
  }

  void _doAdd({required String host, int? port, String? name}) {
    setState(() => _adding = true);

    final c = RemoteScope.of(context);
    c.addManualDevice(host, port: port, name: name);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}
