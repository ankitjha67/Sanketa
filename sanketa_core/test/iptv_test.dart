import 'package:test/test.dart';
import 'package:sanketa_core/sanketa_core.dart';

void main() {
  group('M3uParser', () {
    const parser = M3uParser();

    test('parses basic M3U with EXTINF', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1 tvg-id="CNN.us" tvg-name="CNN" tvg-logo="https://example.com/cnn.png" group-title="News",CNN International
https://stream.example.com/cnn/live.m3u8
#EXTINF:-1 tvg-id="BBC.uk" group-title="News",BBC World
https://stream.example.com/bbc/live.m3u8
''';
      final playlist = parser.parse(m3u);
      expect(playlist.channels, hasLength(2));
      expect(playlist.channels[0].name, 'CNN International');
      expect(playlist.channels[0].tvgId, 'CNN.us');
      expect(playlist.channels[0].tvgName, 'CNN');
      expect(playlist.channels[0].tvgLogo, 'https://example.com/cnn.png');
      expect(playlist.channels[0].groupTitle, 'News');
      expect(playlist.channels[0].url, 'https://stream.example.com/cnn/live.m3u8');
      expect(playlist.channels[1].name, 'BBC World');
    });

    test('extracts header tvg-url', () {
      const m3u = '#EXTM3U url-tvg="https://epg.example.com/guide.xml"\n'
          '#EXTINF:-1,Test\nhttps://s.example.com/test.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.tvgUrl, 'https://epg.example.com/guide.xml');
    });

    test('rejects non-http URLs', () {
      const m3u = '''
#EXTM3U
#EXTINF:-1,RTSP Stream
rtsp://stream.example.com/live
#EXTINF:-1,File Stream
file:///etc/passwd
#EXTINF:-1,UDP Stream
udp://239.1.1.1:1234
#EXTINF:-1,Good Stream
https://stream.example.com/good.m3u8
''';
      final playlist = parser.parse(m3u);
      expect(playlist.channels, hasLength(1));
      expect(playlist.channels[0].name, 'Good Stream');
    });

    test('rejects URLs with embedded credentials', () {
      const m3u = '#EXTM3U\n#EXTINF:-1,Bad\n'
          'https://user:pass@stream.example.com/live.m3u8\n'
          '#EXTINF:-1,Good\nhttps://stream.example.com/live.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels, hasLength(1));
      expect(playlist.channels[0].name, 'Good');
    });

    test('sanitizes channel names', () {
      const m3u = '#EXTM3U\n'
          '#EXTINF:-1,<script>alert("xss")</script>Channel\n'
          'https://stream.example.com/live.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels[0].name, contains('Channel'));
      expect(playlist.channels[0].name, isNot(contains('<script>')));
      expect(playlist.channels[0].name, isNot(contains('<')));
    });

    test('handles bare URLs without EXTINF', () {
      const m3u = '#EXTM3U\nhttps://stream.example.com/live.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels, hasLength(1));
      expect(playlist.channels[0].name, 'stream.example.com');
    });

    test('enforces maxChannels limit', () {
      final lines = StringBuffer('#EXTM3U\n');
      for (var i = 0; i < 100; i++) {
        lines.writeln('#EXTINF:-1,Channel $i');
        lines.writeln('https://stream.example.com/$i.m3u8');
      }
      const limited = M3uParser(maxChannels: 10);
      final playlist = limited.parse(lines.toString());
      expect(playlist.channels, hasLength(10));
    });

    test('filters NSFW by default', () {
      const m3u = '#EXTM3U\n'
          '#EXTINF:-1 group-title="XXX",Adult Channel\n'
          'https://stream.example.com/adult.m3u8\n'
          '#EXTINF:-1 group-title="News",CNN\n'
          'https://stream.example.com/cnn.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels, hasLength(1));
      expect(playlist.channels[0].name, 'CNN');
    });

    test('allows NSFW when enabled', () {
      const m3u = '#EXTM3U\n'
          '#EXTINF:-1 group-title="XXX",Adult Channel\n'
          'https://stream.example.com/adult.m3u8';
      const nsfwParser = M3uParser(allowNsfw: true);
      final playlist = nsfwParser.parse(m3u);
      expect(playlist.channels, hasLength(1));
      expect(playlist.channels[0].isNsfw, isTrue);
    });

    test('parses VLC options (user-agent, referrer)', () {
      const m3u = '#EXTM3U\n'
          '#EXTINF:-1,Stream\n'
          '#EXTVLCOPT:http-user-agent=CustomAgent/1.0\n'
          '#EXTVLCOPT:http-referrer=https://referer.example.com\n'
          'https://stream.example.com/live.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels[0].userAgent, 'CustomAgent/1.0');
      expect(playlist.channels[0].referrer, 'https://referer.example.com');
    });

    test('rejects non-http logo URLs', () {
      const m3u = '#EXTM3U\n'
          '#EXTINF:-1 tvg-logo="file:///etc/passwd",Bad Logo\n'
          'https://stream.example.com/live.m3u8';
      final playlist = parser.parse(m3u);
      expect(playlist.channels[0].tvgLogo, isNull);
    });

    test('handles empty input', () {
      expect(parser.parse('').channels, isEmpty);
    });
  });

  group('IptvPlaylist', () {
    test('groups channels by category', () {
      final playlist = IptvPlaylist(channels: [
        const IptvChannel(name: 'CNN', url: 'https://a.com/1', groupTitle: 'News'),
        const IptvChannel(name: 'BBC', url: 'https://a.com/2', groupTitle: 'News'),
        const IptvChannel(name: 'MTV', url: 'https://a.com/3', groupTitle: 'Music'),
        const IptvChannel(name: 'Bare', url: 'https://a.com/4'),
      ]);
      final cats = playlist.categories;
      expect(cats, hasLength(3));
      expect(cats[0].name, 'News');
      expect(cats[0].channels, hasLength(2));
      expect(cats[2].name, 'Uncategorized');
    });

    test('searches channels by name', () {
      final playlist = IptvPlaylist(channels: [
        const IptvChannel(name: 'CNN International', url: 'https://a.com/1'),
        const IptvChannel(name: 'BBC World', url: 'https://a.com/2'),
        const IptvChannel(name: 'CNBC', url: 'https://a.com/3'),
      ]);
      expect(playlist.search('cn'), hasLength(2)); // CNN, CNBC
      expect(playlist.search('bbc'), hasLength(1));
      expect(playlist.search(''), hasLength(3));
    });
  });

  group('IptvCatalog', () {
    test('all sources have valid HTTP URLs', () {
      for (final source in IptvCatalog.all) {
        expect(source.url, startsWith('https://'));
        expect(source.id, isNotEmpty);
        expect(source.name, isNotEmpty);
      }
    });

    test('findById returns correct source', () {
      final news = IptvCatalog.findById('cat_news');
      expect(news, isNotNull);
      expect(news!.name, 'News');
    });

    test('findById returns null for unknown id', () {
      expect(IptvCatalog.findById('nonexistent'), isNull);
    });

    test('search filters by name', () {
      final results = IptvCatalog.search('india');
      expect(results, isNotEmpty);
      expect(results.first.name, 'India');
    });

    test('byCategory, byCountry, byLanguage are non-empty', () {
      expect(IptvCatalog.byCategory, isNotEmpty);
      expect(IptvCatalog.byCountry, isNotEmpty);
      expect(IptvCatalog.byLanguage, isNotEmpty);
    });
  });

  group('HlsFilter', () {
    const filter = HlsFilter();

    test('passes through master playlists unchanged', () {
      const master = '#EXTM3U\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=800000\n'
          'low/index.m3u8\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=2000000\n'
          'high/index.m3u8';
      expect(filter.filterManifest(master), master);
    });

    test('strips CUE-OUT/CUE-IN ad segments', () {
      const manifest = '#EXTM3U\n'
          '#EXT-X-VERSION:3\n'
          '#EXT-X-TARGETDURATION:10\n'
          '#EXTINF:10.0,\n'
          'segment1.ts\n'
          '#EXT-X-CUE-OUT:DURATION=30\n'
          '#EXTINF:10.0,\n'
          'ad1.ts\n'
          '#EXTINF:10.0,\n'
          'ad2.ts\n'
          '#EXTINF:10.0,\n'
          'ad3.ts\n'
          '#EXT-X-CUE-IN\n'
          '#EXTINF:10.0,\n'
          'segment2.ts\n'
          '#EXT-X-ENDLIST';
      final filtered = filter.filterManifest(manifest);
      expect(filtered, contains('segment1.ts'));
      expect(filtered, contains('segment2.ts'));
      expect(filtered, isNot(contains('ad1.ts')));
      expect(filtered, isNot(contains('ad2.ts')));
      expect(filtered, isNot(contains('ad3.ts')));
      expect(filtered, contains('#EXT-X-DISCONTINUITY'));
    });

    test('strips SCTE-35 markers', () {
      const manifest = '#EXTM3U\n'
          '#EXTINF:10.0,\n'
          'seg1.ts\n'
          '#EXT-X-SCTE35:CUE=OUT\n'
          '#EXTINF:10.0,\n'
          'ad.ts\n'
          '#EXT-X-SCTE35:CUE=IN\n'
          '#EXTINF:10.0,\n'
          'seg2.ts';
      final filtered = filter.filterManifest(manifest);
      expect(filtered, contains('seg1.ts'));
      expect(filtered, contains('seg2.ts'));
      expect(filtered, isNot(contains('ad.ts')));
    });

    test('strips DATERANGE with SCTE35 attributes', () {
      const manifest = '#EXTM3U\n'
          '#EXTINF:10.0,\n'
          'seg1.ts\n'
          '#EXT-X-DATERANGE:ID="ad1",START-DATE="2024-01-01T00:00:00Z",SCTE35-OUT=0xFC30\n'
          '#EXTINF:10.0,\n'
          'ad.ts\n'
          '#EXT-X-DATERANGE:ID="ad1",END-ON-NEXT=YES,SCTE35-IN=0xFC30\n'
          '#EXTINF:10.0,\n'
          'seg2.ts';
      final filtered = filter.filterManifest(manifest);
      expect(filtered, contains('seg1.ts'));
      expect(filtered, contains('seg2.ts'));
      expect(filtered, isNot(contains('ad.ts')));
    });

    test('strips EXT-OATCLS ad segments', () {
      const manifest = '#EXTM3U\n'
          '#EXTINF:10.0,\n'
          'seg1.ts\n'
          '#EXT-OATCLS:com.example.Ad\n'
          '#EXTINF:10.0,\n'
          'ad.ts\n'
          '#EXTINF:10.0,\n'
          'seg2.ts';
      final filtered = filter.filterManifest(manifest);
      expect(filtered, contains('seg1.ts'));
      expect(filtered, contains('seg2.ts'));
      expect(filtered, isNot(contains('ad.ts')));
    });

    test('returns original when no ad markers present', () {
      const clean = '#EXTM3U\n'
          '#EXTINF:10.0,\n'
          'seg1.ts\n'
          '#EXTINF:10.0,\n'
          'seg2.ts';
      expect(filter.filterManifest(clean), clean);
    });

    test('hasAdMarkers detects markers', () {
      expect(filter.hasAdMarkers('#EXT-X-CUE-OUT:30'), isTrue);
      expect(filter.hasAdMarkers('#EXTINF:10,\nseg.ts'), isFalse);
    });

    test('handles empty input', () {
      expect(filter.filterManifest(''), '');
    });
  });
}
