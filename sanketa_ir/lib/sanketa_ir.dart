/// SANKETA infrared subsystem.
///
/// Pure-Dart IR encoding + codesets + an [IrControlAdapter] that puts IR behind
/// the same `ControlAdapter` contract as the network brands. The only native
/// dependency is the [IrTransmitter] seam (Android ConsumerIrManager), injected
/// from the app. Everything here is offline and testable (PRD FR-2, NFR-8).
library sanketa_ir;

export 'src/ac/ac_encoder.dart';
export 'src/ac/ac_state.dart';
export 'src/ac/coolix_ac_encoder.dart';
export 'src/ac/ir_ac_controller.dart';
export 'src/assist/assist_typer.dart';
export 'src/assist/keyboard_layout.dart';
export 'src/codesets/lg_tv.dart';
export 'src/codesets/panasonic_tv.dart';
export 'src/codesets/samsung_tv.dart';
export 'src/codesets/sony_tv.dart';
export 'src/ir_codec.dart';
export 'src/ir_codeset.dart';
export 'src/ir_control_adapter.dart';
export 'src/ir_signal.dart';
export 'src/ir_transmitter.dart';
export 'src/irdb/brand_map.dart';
export 'src/irdb/capture_session.dart';
export 'src/irdb/codeset_builder.dart';
export 'src/irdb/flipper_ir_parser.dart';
export 'src/irdb/irdb_catalog.dart';
export 'src/irdb/key_name_map.dart';
export 'src/irdb/kookong_key_map.dart';
export 'src/irdb/lirc_parser.dart';
export 'src/irdb/protocol_decoder.dart';
