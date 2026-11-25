import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/custom_layout_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class CustomLayoutScreen extends StatefulWidget {
  const CustomLayoutScreen({super.key});

  @override
  State<CustomLayoutScreen> createState() => _CustomLayoutScreenState();
}

class _CustomLayoutScreenState extends State<CustomLayoutScreen> {
  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final ls = c.layoutService;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Custom Layouts',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: ls.layouts.isEmpty ? _empty() : _list(c, ls),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hex(AppColors.primaryContainer),
        onPressed: () => _showCreateDialog(c),
        child: Icon(Icons.add, color: hex(AppColors.onPrimaryContainer)),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize,
                size: 48,
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No custom layouts',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.sm),
            Text('Build your own remote button grid',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ],
        ),
      );

  Widget _list(RemoteController c, CustomLayoutService ls) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: ls.layouts.length,
      itemBuilder: (_, i) {
        final l = ls.layouts[i];
        final active = ls.activeIndex == i;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: panel(
            borderColor:
                active ? AppColors.primaryContainer : AppColors.outlineVariant,
            borderOpacity: active ? 0.6 : 0.3,
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.dashboard_customize,
                  size: 20, color: hex(AppColors.primaryContainer)),
            ),
            title: Text(l.name,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500)),
            subtitle: Text('${l.buttons.length} buttons, ${l.columns} cols',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (active) {
                      ls.clearActive();
                    } else {
                      ls.setActive(i);
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? hex(AppColors.primaryContainer).withValues(alpha: 0.2)
                          : hex(AppColors.surfaceContainer),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(active ? 'ACTIVE' : 'Use',
                        style: gfont(AppType.bodySm,
                            color: active
                                ? hex(AppColors.primaryContainer)
                                : hex(AppColors.onSurfaceVariant),
                            size: 11,
                            weight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: hex(AppColors.outlineVariant)),
                  onPressed: () {
                    ls.removeLayout(i);
                    setState(() {});
                  },
                ),
              ],
            ),
            onTap: () => _showLayoutPreview(c, l),
          ),
        );
      },
    );
  }

  void _showLayoutPreview(RemoteController c, RemoteLayout layout) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (_) => RemoteScope(
        controller: c,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: hex(AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(layout.name,
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 16,
                      weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: layout.columns,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.5,
                children: [
                  for (final btn in layout.buttons)
                    _layoutButton(c, btn),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layoutButton(RemoteController c, RemoteButton btn) {
    return GestureDetector(
      onTap: () => _executeButton(c, btn),
      child: Container(
        alignment: Alignment.center,
        decoration: panel(fill: AppColors.surfaceContainer, radius: AppRadii.md),
        child: Text(btn.label,
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurface), weight: FontWeight.w500)),
      ),
    );
  }

  void _executeButton(RemoteController c, RemoteButton btn) {
    switch (btn.action) {
      case 'key':
        final k = core.Key.values.firstWhere(
          (k) => k.name == btn.argument,
          orElse: () => core.Key.ok,
        );
        c.key(k);
      case 'power_on':
        c.power(true);
      case 'power_off':
        c.power(false);
      case 'source':
        if (btn.argument != null) c.setSource(btn.argument!);
      case 'launch':
        if (btn.argument != null) c.launch(btn.argument!);
    }
  }

  void _showCreateDialog(RemoteController c) {
    final nameCtrl = TextEditingController();
    final buttons = <RemoteButton>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLow),
          title: Text('New Layout',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface), size: 16)),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface)),
                    decoration: InputDecoration(
                      hintText: 'Layout name',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outlineVariant)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Add buttons:',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant))),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < buttons.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(buttons[i].label,
                                style: gfont(AppType.labelMonoSm,
                                    color: hex(AppColors.onSurface))),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setDlg(() => buttons.removeAt(i)),
                            child: Icon(Icons.close,
                                size: 14,
                                color: hex(AppColors.outlineVariant)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final e in _buttonTemplates)
                        _addBtn(e.$1, () => setDlg(() => buttons.add(
                            RemoteButton(
                                label: e.$1,
                                action: e.$2,
                                argument: e.$3)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style:
                      gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty && buttons.isNotEmpty) {
                  c.layoutService.addLayout(
                      RemoteLayout(name: name, buttons: buttons));
                  setState(() {});
                }
                Navigator.of(ctx).pop();
              },
              child: Text('Create',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primaryContainer),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static const _buttonTemplates = [
    ('Power On', 'power_on', null),
    ('Power Off', 'power_off', null),
    ('Home', 'key', 'home'),
    ('Back', 'key', 'back'),
    ('OK', 'key', 'ok'),
    ('Up', 'key', 'up'),
    ('Down', 'key', 'down'),
    ('Left', 'key', 'left'),
    ('Right', 'key', 'right'),
    ('Vol +', 'key', 'volumeUp'),
    ('Vol -', 'key', 'volumeDown'),
    ('Mute', 'key', 'mute'),
    ('HDMI 1', 'source', 'HDMI 1'),
    ('HDMI 2', 'source', 'HDMI 2'),
    ('Netflix', 'launch', 'NETFLIX'),
    ('YouTube', 'launch', 'YouTube'),
    ('Prime', 'launch', 'prime'),
    ('Disney+', 'launch', 'Disney+'),
  ];

  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainer),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), size: 11)),
        ),
      );
}
