/// AcEncoder — one interface per AC protocol family, mirroring how the TV world
/// has one ControlAdapter per platform. Adding a manufacturer's AC is a bounded,
/// contract-only unit of work (NFR-14); Coolix is the first (see
/// `coolix_ac_encoder.dart`), with Gree/Daikin/Panasonic to follow.
library;

import '../ir_signal.dart';
import 'ac_state.dart';

abstract interface class AcEncoder {
  /// Protocol id, e.g. `coolix`.
  String get protocol;

  int get minTempC;
  int get maxTempC;

  /// Compile a full AC state into an emittable IR frame.
  IrSignal encode(AcState state);
}
