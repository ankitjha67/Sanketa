import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../control/room_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late final RoomService _rooms;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = RemoteScope.of(context);
    if (_rooms != c.roomService) {
      _rooms.removeListener(_onChanged);
      _rooms = c.roomService;
      _rooms.addListener(_onChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    _rooms = RoomService(); // placeholder until didChangeDependencies
    _rooms.addListener(_onChanged);
  }

  @override
  void dispose() {
    _rooms.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
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
        title: Text('Rooms',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _showAddRoomDialog,
          ),
        ],
      ),
      body: !_rooms.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _rooms.rooms.length,
                  itemBuilder: (_, i) => _roomCard(_rooms.rooms[i]),
                ),
              ),
            ),
    );
  }

  Widget _roomCard(Room room) {
    final c = RemoteScope.of(context);
    final allDevices = c.discoveredDevices;
    final roomDevices = allDevices
        .where((d) => room.deviceIds.contains(d.device.host))
        .toList();
    final unassignedCount = allDevices
        .where((d) => _rooms.roomForDevice(d.device.host ?? '') == null)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room header
          GestureDetector(
            onTap: () => _showRoomDetail(room),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hex(AppColors.primaryContainer)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Center(
                      child: Text(room.icon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.name,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${room.deviceIds.length} device${room.deviceIds.length == 1 ? '' : 's'}'
                          '${room.activeProfile != null ? ' · ${room.activeProfile!.name}' : ''}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18, color: hex(AppColors.outlineVariant)),
                    color: hex(AppColors.surfaceContainerLow),
                    onSelected: (val) {
                      switch (val) {
                        case 'edit':
                          _showEditRoomDialog(room);
                        case 'profile':
                          _showAddProfileDialog(room);
                        case 'delete':
                          _rooms.deleteRoom(room.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit room',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface))),
                      ),
                      PopupMenuItem(
                        value: 'profile',
                        child: Text('Add profile',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface))),
                      ),
                      if (_rooms.rooms.length > 1)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete room',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.error))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Profiles row
          if (room.profiles.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.2))),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in room.profiles) ...[
                      GestureDetector(
                        onTap: () => _rooms.setActiveProfile(
                          room.id,
                          room.activeProfileId == p.id ? null : p.id,
                        ),
                        onLongPress: () => _rooms.deleteProfile(room.id, p.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: room.activeProfileId == p.id
                                ? hex(AppColors.primaryContainer)
                                    .withValues(alpha: 0.2)
                                : hex(AppColors.surfaceContainer),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: room.activeProfileId == p.id
                                  ? hex(AppColors.primaryContainer)
                                      .withValues(alpha: 0.5)
                                  : hex(AppColors.outlineVariant)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(p.name,
                              style: gfont(AppType.bodySm,
                                  color: room.activeProfileId == p.id
                                      ? hex(AppColors.primaryContainer)
                                      : hex(AppColors.onSurfaceVariant),
                                  size: 11,
                                  weight: room.activeProfileId == p.id
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),

          // Devices in this room
          if (roomDevices.isNotEmpty)
            ...roomDevices.map((d) => _deviceRow(c, d, room)),

          // Add device button
          if (unassignedCount > 0)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.2))),
              ),
              child: GestureDetector(
                onTap: () => _showAssignDeviceDialog(room),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 16, color: hex(AppColors.primaryContainer)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Add device',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.primaryContainer),
                              weight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deviceRow(
      RemoteController c, core.DiscoveredDevice d, Room room) {
    final isActive = c.selectedDevice?.device.host == d.device.host;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2))),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.tv,
              size: 18,
              color: hex(isActive
                  ? AppColors.primaryContainer
                  : AppColors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.device.friendlyName ?? d.device.host ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500),
                ),
                Text(d.device.brand.name,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          _quickControl(Icons.power_settings_new, () {
            if (isActive) c.power(false);
          }),
          _quickControl(Icons.volume_up, () {
            if (isActive) c.key(core.Key.volumeUp);
          }),
          _quickControl(Icons.volume_off, () {
            if (isActive) c.key(core.Key.mute);
          }),
          GestureDetector(
            onTap: () {
              _rooms.removeDevice(d.device.host ?? '', room.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.remove_circle_outline,
                  size: 16, color: hex(AppColors.outlineVariant)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickControl(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: hex(AppColors.onSurfaceVariant)),
        ),
      );

  void _showAddRoomDialog() {
    final nameCtrl = TextEditingController();
    var selectedIcon = '📺';
    const icons = ['📺', '🛋️', '🛏️', '🍳', '🎮', '📚', '🏠', '🎵'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLow),
          title: Text('New Room',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface), size: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Room name',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Icon',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: icons
                    .map((e) => GestureDetector(
                          onTap: () => setDlg(() => selectedIcon = e),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedIcon == e
                                  ? hex(AppColors.primaryContainer)
                                      .withValues(alpha: 0.2)
                                  : hex(AppColors.surfaceContainer),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: selectedIcon == e
                                    ? hex(AppColors.primaryContainer)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  _rooms.addRoom(name, icon: selectedIcon);
                }
                Navigator.pop(ctx);
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

  void _showEditRoomDialog(Room room) {
    final nameCtrl = TextEditingController(text: room.name);
    var selectedIcon = room.icon;
    const icons = ['📺', '🛋️', '🛏️', '🍳', '🎮', '📚', '🏠', '🎵'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLow),
          title: Text('Edit Room',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface), size: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Room name',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Icon',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: icons
                    .map((e) => GestureDetector(
                          onTap: () => setDlg(() => selectedIcon = e),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedIcon == e
                                  ? hex(AppColors.primaryContainer)
                                      .withValues(alpha: 0.2)
                                  : hex(AppColors.surfaceContainer),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: selectedIcon == e
                                    ? hex(AppColors.primaryContainer)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  _rooms.updateRoom(room.id,
                      name: name, icon: selectedIcon);
                }
                Navigator.pop(ctx);
              },
              child: Text('Save',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primaryContainer),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDeviceDialog(Room room) {
    final c = RemoteScope.of(context);
    final unassigned = c.discoveredDevices
        .where((d) => _rooms.roomForDevice(d.device.host ?? '') == null)
        .toList();

    if (unassigned.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Add Device to ${room.name}',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: unassigned
                .map((d) => ListTile(
                      dense: true,
                      leading: Icon(Icons.tv,
                          size: 20,
                          color: hex(AppColors.onSurfaceVariant)),
                      title: Text(
                        d.device.friendlyName ?? d.device.host ?? 'Unknown',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface)),
                      ),
                      subtitle: Text(d.device.brand.name,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      onTap: () {
                        _rooms.assignDevice(
                            d.device.host ?? '', room.id);
                        Navigator.pop(ctx);
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
        ],
      ),
    );
  }

  void _showAddProfileDialog(Room room) {
    final nameCtrl = TextEditingController();
    final volCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final appCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('New Profile for ${room.name}',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Profile name (e.g. "Movie Night")',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: volCtrl,
                keyboardType: TextInputType.number,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Volume preset (0–100)',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sourceCtrl,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Default source (e.g. "HDMI 1")',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: appCtrl,
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Default app (e.g. "Netflix")',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                ),
              ),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final vol = int.tryParse(volCtrl.text.trim());
                final src = sourceCtrl.text.trim();
                final app = appCtrl.text.trim();
                _rooms.addProfile(
                  room.id,
                  RoomProfile(
                    name: name,
                    volumePreset: vol,
                    defaultSource: src.isEmpty ? null : src,
                    defaultApp: app.isEmpty ? null : app,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text('Add',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showRoomDetail(Room room) {
    // Tap on room header navigates into it — reuse this screen with
    // a filtered view, or just scroll to the room (rooms are already
    // shown in-line with their devices, so this is a no-op).
  }
}
