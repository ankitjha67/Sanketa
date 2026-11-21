/// Endpoint classifier — turns a raw discovery hit into a brand guess, the
/// adapter that should control it, and the capability badges to show.
///
/// This is the "recognise any brand" brain. It reads only wire hints (mDNS
/// service type, SSDP ST/SERVER/LOCATION), never trusts a single vendor, and is
/// deliberately additive: teaching it a new signature is a one-line change and
/// touches no other code (mirrors the adapter philosophy, NFR-14).
library;

import '../model/capabilities.dart';
import '../model/device.dart';
import 'discovered_endpoint.dart';

/// The result of classifying one endpoint.
class Classification {
  const Classification({
    required this.brand,
    required this.badges,
    this.adapterId,
    this.deviceType = DeviceType.tv,
    this.confident = true,
  });

  final BrandFamily brand;
  final Set<CapabilityBadge> badges;
  final String? adapterId;
  final DeviceType deviceType;
  final bool confident;
}

class EndpointClassifier {
  const EndpointClassifier();

  // Badge shorthands.
  static const _control = CapabilityBadge.control;
  static const _keyboard = CapabilityBadge.keyboard;
  static const _cast = CapabilityBadge.cast;

  /// Full-remote platforms advertise control + keyboard + cast; cast-only or
  /// render-only endpoints advertise just cast.
  Classification classify(DiscoveredEndpoint e) {
    final st = (e.searchTarget ?? '').toLowerCase();
    final server = (e.server ?? '').toLowerCase();
    final hay = [
      st,
      server,
      (e.location ?? '').toLowerCase(),
      (e.friendlyName ?? '').toLowerCase(),
    ].join(' ');

    // --- Brand fingerprints first — a device's real brand takes precedence
    // over generic protocol classifications (e.g. a Sony BRAVIA advertising
    // AirPlay is still a BRAVIA, not an Apple TV). --------------------------
    final brandMatch = _matchBrand(hay);
    if (brandMatch != null) return brandMatch;

    // --- mDNS service types (generic protocol) -----------------------------
    if (st.contains('androidtvremote')) {
      return const Classification(
        brand: BrandFamily.androidTv,
        adapterId: 'android_tv',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (st.contains('_googlecast')) {
      return const Classification(
        brand: BrandFamily.androidTv,
        adapterId: 'cast',
        badges: {_cast},
      );
    }
    if (st.contains('_airplay') || st.contains('_raop')) {
      return const Classification(
        brand: BrandFamily.appleTv,
        badges: {_cast},
        confident: false,
      );
    }

    // --- Generic protocols (broadest, least specific) -----------------------
    if (st.contains('dial-multiscreen')) {
      // DIAL: app launch (YouTube/Netflix pairing). Brand unknown from DIAL alone.
      return const Classification(
        brand: BrandFamily.other,
        adapterId: 'dial',
        badges: {_cast},
        confident: false,
      );
    }
    if (st.contains('mediarenderer')) {
      return const Classification(
        brand: BrandFamily.dlna,
        adapterId: 'dlna',
        badges: {_cast},
        deviceType: DeviceType.mediaRenderer,
      );
    }

    // Unknown UPnP root / unrecognised service.
    return const Classification(
      brand: BrandFamily.other,
      badges: {},
      confident: false,
    );
  }

  Classification? _matchBrand(String hay) {
    if (hay.contains('roku')) {
      return const Classification(
        brand: BrandFamily.roku,
        adapterId: 'roku',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (hay.contains('samsung') || hay.contains('tizen')) {
      return const Classification(
        brand: BrandFamily.tizen,
        adapterId: 'tizen',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (hay.contains('webos') || hay.contains('lg electronics')) {
      return const Classification(
        brand: BrandFamily.webOs,
        adapterId: 'webos',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (hay.contains('bravia') || hay.contains('sony')) {
      return const Classification(
        brand: BrandFamily.bravia,
        adapterId: 'bravia',
        badges: {_control, _keyboard, _cast},
      );
    }
    if ((hay.contains('fire') && hay.contains('tv')) ||
        hay.contains('amzn-wplay') || hay.contains('aftm') ||
        hay.contains('amazon fire')) {
      return const Classification(
        brand: BrandFamily.fireTv,
        adapterId: 'fire_tv',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (hay.contains('vizio') || hay.contains('smartcast')) {
      return const Classification(
        brand: BrandFamily.vizio,
        adapterId: 'vizio',
        badges: {_control, _cast},
      );
    }
    if (hay.contains('viera') || hay.contains('panasonic')) {
      return const Classification(
        brand: BrandFamily.panasonic,
        adapterId: 'panasonic',
        badges: {_control},
      );
    }
    if (hay.contains('philips')) {
      return const Classification(
        brand: BrandFamily.philips,
        adapterId: 'philips',
        badges: {_control},
      );
    }
    if (hay.contains('vidaa') || hay.contains('hisense')) {
      return const Classification(
        brand: BrandFamily.hisense,
        adapterId: 'hisense',
        badges: {_control},
      );
    }
    if (hay.contains('haier')) {
      return const Classification(
        brand: BrandFamily.other,
        adapterId: 'android_tv',
        badges: {_control, _keyboard, _cast},
        confident: false,
      );
    }
    if (hay.contains('tcl')) {
      return const Classification(
        brand: BrandFamily.tcl,
        adapterId: 'android_tv',
        badges: {_control, _keyboard, _cast},
        confident: false,
      );
    }
    if (hay.contains('xiaomi') || hay.contains('mi tv') ||
        hay.contains('mi box') || hay.contains('mitv')) {
      return const Classification(
        brand: BrandFamily.androidTv,
        adapterId: 'android_tv',
        badges: {_control, _keyboard, _cast},
      );
    }
    if (hay.contains('mediatek') || hay.contains('mtk')) {
      return const Classification(
        brand: BrandFamily.androidTv,
        adapterId: 'android_tv',
        badges: {_control, _keyboard, _cast},
        confident: false,
      );
    }
    return null;
  }
}
