/// Codeset model — a device's key → IR command table (PRD FR-2.2).
///
/// A codeset is the normalized, on-device representation of one device's remote:
/// each logical [Key] maps to an [IrCommand] (protocol + params). The guided
/// matching wizard (FR-2.3) picks the right codeset per device; the packs
/// themselves are signed, versioned, geo-prioritized downloads (OD-6 governs
/// sourcing/licensing of the pack *content* — this model is source-agnostic).
library;

import 'package:sanketa_core/sanketa_core.dart';

import 'ir_signal.dart';

class IrCodeset {
  const IrCodeset({
    required this.id,
    required this.brand,
    required this.deviceType,
    required this.keys,
    this.name,
  });

  /// Stable pack-scoped id, e.g. `sony_tv_sirc_default`.
  final String id;
  final BrandFamily brand;
  final DeviceType deviceType;
  final String? name;

  /// The remote, as a map from canonical key to stored IR command.
  final Map<Key, IrCommand> keys;

  bool supports(Key key) => keys.containsKey(key);
  Set<Key> get supportedKeys => keys.keys.toSet();
}
