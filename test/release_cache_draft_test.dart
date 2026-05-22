import 'package:flutter_test/flutter_test.dart';
import 'package:neom_releases/data/release_cache_controller.dart';

void main() {
  group('ReleaseCacheDraft.canResume', () {
    test('initial state cannot be resumed (no progress)', () {
      final draft = ReleaseCacheDraft(ownerId: 'u');
      expect(draft.lastCompletedStep, equals(ReleaseUploadStep.initial));
      expect(draft.canResume, isFalse);
    });

    test('completed state cannot be resumed', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.completed,
      );
      expect(draft.canResume, isFalse);
    });

    test('failed state cannot be resumed', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.failed,
      );
      expect(draft.canResume, isFalse);
    });

    test('mid-flow recent draft CAN resume', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.coverUploaded,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(draft.canResume, isTrue);
    });

    test('draft older than 72 hours cannot resume (boundary)', () {
      final tooOld = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.coverUploaded,
        updatedAt: DateTime.now().subtract(const Duration(hours: 73)),
      );
      expect(tooOld.canResume, isFalse);
    });

    test('draft exactly 72h old: edge — current impl uses < 72', () {
      // Using subtract(72h) gives hoursSinceUpdate == 72 => 72 < 72 == false
      final at72 = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.coverUploaded,
        updatedAt: DateTime.now().subtract(const Duration(hours: 72, seconds: 1)),
      );
      expect(at72.canResume, isFalse);
    });

    test('every mid-step except completed/failed is resumable when fresh', () {
      final midSteps = ReleaseUploadStep.values.where((s) =>
          s != ReleaseUploadStep.initial &&
          s != ReleaseUploadStep.completed &&
          s != ReleaseUploadStep.failed);
      for (final step in midSteps) {
        final d = ReleaseCacheDraft(
          ownerId: 'u',
          lastCompletedStep: step,
          updatedAt: DateTime.now(),
        );
        expect(d.canResume, isTrue, reason: 'Step $step should be resumable');
      }
    });
  });

  group('ReleaseCacheDraft.progressDescription', () {
    test('returns a non-empty description for every step', () {
      for (final step in ReleaseUploadStep.values) {
        final d = ReleaseCacheDraft(
          ownerId: 'u',
          lastCompletedStep: step,
        );
        expect(d.progressDescription, isNotEmpty);
      }
    });

    test('itemsUploading shows current/total progress (1-indexed)', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.itemsUploading,
        currentItemIndex: 0,
        releaseItems: [],
      );
      // releaseItems empty, currentItemIndex 0 => "1/0" - documents quirk
      expect(draft.progressDescription, contains('1/0'));
    });

    test('failed includes error message', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.failed,
        errorMessage: 'network down',
      );
      expect(draft.progressDescription, contains('network down'));
    });

    test('failed without errorMessage shows "desconocido"', () {
      final draft = ReleaseCacheDraft(
        ownerId: 'u',
        lastCompletedStep: ReleaseUploadStep.failed,
      );
      expect(draft.progressDescription, contains('desconocido'));
    });
  });

  group('ReleaseCacheDraft serialization', () {
    test('round-trip preserves core fields', () {
      final original = ReleaseCacheDraft(
        ownerId: 'owner_42',
        lastCompletedStep: ReleaseUploadStep.coverUploaded,
        publishedYear: 2026,
        currentItemIndex: 3,
        isAutoPublished: true,
      );
      final json = original.toJson();
      final restored = ReleaseCacheDraft.fromJson(json);

      expect(restored.ownerId, equals('owner_42'));
      expect(restored.lastCompletedStep, equals(ReleaseUploadStep.coverUploaded));
      expect(restored.publishedYear, equals(2026));
      expect(restored.currentItemIndex, equals(3));
      expect(restored.isAutoPublished, isTrue);
    });

    test('default constructor auto-generates id', () {
      final a = ReleaseCacheDraft(ownerId: 'u');
      expect(a.id, isNotEmpty);
    });

    test('two drafts created back-to-back may have same id (timestamp ms)', () {
      // This documents a real risk: two near-simultaneous draft starts
      // could collide on millisecondsSinceEpoch.
      final a = ReleaseCacheDraft(ownerId: 'u1');
      final b = ReleaseCacheDraft(ownerId: 'u2');
      // Not asserting equality - just exercising. The point is to surface
      // the risk via this test's existence.
      expect(a.id, isNotEmpty);
      expect(b.id, isNotEmpty);
    });
  });

  group('ReleaseUploadStep monotonicity', () {
    test('step indexes are strictly increasing', () {
      final indexes = ReleaseUploadStep.values.map((s) => s.index).toList();
      for (int i = 1; i < indexes.length; i++) {
        expect(indexes[i], equals(indexes[i - 1] + 1));
      }
    });

    test('initial is at index 0', () {
      expect(ReleaseUploadStep.initial.index, equals(0));
    });

    test('failed is the last step', () {
      expect(ReleaseUploadStep.failed.index,
          equals(ReleaseUploadStep.values.length - 1));
    });
  });
}
