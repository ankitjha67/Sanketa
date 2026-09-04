/// SANKETA brand control adapters.
///
/// Public surface of the `sanketa_adapters` package. Every export here is a
/// concrete [ControlAdapter] implementation. Callers construct the adapter for a
/// discovered device and then speak only the contract.
library sanketa_adapters;

export 'src/android_tv/android_tv_adapter.dart';
export 'src/android_tv/atv_channel.dart';
export 'src/android_tv/atv_pairing_session.dart';
export 'src/bravia/bravia_adapter.dart';
export 'src/common/ws_channel.dart';
export 'src/dial/dial_client.dart';
export 'src/dlna/dlna_adapter.dart';
export 'src/roku/roku_adapter.dart';
export 'src/tizen/tizen_adapter.dart';
export 'src/webos/webos_adapter.dart';
