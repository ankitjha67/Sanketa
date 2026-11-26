import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class RemoteSharingScreen extends StatefulWidget {
  const RemoteSharingScreen({super.key});

  @override
  State<RemoteSharingScreen> createState() => _RemoteSharingScreenState();
}

class _RemoteSharingScreenState extends State<RemoteSharingScreen> {
  bool _hosting = false;
  bool _joined = false;
  String _code = '';
  final _codeCtrl = TextEditingController();

  static const _connectedUsers = <(String, String, IconData)>[
    ('Ankit', 'Host · Full control', Icons.admin_panel_settings),
    ('Guest 1', 'Volume & navigation', Icons.person),
  ];

  static const _permissions = [
    ('Full Control', 'All remote functions', true),
    ('Volume Only', 'Volume up/down and mute', false),
    ('Navigation', 'D-pad, OK, Back, Home', false),
    ('View Only', 'See what\'s playing', false),
  ];

  void _startHosting() {
    setState(() {
      _hosting = true;
      _code = '${(100000 + DateTime.now().microsecond % 900000)}';
    });
  }

  void _stopHosting() {
    setState(() {
      _hosting = false;
      _code = '';
    });
  }

  void _joinSession() {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Enter a 6-digit session code'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    setState(() => _joined = true);
  }

  void _leaveSession() {
    setState(() {
      _joined = false;
      _codeCtrl.clear();
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 1),
      ));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Sharing',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (!_hosting && !_joined) ...[
            _hostButton(),
            const SizedBox(height: AppSpacing.md),
            _joinSection(),
          ] else if (_hosting) ...[
            _activeSessionCard(),
            const SizedBox(height: AppSpacing.md),
            _connectedUsersCard(),
            const SizedBox(height: AppSpacing.md),
            _permissionsCard(),
          ] else ...[
            _joinedCard(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.group, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Share Your Remote',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Let family members control the TV from their own phones on the same network',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _hostButton() => GestureDetector(
        onTap: _startHosting,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_tethering,
                  size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Start Hosting Session',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _joinSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join a Session',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Enter the 6-digit code from the host',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 20,
                        weight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: gfont(AppType.headlineMd,
                          color: hex(AppColors.outline).withValues(alpha: 0.3),
                          size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _joinSession,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Text('Join',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _activeSessionCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering,
                    size: 20, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: 8),
                Text('Session Active',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Share this code:',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_code,
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.onSurface),
                            size: 28,
                            weight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Icon(Icons.copy,
                        size: 16, color: hex(AppColors.outline)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _stopHosting,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Stop Session',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600,
                        size: 11)),
              ),
            ),
          ],
        ),
      );

  Widget _connectedUsersCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected (${_connectedUsers.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._connectedUsers.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: hex(AppColors.primary)
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadii.full),
                        ),
                        child: Icon(u.$3,
                            size: 16, color: hex(AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.$1,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: FontWeight.w600,
                                  size: 12)),
                          Text(u.$2,
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline),
                                  size: 10)),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _permissionsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest Permissions',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._permissions.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        p.$3 ? Icons.check_circle : Icons.radio_button_off,
                        size: 16,
                        color: hex(p.$3
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$1,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 11)),
                            Text(p.$2,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline),
                                    size: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _joinedCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle,
                size: 40, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Connected to Session',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('You can now control the TV through the host',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _leaveSession,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Leave Session',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600,
                        size: 11)),
              ),
            ),
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
                'Share your TV remote with others on the same Wi-Fi network. The host controls permissions. All communication stays on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
