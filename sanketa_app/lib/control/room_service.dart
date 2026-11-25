import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class RoomProfile {
  RoomProfile({
    String? id,
    required this.name,
    this.volumePreset,
    this.defaultSource,
    this.defaultApp,
    this.layoutName,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  final String name;
  final int? volumePreset;
  final String? defaultSource;
  final String? defaultApp;
  final String? layoutName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (volumePreset != null) 'volumePreset': volumePreset,
        if (defaultSource != null) 'defaultSource': defaultSource,
        if (defaultApp != null) 'defaultApp': defaultApp,
        if (layoutName != null) 'layoutName': layoutName,
      };

  factory RoomProfile.fromJson(Map<String, dynamic> j) => RoomProfile(
        id: j['id'] as String?,
        name: j['name'] as String,
        volumePreset: (j['volumePreset'] as num?)?.toInt(),
        defaultSource: j['defaultSource'] as String?,
        defaultApp: j['defaultApp'] as String?,
        layoutName: j['layoutName'] as String?,
      );
}

class Room {
  Room({
    String? id,
    required this.name,
    this.icon = '📺',
    List<String>? deviceIds,
    List<RoomProfile>? profiles,
    this.activeProfileId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        deviceIds = deviceIds ?? [],
        profiles = profiles ?? [];

  final String id;
  String name;
  String icon;
  final List<String> deviceIds;
  final List<RoomProfile> profiles;
  String? activeProfileId;

  RoomProfile? get activeProfile => activeProfileId == null
      ? null
      : profiles.where((p) => p.id == activeProfileId).firstOrNull;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'deviceIds': deviceIds,
        'profiles': profiles.map((p) => p.toJson()).toList(),
        if (activeProfileId != null) 'activeProfileId': activeProfileId,
      };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String?,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? '📺',
        deviceIds: (j['deviceIds'] as List?)?.cast<String>() ?? [],
        profiles: (j['profiles'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map(RoomProfile.fromJson)
                .toList() ??
            [],
        activeProfileId: j['activeProfileId'] as String?,
      );
}

class RoomService extends ChangeNotifier {
  List<Room> rooms = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/rooms.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = await f.readAsString();
        rooms = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(Room.fromJson)
            .toList();
      }
    } on Object {
      // Best-effort.
    }
    if (rooms.isEmpty) {
      rooms.add(Room(name: 'Living Room', icon: '🛋️'));
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(rooms.map((r) => r.toJson()).toList()));
  }

  Room? roomById(String id) =>
      rooms.where((r) => r.id == id).firstOrNull;

  Room? roomForDevice(String deviceId) =>
      rooms.where((r) => r.deviceIds.contains(deviceId)).firstOrNull;

  void addRoom(String name, {String icon = '📺'}) {
    rooms.add(Room(name: name, icon: icon));
    _save();
    notifyListeners();
  }

  void updateRoom(String roomId, {String? name, String? icon}) {
    final room = roomById(roomId);
    if (room == null) return;
    if (name != null) room.name = name;
    if (icon != null) room.icon = icon;
    _save();
    notifyListeners();
  }

  void deleteRoom(String roomId) {
    rooms.removeWhere((r) => r.id == roomId);
    if (rooms.isEmpty) {
      rooms.add(Room(name: 'Living Room', icon: '🛋️'));
    }
    _save();
    notifyListeners();
  }

  void assignDevice(String deviceId, String roomId) {
    for (final r in rooms) {
      r.deviceIds.remove(deviceId);
    }
    final room = roomById(roomId);
    if (room != null && !room.deviceIds.contains(deviceId)) {
      room.deviceIds.add(deviceId);
    }
    _save();
    notifyListeners();
  }

  void removeDevice(String deviceId, String roomId) {
    roomById(roomId)?.deviceIds.remove(deviceId);
    _save();
    notifyListeners();
  }

  void addProfile(String roomId, RoomProfile profile) {
    final room = roomById(roomId);
    if (room == null) return;
    room.profiles.add(profile);
    _save();
    notifyListeners();
  }

  void deleteProfile(String roomId, String profileId) {
    final room = roomById(roomId);
    if (room == null) return;
    room.profiles.removeWhere((p) => p.id == profileId);
    if (room.activeProfileId == profileId) {
      room.activeProfileId = null;
    }
    _save();
    notifyListeners();
  }

  void setActiveProfile(String roomId, String? profileId) {
    final room = roomById(roomId);
    if (room == null) return;
    room.activeProfileId = profileId;
    _save();
    notifyListeners();
  }
}
