import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  group('CastSession', () {
    test('idle session is not active', () {
      expect(CastSession.idle.isActive, isFalse);
      expect(CastSession.idle.phase, CastPhase.idle);
      expect(CastSession.idle.fileName, isNull);
      expect(CastSession.idle.error, isNull);
    });

    test('loading session is active', () {
      const s = CastSession(phase: CastPhase.loading, fileName: 'video.mp4');
      expect(s.isActive, isTrue);
      expect(s.fileName, 'video.mp4');
    });

    test('playing session is active', () {
      const s = CastSession(phase: CastPhase.playing);
      expect(s.isActive, isTrue);
    });

    test('paused session is active', () {
      const s = CastSession(phase: CastPhase.paused);
      expect(s.isActive, isTrue);
    });

    test('error session is not active', () {
      const s = CastSession(phase: CastPhase.error, error: 'fail');
      expect(s.isActive, isFalse);
      expect(s.error, 'fail');
    });

    test('copyWith transitions phase and clears error', () {
      const s = CastSession(
        phase: CastPhase.loading,
        fileName: 'song.mp3',
        mimeType: 'audio/mpeg',
      );
      final playing = s.copyWith(phase: CastPhase.playing);
      expect(playing.phase, CastPhase.playing);
      expect(playing.fileName, 'song.mp3');
      expect(playing.mimeType, 'audio/mpeg');
      expect(playing.error, isNull);
    });

    test('copyWith sets error and preserves fileName', () {
      const s = CastSession(
        phase: CastPhase.playing,
        fileName: 'photo.jpg',
      );
      final err = s.copyWith(
        phase: CastPhase.error,
        error: 'renderer rejected',
      );
      expect(err.phase, CastPhase.error);
      expect(err.error, 'renderer rejected');
      expect(err.fileName, 'photo.jpg');
    });
  });

  group('CastResult', () {
    test('success', () {
      const r = CastResult.success();
      expect(r.ok, isTrue);
      expect(r.error, isNull);
    });

    test('failure carries error', () {
      const r = CastResult.failure('timeout');
      expect(r.ok, isFalse);
      expect(r.error, 'timeout');
    });
  });

  group('CapabilityMap.canCast', () {
    test('defaults to false', () {
      const cap = CapabilityMap(
        keys: {},
        textMode: TextInjectionMode.none,
      );
      expect(cap.canCast, isFalse);
    });

    test('can be set to true', () {
      const cap = CapabilityMap(
        keys: {},
        textMode: TextInjectionMode.none,
        canCast: true,
      );
      expect(cap.canCast, isTrue);
    });
  });
}
