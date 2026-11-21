/// Maps brand name strings from external IR databases to [BrandFamily].
///
/// Directory names in Flipper IRDB, LIRC, or user-entered brand names are
/// normalised here. Unknown brands default to [BrandFamily.genericIr].
library;

import 'package:sanketa_core/sanketa_core.dart';

/// Resolve a brand name string to a [BrandFamily].
BrandFamily resolveBrand(String name) {
  final norm = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), ' ');
  for (final entry in _brandAliases.entries) {
    if (entry.value.contains(norm)) return entry.key;
  }
  return BrandFamily.genericIr;
}

/// Map a Flipper IRDB top-level category directory to [DeviceType].
DeviceType resolveDeviceType(String category) {
  return tryResolveDeviceType(category) ?? DeviceType.tv;
}

/// Resolve a supported IRDB category, returning `null` for unrelated devices.
DeviceType? tryResolveDeviceType(String category) {
  final norm =
      category.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '_');
  return _deviceTypeMap[norm];
}

const _deviceTypeMap = <String, DeviceType>{
  'tvs': DeviceType.tv,
  'acs': DeviceType.airConditioner,
  'projectors': DeviceType.projector,
  'soundbars': DeviceType.soundbar,
  'speakers': DeviceType.soundbar,
  'audio_and_video_receivers': DeviceType.soundbar,
  'streaming_devices': DeviceType.streamingStick,
  'cable_boxes': DeviceType.setTopBox,
  'dvb_t': DeviceType.setTopBox,
  'tv_tuner': DeviceType.setTopBox,
  'dvd_players': DeviceType.mediaRenderer,
  'blu_ray': DeviceType.mediaRenderer,
  'cd_players': DeviceType.mediaRenderer,
  'monitors': DeviceType.tv,
  'digital_signs': DeviceType.tv,
};

const _brandAliases = <BrandFamily, Set<String>>{
  BrandFamily.bravia: {'sony', 'sony bravia'},
  BrandFamily.tizen: {'samsung'},
  BrandFamily.webOs: {'lg', 'lg electronics'},
  BrandFamily.roku: {'roku', 'tcl roku'},
  BrandFamily.fireTv: {'amazon', 'fire tv', 'amazon fire'},
  BrandFamily.vizio: {'vizio'},
  BrandFamily.panasonic: {'panasonic', 'national'},
  BrandFamily.philips: {'philips'},
  BrandFamily.hisense: {'hisense', 'vidaa'},
  BrandFamily.tcl: {'tcl'},
  BrandFamily.appleTv: {'apple', 'apple tv'},
  BrandFamily.androidTv: {
    'xiaomi',
    'mi',
    'nvidia',
    'shield',
    'chromecast',
    'google',
    'jvc',
    'sharp',
    'toshiba',
    'skyworth',
    'haier',
    'funai',
    'sanyo',
    'emerson',
    'insignia',
    'element',
    'westinghouse',
    'magnavox',
    'onn',
    'sylvania',
  },
};
