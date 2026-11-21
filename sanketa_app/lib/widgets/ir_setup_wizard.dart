/// Guided setup for an IR-controlled device (FR-2.3).
///
/// A codeset becomes active only after the user confirms that its Power test
/// visibly worked on the target device.
library;

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/ir_device_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

void showIrSetupWizard(BuildContext context, RemoteController controller) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: hex(AppColors.surfaceContainerHigh),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    isScrollControlled: true,
    builder: (_) => _IrSetupWizard(controller: controller),
  );
}

class _IrSetupWizard extends StatefulWidget {
  const _IrSetupWizard({required this.controller});

  final RemoteController controller;

  @override
  State<_IrSetupWizard> createState() => _IrSetupWizardState();
}

class _IrSetupWizardState extends State<_IrSetupWizard> {
  String? _brand;
  int _candidateIndex = 0;
  bool _testing = false;
  bool _testSent = false;
  String? _testError;

  List<IrDeviceEntry> get _candidates => _brand == null
      ? const []
      : widget.controller.irService.byBrandName(
          _brand!,
          deviceType: core.DeviceType.tv,
        );

  IrDeviceEntry? get _candidate =>
      _candidates.isEmpty ? null : _candidates[_candidateIndex];

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.68,
    minChildSize: 0.45,
    maxChildSize: 0.9,
    expand: false,
    builder: (ctx, scrollController) => Column(
      children: [
        _handle(),
        _header(),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              if (!widget.controller.irHardwareChecked)
                _notice(
                  icon: Icons.sensors,
                  text: 'Checking this phone for an IR blaster…',
                  color: hex(AppColors.primaryContainer),
                )
              else if (!widget.controller.hasIrHardware)
                _notice(
                  icon: Icons.info_outline,
                  text: 'No IR blaster was detected on this phone. Power tests cannot be sent.',
                  color: hex(AppColors.error),
                ),
              const SizedBox(height: AppSpacing.md),
              if (_brand == null) _brandPicker() else _testStep(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _handle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: hex(AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      children: [
        if (_brand != null)
          IconButton(
            tooltip: 'Choose another brand',
            onPressed: () => setState(() {
              _brand = null;
              _candidateIndex = 0;
              _testSent = false;
              _testError = null;
            }),
            icon: const Icon(Icons.arrow_back),
          )
        else
          Icon(
            Icons.settings_remote,
            size: 22,
            color: hex(AppColors.primaryContainer),
          ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            _brand == null ? 'Add IR Remote' : 'Test your remote',
            style: gfont(
              AppType.headlineMd,
              color: hex(AppColors.onSurface),
              size: 16,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _brandPicker() {
    final brands = widget.controller.irService.availableBrandNames(
      deviceType: core.DeviceType.tv,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your TV brand. We’ll test a Power command before saving the remote.',
          style: gfont(AppType.bodySm, color: hex(AppColors.onSurfaceVariant)),
        ),
        const SizedBox(height: AppSpacing.md),
        ...brands.map((brand) {
          final entries = widget.controller.irService.byBrandName(
            brand,
            deviceType: core.DeviceType.tv,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _tile(
              title: brand,
              subtitle:
                  '${entries.length} available codeset${entries.length == 1 ? '' : 's'}',
              onTap: () => setState(() {
                _brand = brand;
                _candidateIndex = 0;
                _testSent = false;
                _testError = null;
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _testStep() {
    final candidate = _candidate;
    if (candidate == null) {
      return Text(
        'No codesets are available for this brand.',
        style: gfont(AppType.bodyMd, color: hex(AppColors.error)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Point the top of your phone at the TV, then tap Test Power.',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
        ),
        const SizedBox(height: AppSpacing.md),
        _tile(
          title: candidate.displayName,
          subtitle:
              'Code ${_candidateIndex + 1} of ${_candidates.length} · ${candidate.keyCount} keys',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const ValueKey('test-ir-power'),
          onPressed: _testing || !widget.controller.hasIrHardware
              ? null
              : () => _testPower(candidate),
          icon: _testing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.power_settings_new),
          label: Text(_testing ? 'Sending…' : 'Test Power'),
        ),
        if (_testError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _testError!,
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm, color: hex(AppColors.error)),
          ),
        ],
        if (_testSent) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Did the TV turn on or off?',
            textAlign: TextAlign.center,
            style: gfont(
              AppType.bodyMd,
              color: hex(AppColors.onSurface),
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: const ValueKey('confirm-ir-code'),
            onPressed: () async {
              await widget.controller.selectIrDevice(candidate);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Yes, it worked'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            key: const ValueKey('reject-ir-code'),
            onPressed: _tryNext,
            child: Text(
              _candidateIndex + 1 < _candidates.length
                  ? 'No, try next code'
                  : 'No, none of these worked',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _testPower(IrDeviceEntry candidate) async {
    setState(() {
      _testing = true;
      _testSent = false;
      _testError = null;
    });
    final result = await widget.controller.testIrDevice(candidate);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testSent = result.ok;
      if (!result.ok) {
        _testError = 'The phone could not send the IR test. Check the blaster and try again.';
      }
    });
  }

  void _tryNext() {
    if (_candidateIndex + 1 < _candidates.length) {
      setState(() {
        _candidateIndex++;
        _testSent = false;
        _testError = null;
      });
      return;
    }
    setState(() {
      _testSent = false;
      _testError = 'No available code matched this TV yet.';
    });
  }

  Widget _notice({
    required IconData icon,
    required String text,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: gfont(AppType.labelMonoSm, color: color)),
        ),
      ],
    ),
  );

  Widget _tile({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadii.md),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tv, size: 22, color: hex(AppColors.primaryContainer)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: gfont(
                    AppType.labelMonoSm,
                    color: hex(AppColors.outline),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: hex(AppColors.outlineVariant),
            ),
        ],
      ),
    ),
  );
}
