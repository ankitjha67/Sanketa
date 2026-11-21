import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

DiscoveredEndpoint _ep({
  DiscoverySource source = DiscoverySource.ssdp,
  String host = '192.168.1.50',
  int? port,
  String? usn,
  String? st,
  String? server,
  String? name,
}) =>
    DiscoveredEndpoint(
      source: source,
      host: host,
      port: port,
      usn: usn,
      searchTarget: st,
      server: server,
      friendlyName: name,
    );

void main() {
  group('EndpointClassifier', () {
    const c = EndpointClassifier();

    test('Roku ECP → roku with full badges', () {
      final r = c.classify(_ep(st: 'roku:ecp', server: 'Roku/9.4'));
      expect(r.brand, BrandFamily.roku);
      expect(r.adapterId, 'roku');
      expect(
          r.badges,
          containsAll(<CapabilityBadge>[
            CapabilityBadge.control,
            CapabilityBadge.keyboard,
            CapabilityBadge.cast,
          ]));
    });

    test('Android TV remote mDNS → android_tv, keyboard-capable', () {
      final r = c.classify(
          _ep(source: DiscoverySource.mdns, st: '_androidtvremote2._tcp'));
      expect(r.brand, BrandFamily.androidTv);
      expect(r.adapterId, 'android_tv');
      expect(r.badges, contains(CapabilityBadge.keyboard));
    });

    test('Google Cast mDNS → cast badge only', () {
      final r =
          c.classify(_ep(source: DiscoverySource.mdns, st: '_googlecast._tcp'));
      expect(r.badges, equals({CapabilityBadge.cast}));
    });

    test('Samsung server hint → tizen', () {
      final r = c.classify(_ep(server: 'SHP, UPnP/1.0, Samsung UPnP SDK/1.0'));
      expect(r.brand, BrandFamily.tizen);
    });

    test('LG webOS hint → webOs', () {
      final r = c.classify(_ep(server: 'WebOS/1.0 UPnP/1.0'));
      expect(r.brand, BrandFamily.webOs);
    });

    test('generic MediaRenderer → dlna, cast-only, render type', () {
      final r =
          c.classify(_ep(st: 'urn:schemas-upnp-org:device:MediaRenderer:1'));
      expect(r.brand, BrandFamily.dlna);
      expect(r.adapterId, 'dlna');
      expect(r.deviceType, DeviceType.mediaRenderer);
    });

    test('unknown service → other, not confident', () {
      final r = c.classify(
          _ep(st: 'urn:schemas-upnp-org:device:InternetGatewayDevice:1'));
      expect(r.brand, BrandFamily.other);
      expect(r.confident, isFalse);
    });
  });

  group('DeviceRegistry dedupe', () {
    test('same device via SSDP and mDNS collapses to one, badges unioned', () {
      final reg = DeviceRegistry();
      // SSDP sees Cast (cast badge) on host X; mDNS sees the Android TV remote
      // (control+keyboard) on the same host X.
      reg.ingest(_ep(
          host: '192.168.1.77',
          st: '_googlecast._tcp',
          source: DiscoverySource.mdns));
      reg.ingest(_ep(
          host: '192.168.1.77',
          st: '_androidtvremote2._tcp',
          source: DiscoverySource.mdns));

      expect(reg.devices, hasLength(1));
      final d = reg.devices.single;
      expect(d.device.host, '192.168.1.77');
      expect(
          d.badges,
          containsAll(<CapabilityBadge>[
            CapabilityBadge.cast,
            CapabilityBadge.control,
            CapabilityBadge.keyboard,
          ]));
      expect(d.sources, contains(DiscoverySource.mdns));
      expect(d.adapterId, 'android_tv'); // richer brand wins over cast-only
    });

    test('a confident brand is not overwritten by a later generic hit', () {
      final reg = DeviceRegistry();
      reg.ingest(_ep(host: '10.0.0.5', st: 'roku:ecp', server: 'Roku/9'));
      reg.ingest(_ep(
          host: '10.0.0.5',
          st: 'urn:schemas-upnp-org:device:InternetGatewayDevice:1'));
      expect(reg.devices.single.device.brand, BrandFamily.roku);
    });

    test('different hosts stay separate', () {
      final reg = DeviceRegistry();
      reg.ingest(_ep(host: '192.168.1.10', st: 'roku:ecp'));
      reg.ingest(_ep(host: '192.168.1.11', st: 'roku:ecp'));
      expect(reg.devices, hasLength(2));
    });
  });

  group('DiscoveryEngine', () {
    test('merges hits from multiple backends', () async {
      final engine = DiscoveryEngine(backends: [
        _FakeBackend(
            DiscoverySource.ssdp, [_ep(host: '192.168.1.10', st: 'roku:ecp')]),
        _FakeBackend(DiscoverySource.mdns, [
          _ep(
              host: '192.168.1.20',
              st: '_androidtvremote2._tcp',
              source: DiscoverySource.mdns),
        ]),
      ]);
      final result =
          await engine.scan(timeout: const Duration(milliseconds: 50));
      expect(result.devices, hasLength(2));
      expect(result.backendsRun, 2);
      expect(result.backendsFailed, 0);
      expect(result.apIsolationSuspected, isFalse);
    });

    test('one backend throwing does not abort the scan', () async {
      final engine = DiscoveryEngine(backends: [
        _ThrowingBackend(),
        _FakeBackend(
            DiscoverySource.ssdp, [_ep(host: '192.168.1.10', st: 'roku:ecp')]),
      ]);
      final result =
          await engine.scan(timeout: const Duration(milliseconds: 50));
      expect(result.devices, hasLength(1));
      expect(result.backendsFailed, 1);
    });

    test('empty result + reachable gateway ⇒ AP isolation suspected', () async {
      final engine = DiscoveryEngine(
        backends: [_FakeBackend(DiscoverySource.ssdp, const [])],
        gatewayReachable: () async => true,
      );
      final result =
          await engine.scan(timeout: const Duration(milliseconds: 50));
      expect(result.devices, isEmpty);
      expect(result.apIsolationSuspected, isTrue);
    });

    test('enforces the overall timeout and cancels a slow backend', () async {
      final engine = DiscoveryEngine(backends: [_SlowBackend()]);
      final stopwatch = Stopwatch()..start();

      final result = await engine.scan(
        timeout: const Duration(milliseconds: 30),
      );

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 200)));
      expect(result.devices, isEmpty);
      expect(result.backendsFailed, 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(engine.registry.devices, isEmpty);
    });

    test('a new scan clears devices that are no longer present', () async {
      final backend = _MutableBackend([
        _ep(host: '192.168.1.10', st: 'roku:ecp'),
      ]);
      final engine = DiscoveryEngine(backends: [backend]);
      expect((await engine.scan()).devices, hasLength(1));

      backend.items = [];
      expect((await engine.scan()).devices, isEmpty);
    });
  });
}

class _FakeBackend implements DiscoveryBackend {
  _FakeBackend(this._source, this._items);
  final DiscoverySource _source;
  final List<DiscoveredEndpoint> _items;

  @override
  DiscoverySource get source => _source;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) =>
      Stream.fromIterable(_items);
}

class _ThrowingBackend implements DiscoveryBackend {
  @override
  DiscoverySource get source => DiscoverySource.probe;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) =>
      Stream.error(StateError('no multicast route'));
}

class _SlowBackend implements DiscoveryBackend {
  @override
  DiscoverySource get source => DiscoverySource.probe;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield _ep(host: '192.168.1.99');
  }
}

class _MutableBackend implements DiscoveryBackend {
  _MutableBackend(this.items);

  List<DiscoveredEndpoint> items;

  @override
  DiscoverySource get source => DiscoverySource.ssdp;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) =>
      Stream.fromIterable(items);
}
