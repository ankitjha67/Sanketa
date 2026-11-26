import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  String _partyCode = '';
  bool _hosting = false;
  bool _counting = false;
  int _countdown = 5;
  Timer? _timer;
  final _joinCtrl = TextEditingController();

  final _members = <(String, bool)>[
    ('You (Host)', true),
  ];

  static const _sampleNames = ['Alex', 'Sam', 'Jordan', 'Riley', 'Casey'];

  @override
  void dispose() {
    _timer?.cancel();
    _joinCtrl.dispose();
    super.dispose();
  }

  void _createParty() {
    final code = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      _partyCode = code;
      _hosting = true;
      _members.clear();
      _members.add(('You (Host)', true));
      final extra = 1 + Random().nextInt(3);
      for (var i = 0; i < extra; i++) {
        _members.add((_sampleNames[i], true));
      }
    });
  }

  void _joinParty() {
    if (_joinCtrl.text.trim().length != 6) return;
    setState(() {
      _partyCode = _joinCtrl.text.trim();
      _hosting = false;
      _members.clear();
      _members.add(('Host', true));
      _members.add(('You', true));
    });
    _joinCtrl.clear();
  }

  void _startCountdown() {
    setState(() {
      _counting = true;
      _countdown = 5;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown <= 1) {
        _timer?.cancel();
        setState(() => _counting = false);
        final rc = RemoteScope.of(context);
        rc.launch('Play');
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Play! Everyone starts watching now.'),
            duration: Duration(seconds: 2),
          ));
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _leaveParty() {
    _timer?.cancel();
    setState(() {
      _partyCode = '';
      _hosting = false;
      _counting = false;
      _members.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Watch Party',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_partyCode.isNotEmpty)
            GestureDetector(
              onTap: _leaveParty,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.exit_to_app, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_partyCode.isEmpty) ...[
            _heroCard(),
            const SizedBox(height: AppSpacing.md),
            _createSection(),
            const SizedBox(height: AppSpacing.md),
            _joinSection(),
          ] else ...[
            _partyView(),
            const SizedBox(height: AppSpacing.md),
            _membersList(),
            const SizedBox(height: AppSpacing.md),
            if (_counting) _countdownView() else _syncButton(),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.groups, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Watch Together',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 4),
            Text('Sync playback with friends and family on different TVs',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _createSection() => GestureDetector(
        onTap: _createParty,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 18, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Create Watch Party',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary), weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _joinSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join a Party',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _joinCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 14),
                    decoration: InputDecoration(
                      hintText: '6-digit code',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _joinParty,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hex(AppColors.secondary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(Icons.login, size: 20, color: hex(AppColors.secondary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _partyView() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(_hosting ? 'Your Party' : 'Joined Party',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _partyCode));
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('Code copied!')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_partyCode,
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.primary),
                            size: 24, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 16, color: hex(AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Share this code with others to join',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
      );

  Widget _membersList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Members (${_members.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: hex(AppColors.primary)),
                      const SizedBox(width: 10),
                      Text(m.$1,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface), size: 12)),
                      const Spacer(),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: hex(m.$2 ? AppColors.signalEmerald : AppColors.outline),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      );

  Widget _countdownView() => Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.alertAmber).withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text('$_countdown',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.alertAmber), size: 60, weight: FontWeight.w700)),
        ),
      );

  Widget _syncButton() => GestureDetector(
        onTap: _startCountdown,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 18, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Sync & Play',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
            ],
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
                'Create or join a watch party to sync playback with others. Share the 6-digit code, then hit Sync & Play when everyone is ready. All communication stays local.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
