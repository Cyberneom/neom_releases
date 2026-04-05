import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/release_status.dart';
import 'package:neom_core/utils/enums/release_type.dart';

import 'package:neom_releases/data/release_cache_controller.dart';

/// ──────────────────────────────────────────────────────────────────
/// Test Suite: Release Upload Scenarios
///
/// Simulates three end-to-end upload flows:
///  1. EMXI — Single PDF file upload (book/document)
///  2. Gigmeout — EP with 3 MP3s from a rock band
///  3. Cyberneom — Single MP3 meditation audio
///
/// Each test validates: model creation → serialization → draft caching
/// → content type detection → slug generation → status transitions.
/// ──────────────────────────────────────────────────────────────────

void main() {
  // ════════════════════════════════════════════════════════════════
  // TEST 1: EMXI — Single PDF Upload
  // ════════════════════════════════════════════════════════════════
  group('EMXI — PDF Single Upload', () {
    late AppReleaseItem pdfRelease;
    late ReleaseCacheDraft draft;

    setUp(() {
      pdfRelease = AppReleaseItem(
        id: 'emxi_pdf_001',
        name: 'Guía de Producción Musical 2026',
        description: 'Manual completo de producción musical para artistas independientes. '
            'Cubre mezcla, mastering y distribución digital.',
        imgUrl: 'https://firebasestorage.googleapis.com/emxi/covers/guia-produccion.jpg',
        galleryUrls: [
          'https://firebasestorage.googleapis.com/emxi/gallery/owner-photo.jpg',
        ],
        previewUrl: 'https://firebasestorage.googleapis.com/emxi/files/guia-produccion-musical.pdf',
        duration: 245, // 245 pages
        type: ReleaseType.single,
        status: ReleaseStatus.pending, // EMXI has revision enabled
        mediaType: MediaItemType.pdf,
        ownerEmail: 'editor@emxi.org',
        ownerName: 'EMXI Editorial',
        ownerType: OwnerType.profile,
        categories: ['Producción Musical', 'Educación', 'Tecnología'],
        tags: ['produccion', 'mezcla', 'mastering', 'guia'],
        language: 'es',
        digitalPrice: Price(amount: 299.0, currency: AppCurrency.mxn),
        physicalPrice: Price(amount: 599.0, currency: AppCurrency.mxn),
        isRental: false,
        publishedYear: 2026,
        place: Place(
          name: 'EMXI Editorial',
          description: 'Editorial digital independiente',
        ),
        createdTime: DateTime(2026, 3, 10).millisecondsSinceEpoch,
        slug: 'guia-de-produccion-musical-2026',
        metaOwnerId: 'editor@emxi.org',
        metaOwner: 'EMXI Editorial',
      );

      draft = ReleaseCacheDraft(
        ownerId: 'profile_emxi_editor',
        lastCompletedStep: ReleaseUploadStep.infoSet,
        releaseType: ReleaseType.single,
        releaseItems: [pdfRelease],
        releaseFilePaths: ['/tmp/guia-produccion-musical.pdf'],
        coverImageLocalPath: '/tmp/guia-produccion-cover.jpg',
        isAutoPublished: false,
        publishedYear: 2026,
      );
    });

    test('PDF release item should have correct content type detection', () {
      expect(pdfRelease.isBookContent, isTrue,
          reason: 'PDF mediaType should be detected as book content');
      expect(pdfRelease.isAudioContent, isFalse,
          reason: 'PDF should NOT be detected as audio content');
    });

    test('PDF release should fallback to extension-based detection', () {
      // Create item WITHOUT mediaType — relies on file extension
      final noMediaType = AppReleaseItem(
        previewUrl: 'https://storage.com/files/document.pdf?token=abc123',
        mediaType: null,
      );
      expect(noMediaType.isBookContent, isTrue,
          reason: 'Should detect .pdf extension even with query params');
      expect(noMediaType.isAudioContent, isFalse);
    });

    test('PDF release should have pending status (EMXI revision enabled)', () {
      expect(pdfRelease.status, ReleaseStatus.pending);
    });

    test('PDF release should serialize and deserialize correctly', () {
      final json = pdfRelease.toJSON();
      final reconstructed = AppReleaseItem.fromJSON(json);

      expect(reconstructed.id, 'emxi_pdf_001');
      expect(reconstructed.name, 'Guía de Producción Musical 2026');
      expect(reconstructed.duration, 245);
      expect(reconstructed.type, ReleaseType.single);
      expect(reconstructed.status, ReleaseStatus.pending);
      expect(reconstructed.mediaType, MediaItemType.pdf);
      expect(reconstructed.ownerType, OwnerType.profile);
      expect(reconstructed.categories.length, 3);
      expect(reconstructed.categories.first, 'Producción Musical');
      expect(reconstructed.language, 'es');
      expect(reconstructed.slug, 'guia-de-produccion-musical-2026');
      expect(reconstructed.isRental, isFalse);
      expect(reconstructed.isSuspended, isFalse);
    });

    test('PDF release should preserve pricing through serialization', () {
      final json = pdfRelease.toJSON();
      final reconstructed = AppReleaseItem.fromJSON(json);

      expect(reconstructed.digitalPrice, isNotNull);
      expect(reconstructed.digitalPrice!.amount, 299.0);
      expect(reconstructed.digitalPrice!.currency, AppCurrency.mxn);
      expect(reconstructed.physicalPrice, isNotNull);
      expect(reconstructed.physicalPrice!.amount, 599.0);
    });

    test('Slug generation should produce clean URL-safe strings', () {
      expect(
        AppReleaseItem.generateSlug('Guía de Producción Musical 2026'),
        'guía-de-producción-musical-2026',
      );
      expect(
        AppReleaseItem.generateSlug('¡Hola Mundo! @#\$'),
        'hola-mundo-',
      );
      expect(
        AppReleaseItem.generateSlug('   Spaces   Everywhere   '),
        '-spaces-everywhere-',
      );
    });

    test('Draft should correctly cache and restore EMXI PDF upload state', () {
      final draftJson = draft.toJson();
      final restored = ReleaseCacheDraft.fromJson(draftJson);

      expect(restored.ownerId, 'profile_emxi_editor');
      expect(restored.lastCompletedStep, ReleaseUploadStep.infoSet);
      expect(restored.releaseType, ReleaseType.single);
      expect(restored.releaseItems.length, 1);
      expect(restored.releaseItems.first.name, 'Guía de Producción Musical 2026');
      expect(restored.releaseItems.first.mediaType, MediaItemType.pdf);
      expect(restored.releaseFilePaths, ['/tmp/guia-produccion-musical.pdf']);
      expect(restored.coverImageLocalPath, '/tmp/guia-produccion-cover.jpg');
      expect(restored.isAutoPublished, isFalse);
      expect(restored.publishedYear, 2026);
    });

    test('Draft should be resumable within 72 hours', () {
      expect(draft.canResume, isTrue,
          reason: 'Fresh draft with infoSet step should be resumable');
    });

    test('Draft progress description should match step', () {
      expect(draft.progressDescription, 'Información de publicación lista');
    });

    test('Draft at initial step should NOT be resumable', () {
      final initialDraft = ReleaseCacheDraft(
        ownerId: 'profile_emxi_editor',
        lastCompletedStep: ReleaseUploadStep.initial,
      );
      expect(initialDraft.canResume, isFalse,
          reason: 'No meaningful progress at initial step');
    });

    test('Completed draft should NOT be resumable', () {
      final completedDraft = ReleaseCacheDraft(
        ownerId: 'profile_emxi_editor',
        lastCompletedStep: ReleaseUploadStep.completed,
      );
      expect(completedDraft.canResume, isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 2: Gigmeout — 3 MP3s Rock Band EP Upload
  // ════════════════════════════════════════════════════════════════
  group('Gigmeout — Rock Band EP (3 MP3s)', () {
    late List<AppReleaseItem> tracks;
    late Itemlist epItemlist;
    late ReleaseCacheDraft draft;

    setUp(() {
      // EP Itemlist (album container)
      epItemlist = Itemlist(
        name: 'Noches Eléctricas EP',
        description: 'EP debut de Los Voltios — 3 tracks de rock alternativo grabados en vivo.',
      );

      // Track 1
      final track1 = AppReleaseItem(
        id: 'gig_track_001',
        name: 'Circuito Roto',
        description: 'Primer single del EP. Rock alternativo con influencias de post-punk.',
        imgUrl: 'https://firebasestorage.googleapis.com/gigmeout/covers/noches-electricas.jpg',
        previewUrl: 'https://firebasestorage.googleapis.com/gigmeout/tracks/circuito-roto.mp3',
        duration: 234, // 3:54
        type: ReleaseType.ep,
        status: ReleaseStatus.publish,
        mediaType: MediaItemType.song,
        ownerEmail: 'losvoltios@gigmeout.com',
        ownerName: 'Los Voltios',
        ownerType: OwnerType.band,
        categories: ['Rock Alternativo', 'Post-Punk'],
        instruments: ['Guitarra Eléctrica', 'Bajo', 'Batería', 'Voz'],
        language: 'es',
        lyrics: 'Cruzo la ciudad bajo el voltaje...',
        digitalPrice: Price(amount: 15.0, currency: AppCurrency.mxn),
        isRental: true,
        createdTime: DateTime(2026, 3, 10).millisecondsSinceEpoch,
        slug: 'circuito-roto',
        metaId: 'itemlist_noches_electricas',
        metaName: 'Noches Eléctricas EP',
        metaOwnerId: 'losvoltios@gigmeout.com',
        metaOwner: 'Los Voltios',
        featInternalArtists: {'artist_id_bass': 'Memo (Bajo)'},
      );

      // Track 2
      final track2 = AppReleaseItem(
        id: 'gig_track_002',
        name: 'Señales de Humo',
        description: 'Balada eléctrica con arreglos de sintetizador.',
        imgUrl: 'https://firebasestorage.googleapis.com/gigmeout/covers/noches-electricas.jpg',
        previewUrl: 'https://firebasestorage.googleapis.com/gigmeout/tracks/senales-de-humo.mp3',
        duration: 287, // 4:47
        type: ReleaseType.ep,
        status: ReleaseStatus.publish,
        mediaType: MediaItemType.song,
        ownerEmail: 'losvoltios@gigmeout.com',
        ownerName: 'Los Voltios',
        ownerType: OwnerType.band,
        categories: ['Rock Alternativo', 'Indie'],
        instruments: ['Guitarra Eléctrica', 'Sintetizador', 'Batería', 'Voz'],
        language: 'es',
        digitalPrice: Price(amount: 15.0, currency: AppCurrency.mxn),
        isRental: true,
        createdTime: DateTime(2026, 3, 10).millisecondsSinceEpoch,
        slug: 'senales-de-humo',
        metaId: 'itemlist_noches_electricas',
        metaName: 'Noches Eléctricas EP',
        metaOwnerId: 'losvoltios@gigmeout.com',
        metaOwner: 'Los Voltios',
      );

      // Track 3
      final track3 = AppReleaseItem(
        id: 'gig_track_003',
        name: 'Último Amplificador',
        description: 'Cierre del EP — rock pesado con solo de guitarra extendido.',
        imgUrl: 'https://firebasestorage.googleapis.com/gigmeout/covers/noches-electricas.jpg',
        previewUrl: 'https://firebasestorage.googleapis.com/gigmeout/tracks/ultimo-amplificador.mp3',
        duration: 312, // 5:12
        type: ReleaseType.ep,
        status: ReleaseStatus.publish,
        mediaType: MediaItemType.song,
        ownerEmail: 'losvoltios@gigmeout.com',
        ownerName: 'Los Voltios',
        ownerType: OwnerType.band,
        categories: ['Rock Alternativo', 'Rock Pesado'],
        instruments: ['Guitarra Eléctrica', 'Bajo', 'Batería', 'Voz'],
        language: 'es',
        lyrics: 'El último amplificador enciende la noche...',
        digitalPrice: Price(amount: 15.0, currency: AppCurrency.mxn),
        isRental: true,
        createdTime: DateTime(2026, 3, 10).millisecondsSinceEpoch,
        slug: 'ultimo-amplificador',
        metaId: 'itemlist_noches_electricas',
        metaName: 'Noches Eléctricas EP',
        metaOwnerId: 'losvoltios@gigmeout.com',
        metaOwner: 'Los Voltios',
        externalArtists: ['DJ Sombra (remix)'],
      );

      tracks = [track1, track2, track3];

      draft = ReleaseCacheDraft(
        ownerId: 'profile_los_voltios',
        lastCompletedStep: ReleaseUploadStep.itemsUploading,
        releaseType: ReleaseType.ep,
        itemlist: epItemlist,
        releaseItems: tracks,
        releaseFilePaths: [
          '/tmp/circuito-roto.mp3',
          '/tmp/senales-de-humo.mp3',
          '/tmp/ultimo-amplificador.mp3',
        ],
        coverImageLocalPath: '/tmp/noches-electricas-cover.jpg',
        coverImageRemoteUrl: 'https://firebasestorage.googleapis.com/gigmeout/covers/noches-electricas.jpg',
        isAutoPublished: true,
        currentItemIndex: 1, // Failed on track 2 — resume from here
      );
    });

    test('All 3 tracks should be detected as audio content', () {
      for (final track in tracks) {
        expect(track.isAudioContent, isTrue,
            reason: '${track.name} should be audio (MediaItemType.song)');
        expect(track.isBookContent, isFalse,
            reason: '${track.name} should NOT be book content');
      }
    });

    test('Audio detection should work via file extension fallback', () {
      final noType = AppReleaseItem(
        previewUrl: 'https://storage.com/tracks/song.mp3?alt=media&token=xyz',
        mediaType: null,
      );
      expect(noType.isAudioContent, isTrue,
          reason: 'Should detect .mp3 extension even with Firebase query params');
      expect(noType.isBookContent, isFalse);
    });

    test('All tracks should share the same band owner', () {
      for (final track in tracks) {
        expect(track.ownerType, OwnerType.band);
        expect(track.ownerName, 'Los Voltios');
        expect(track.ownerEmail, 'losvoltios@gigmeout.com');
      }
    });

    test('All tracks should reference the same EP itemlist', () {
      for (final track in tracks) {
        expect(track.type, ReleaseType.ep);
        expect(track.metaId, 'itemlist_noches_electricas');
        expect(track.metaName, 'Noches Eléctricas EP');
      }
    });

    test('EP should have publish status (Gigmeout auto-publish)', () {
      for (final track in tracks) {
        expect(track.status, ReleaseStatus.publish);
      }
    });

    test('Track durations should be valid and varied', () {
      expect(tracks[0].duration, 234); // 3:54
      expect(tracks[1].duration, 287); // 4:47
      expect(tracks[2].duration, 312); // 5:12

      final totalDuration = tracks.fold<int>(0, (sum, t) => sum + t.duration);
      expect(totalDuration, 833); // 13:53 total EP
      expect(totalDuration, greaterThan(600),
          reason: 'EP should be at least 10 minutes');
    });

    test('Each track should serialize and deserialize independently', () {
      for (int i = 0; i < tracks.length; i++) {
        final json = tracks[i].toJSON();
        final restored = AppReleaseItem.fromJSON(json);

        expect(restored.id, tracks[i].id, reason: 'Track ${i + 1} ID mismatch');
        expect(restored.name, tracks[i].name, reason: 'Track ${i + 1} name mismatch');
        expect(restored.duration, tracks[i].duration);
        expect(restored.type, ReleaseType.ep);
        expect(restored.mediaType, MediaItemType.song);
        expect(restored.ownerType, OwnerType.band);
        expect(restored.slug, tracks[i].slug);
        expect(restored.instruments, isNotNull);
        expect(restored.instruments!.contains('Batería'), isTrue,
            reason: 'Track ${i + 1} should include drums');
      }
    });

    test('Track with featured artists should preserve the map', () {
      final json = tracks[0].toJSON();
      final restored = AppReleaseItem.fromJSON(json);

      expect(restored.featInternalArtists, isNotNull);
      expect(restored.featInternalArtists!['artist_id_bass'], 'Memo (Bajo)');
    });

    test('Track with external artists should preserve the list', () {
      final json = tracks[2].toJSON();
      final restored = AppReleaseItem.fromJSON(json);

      expect(restored.externalArtists, isNotNull);
      expect(restored.externalArtists!.length, 1);
      expect(restored.externalArtists!.first, 'DJ Sombra (remix)');
    });

    test('Draft should correctly track multi-item upload progress', () {
      expect(draft.releaseType, ReleaseType.ep);
      expect(draft.releaseItems.length, 3);
      expect(draft.releaseFilePaths.length, 3);
      expect(draft.currentItemIndex, 1,
          reason: 'Should resume from track 2 (index 1)');
      expect(draft.lastCompletedStep, ReleaseUploadStep.itemsUploading);
    });

    test('Draft with cover already uploaded should preserve remote URL', () {
      expect(draft.coverImageRemoteUrl, isNotNull);
      expect(draft.coverImageRemoteUrl,
          'https://firebasestorage.googleapis.com/gigmeout/covers/noches-electricas.jpg');
    });

    test('Multi-item draft should serialize and restore all tracks', () {
      final draftJson = draft.toJson();
      final restored = ReleaseCacheDraft.fromJson(draftJson);

      expect(restored.releaseItems.length, 3);
      expect(restored.releaseItems[0].name, 'Circuito Roto');
      expect(restored.releaseItems[1].name, 'Señales de Humo');
      expect(restored.releaseItems[2].name, 'Último Amplificador');
      expect(restored.currentItemIndex, 1);
      expect(restored.isAutoPublished, isTrue);
      expect(restored.itemlist, isNotNull);
    });

    test('Draft in mid-upload should be resumable', () {
      expect(draft.canResume, isTrue,
          reason: 'itemsUploading step is mid-progress and fresh');
      expect(draft.progressDescription, contains('Subiendo archivos'));
      expect(draft.progressDescription, contains('2/3'),
          reason: 'Should show current item = index+1 of total');
    });

    test('Slug generation for Spanish rock titles', () {
      expect(AppReleaseItem.generateSlug('Circuito Roto'), 'circuito-roto');
      expect(AppReleaseItem.generateSlug('Señales de Humo'), 'señales-de-humo');
      expect(AppReleaseItem.generateSlug('Último Amplificador'), 'último-amplificador');
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 3: Cyberneom — Meditation Audio (1 MP3)
  // ════════════════════════════════════════════════════════════════
  group('Cyberneom — Meditation Audio (1 MP3)', () {
    late AppReleaseItem meditationRelease;
    late ReleaseCacheDraft draft;

    setUp(() {
      meditationRelease = AppReleaseItem(
        id: 'cyber_med_001',
        name: 'Ondas Theta: Sueño Profundo 432Hz',
        description: 'Sesión de meditación con frecuencias binaurales theta (4-8Hz) '
            'sintonizadas a 432Hz para inducir sueño profundo y reparador. '
            'Duración: 45 minutos.',
        imgUrl: 'https://firebasestorage.googleapis.com/cyberneom/covers/theta-sueno.jpg',
        previewUrl: 'https://firebasestorage.googleapis.com/cyberneom/audio/ondas-theta-sueno-profundo.mp3',
        duration: 2700, // 45 minutes
        type: ReleaseType.single,
        status: ReleaseStatus.publish,
        mediaType: MediaItemType.binaural,
        ownerEmail: 'creator@cyberneom.com',
        ownerName: 'NeomSound Lab',
        ownerType: OwnerType.profile,
        categories: ['Binaural', 'Meditación', 'Sueño'],
        tags: ['theta', '432hz', 'sueño', 'binaural', 'relajación'],
        language: 'es',
        digitalPrice: Price(amount: 0.0, currency: AppCurrency.mxn), // Free
        isRental: true, // Included in membership
        createdTime: DateTime(2026, 3, 10).millisecondsSinceEpoch,
        slug: 'ondas-theta-sueno-profundo-432hz',
      );

      draft = ReleaseCacheDraft(
        ownerId: 'profile_neomsound_lab',
        lastCompletedStep: ReleaseUploadStep.coverUploaded,
        releaseType: ReleaseType.single,
        releaseItems: [meditationRelease],
        releaseFilePaths: ['/tmp/ondas-theta-sueno-profundo.mp3'],
        coverImageLocalPath: '/tmp/theta-sueno-cover.jpg',
        coverImageRemoteUrl: 'https://firebasestorage.googleapis.com/cyberneom/covers/theta-sueno.jpg',
        isAutoPublished: true,
      );
    });

    test('Binaural meditation should be detected as audio content', () {
      expect(meditationRelease.isAudioContent, isTrue,
          reason: 'MediaItemType.binaural should be audio content');
      expect(meditationRelease.isBookContent, isFalse);
    });

    test('All Cyberneom audio types should be detected as audio', () {
      final types = [
        MediaItemType.binaural,
        MediaItemType.frequency,
        MediaItemType.nature,
        MediaItemType.neomPreset,
      ];

      for (final type in types) {
        final item = AppReleaseItem(mediaType: type);
        expect(item.isAudioContent, isTrue,
            reason: '${type.name} should be audio content');
        expect(item.isBookContent, isFalse,
            reason: '${type.name} should NOT be book content');
      }
    });

    test('Meditation audio should have correct long duration', () {
      expect(meditationRelease.duration, 2700); // 45 min
      expect(meditationRelease.duration, greaterThan(1800),
          reason: 'Meditation sessions are typically >30 min');
    });

    test('Meditation should be a single (not EP/album)', () {
      expect(meditationRelease.type, ReleaseType.single);
    });

    test('Meditation should be free and rental-eligible', () {
      expect(meditationRelease.digitalPrice!.amount, 0.0);
      expect(meditationRelease.isRental, isTrue,
          reason: 'Meditation content should be included in membership');
    });

    test('Meditation release should serialize and deserialize fully', () {
      final json = meditationRelease.toJSON();
      final restored = AppReleaseItem.fromJSON(json);

      expect(restored.id, 'cyber_med_001');
      expect(restored.name, 'Ondas Theta: Sueño Profundo 432Hz');
      expect(restored.duration, 2700);
      expect(restored.type, ReleaseType.single);
      expect(restored.status, ReleaseStatus.publish);
      expect(restored.mediaType, MediaItemType.binaural);
      expect(restored.ownerType, OwnerType.profile);
      expect(restored.ownerName, 'NeomSound Lab');
      expect(restored.categories.length, 3);
      expect(restored.categories, contains('Binaural'));
      expect(restored.tags, isNotNull);
      expect(restored.tags!.length, 5);
      expect(restored.tags!, contains('432hz'));
      expect(restored.language, 'es');
      expect(restored.slug, 'ondas-theta-sueno-profundo-432hz');
      expect(restored.isRental, isTrue);
      expect(restored.isSuspended, isFalse);
      expect(restored.totalPageViews, 0);
    });

    test('Cyberneom draft should track post-cover state', () {
      expect(draft.lastCompletedStep, ReleaseUploadStep.coverUploaded);
      expect(draft.coverImageRemoteUrl, isNotNull);
      expect(draft.releaseItems.length, 1);
      expect(draft.releaseFilePaths.length, 1);
    });

    test('Cyberneom draft should be resumable at coverUploaded step', () {
      expect(draft.canResume, isTrue);
      expect(draft.progressDescription, 'Portada subida');
    });

    test('Cyberneom draft should serialize and restore correctly', () {
      final draftJson = draft.toJson();
      final restored = ReleaseCacheDraft.fromJson(draftJson);

      expect(restored.ownerId, 'profile_neomsound_lab');
      expect(restored.lastCompletedStep, ReleaseUploadStep.coverUploaded);
      expect(restored.releaseType, ReleaseType.single);
      expect(restored.releaseItems.length, 1);
      expect(restored.releaseItems.first.name, 'Ondas Theta: Sueño Profundo 432Hz');
      expect(restored.releaseItems.first.mediaType, MediaItemType.binaural);
      expect(restored.isAutoPublished, isTrue);
      expect(restored.coverImageRemoteUrl,
          'https://firebasestorage.googleapis.com/cyberneom/covers/theta-sueno.jpg');
    });

    test('Slug should handle colons and special characters', () {
      expect(
        AppReleaseItem.generateSlug('Ondas Theta: Sueño Profundo 432Hz'),
        'ondas-theta-sueño-profundo-432hz',
      );
    });

    test('Failed draft should NOT be resumable', () {
      final failedDraft = ReleaseCacheDraft(
        ownerId: 'profile_neomsound_lab',
        lastCompletedStep: ReleaseUploadStep.failed,
        errorMessage: 'Firebase Storage quota exceeded',
      );
      expect(failedDraft.canResume, isFalse);
      expect(failedDraft.progressDescription, contains('Firebase Storage'));
    });
  });

  // ════════════════════════════════════════════════════════════════
  // CROSS-SCENARIO: Upload step progression
  // ════════════════════════════════════════════════════════════════
  group('Cross-scenario — Upload step progression', () {
    test('ReleaseUploadStep enum should have correct order', () {
      expect(ReleaseUploadStep.initial.index, 0);
      expect(ReleaseUploadStep.typeSelected.index, 1);
      expect(ReleaseUploadStep.coverUploaded.index, 8);
      expect(ReleaseUploadStep.itemlistCreated.index, 9);
      expect(ReleaseUploadStep.itemsUploading.index, 10);
      expect(ReleaseUploadStep.itemsUploaded.index, 11);
      expect(ReleaseUploadStep.completed.index, 13);
      expect(ReleaseUploadStep.failed.index, 14);
    });

    test('ReleaseType EP should be used for multi-track (Gigmeout)', () {
      expect(ReleaseType.ep.name, 'ep');
    });

    test('ReleaseType single should be used for EMXI + Cyberneom', () {
      expect(ReleaseType.single.name, 'single');
    });

    test('MediaItemType audio subtypes should all report isAudio', () {
      final audioTypes = [
        MediaItemType.song,
        MediaItemType.podcast,
        MediaItemType.audiobook,
        MediaItemType.binaural,
        MediaItemType.frequency,
        MediaItemType.nature,
        MediaItemType.neomPreset,
      ];
      for (final t in audioTypes) {
        expect(t.isAudio, isTrue, reason: '${t.name} should be isAudio');
      }
    });

    test('MediaItemType non-audio types should NOT report isAudio', () {
      final nonAudioTypes = [
        MediaItemType.book,
        MediaItemType.pdf,
        MediaItemType.video,
      ];
      for (final t in nonAudioTypes) {
        expect(t.isAudio, isFalse, reason: '${t.name} should NOT be isAudio');
      }
    });
  });
}
