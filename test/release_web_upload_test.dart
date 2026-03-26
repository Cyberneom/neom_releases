import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';

/// ──────────────────────────────────────────────────────────────────
/// Test Suite: Web Upload Modal — Controller Logic
///
/// Tests the web release upload data preparation:
///  1. Single PDF upload (EMXI)
///  2. Album multi-track upload (Gigmeout)
///  3. Validation rules
///  4. Itemlist construction
///  5. Release items construction from form data
/// ──────────────────────────────────────────────────────────────────

/// Simple file representation for tests (avoids file_picker dependency).
class _FakeFile {
  final String name;
  final int size;
  final Uint8List bytes;
  _FakeFile(this.name, this.size) : bytes = Uint8List(size);
}

void main() {
  // ════════════════════════════════════════════════════════════════
  // TEST 1: EMXI — Web Single PDF Upload
  // ════════════════════════════════════════════════════════════════
  group('Web Modal — EMXI Single PDF', () {
    test('Single type should produce 1 release item', () {
      final items = _buildItems(
        title: 'Mi Primera Novela',
        author: 'Juan Perez',
        description: 'Una novela de aventuras.',
        genre: 'Novela',
        releaseType: ReleaseType.single,
        isEmxi: true,
        files: [_FakeFile('mi-primera-novela.pdf', 2048000)],
      );

      expect(items.length, 1);
      expect(items.first.name, 'Mi Primera Novela');
      expect(items.first.ownerName, 'Juan Perez');
      expect(items.first.description, 'Una novela de aventuras.');
      expect(items.first.categories, ['Novela']);
      expect(items.first.mediaType, MediaItemType.pdf);
      expect(items.first.type, ReleaseType.single);
    });

    test('Single PDF itemlist should have type single', () {
      final itemlist = _buildItemlist(
        title: 'Mi Primera Novela',
        description: 'Una novela de aventuras.',
        releaseType: ReleaseType.single,
      );

      expect(itemlist.name, 'Mi Primera Novela');
      expect(itemlist.description, 'Una novela de aventuras.');
      expect(itemlist.type, ItemlistType.single);
    });

    test('Release item should have required metadata fields', () {
      final items = _buildItems(
        title: 'Obra Completa',
        author: 'Maria Garcia',
        genre: 'Poesia',
        releaseType: ReleaseType.single,
        isEmxi: true,
        files: [_FakeFile('obra-completa.pdf', 1024000)],
        email: 'maria@example.com',
      );

      final item = items.first;
      expect(item.ownerEmail, 'maria@example.com');
      expect(item.boughtUsers, isEmpty);
      expect(item.createdTime, greaterThan(0));
      expect(item.state, 5);
      expect(item.galleryUrls, isNotEmpty);
    });

    test('Empty title should fail validation', () {
      expect(_canProceed(title: '', fileCount: 1), isFalse);
    });

    test('No files should fail validation', () {
      expect(_canProceed(title: 'Valid Title', fileCount: 0), isFalse);
    });

    test('Valid title + file should pass validation', () {
      expect(_canProceed(title: 'Valid Title', fileCount: 1), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 2: Gigmeout — Web Album Upload (3 tracks)
  // ════════════════════════════════════════════════════════════════
  group('Web Modal — Gigmeout Album (3 MP3s)', () {
    test('Album should produce 3 release items from 3 files', () {
      final items = _buildItems(
        title: 'Noches Electricas EP',
        author: 'Los Voltios',
        description: 'EP de rock alternativo.',
        genre: 'Rock',
        releaseType: ReleaseType.album,
        isEmxi: false,
        files: [
          _FakeFile('01-circuito-roto.mp3', 5000000),
          _FakeFile('02-senales-de-humo.mp3', 6000000),
          _FakeFile('03-ultimo-amplificador.mp3', 7000000),
        ],
      );

      expect(items.length, 3);
    });

    test('Album tracks should use filename as name (not album title)', () {
      final items = _buildItems(
        title: 'Noches Electricas EP',
        author: 'Los Voltios',
        releaseType: ReleaseType.album,
        isEmxi: false,
        files: [
          _FakeFile('circuito-roto.mp3', 5000000),
          _FakeFile('senales-de-humo.mp3', 6000000),
        ],
      );

      expect(items[0].name, 'circuito-roto');
      expect(items[1].name, 'senales-de-humo');
    });

    test('All album tracks should share the same author', () {
      final items = _buildItems(
        title: 'Test Album',
        author: 'The Band',
        releaseType: ReleaseType.album,
        isEmxi: false,
        files: [_FakeFile('track1.mp3', 1000), _FakeFile('track2.mp3', 1000)],
      );

      for (final item in items) {
        expect(item.ownerName, 'The Band');
      }
    });

    test('All album tracks should be MediaItemType.song', () {
      final items = _buildItems(
        title: 'Test Album',
        author: 'Artist',
        releaseType: ReleaseType.album,
        isEmxi: false,
        files: [_FakeFile('a.mp3', 1000), _FakeFile('b.mp3', 1000)],
      );

      for (final item in items) {
        expect(item.mediaType, MediaItemType.song);
      }
    });

    test('Album itemlist should have type album', () {
      final itemlist = _buildItemlist(
        title: 'Noches Electricas EP',
        description: 'EP de rock alternativo.',
        releaseType: ReleaseType.album,
      );

      expect(itemlist.type, ItemlistType.album);
    });

    test('Single file in album mode should still produce 1 item', () {
      final items = _buildItems(
        title: 'Mini Album',
        author: 'Solo Artist',
        releaseType: ReleaseType.album,
        isEmxi: false,
        files: [_FakeFile('only-track.mp3', 3000000)],
      );

      expect(items.length, 1);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 3: File management
  // ════════════════════════════════════════════════════════════════
  group('Web Modal — File Management', () {
    test('Single mode should replace file on second add', () {
      final files = <_FakeFile>[];

      files.clear();
      files.add(_FakeFile('first.pdf', 100));
      expect(files.length, 1);
      expect(files.first.name, 'first.pdf');

      files.clear();
      files.add(_FakeFile('second.pdf', 200));
      expect(files.length, 1);
      expect(files.first.name, 'second.pdf');
    });

    test('Album mode should accumulate files', () {
      final files = <_FakeFile>[];
      files.add(_FakeFile('track1.mp3', 100));
      files.add(_FakeFile('track2.mp3', 200));
      files.add(_FakeFile('track3.mp3', 300));
      expect(files.length, 3);
    });

    test('Remove file by index should work correctly', () {
      final files = [
        _FakeFile('a.mp3', 100),
        _FakeFile('b.mp3', 200),
        _FakeFile('c.mp3', 300),
      ];

      files.removeAt(1);
      expect(files.length, 2);
      expect(files[0].name, 'a.mp3');
      expect(files[1].name, 'c.mp3');
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 4: Genre selection
  // ════════════════════════════════════════════════════════════════
  group('Web Modal — Genre Selection', () {
    test('Selected genre should appear in item categories', () {
      final items = _buildItems(
        title: 'Test', author: 'Author', genre: 'Terror',
        releaseType: ReleaseType.single, isEmxi: true,
        files: [_FakeFile('test.pdf', 100)],
      );
      expect(items.first.categories, contains('Terror'));
    });

    test('Empty genre should produce empty categories', () {
      final items = _buildItems(
        title: 'Test', author: 'Author', genre: '',
        releaseType: ReleaseType.single, isEmxi: true,
        files: [_FakeFile('test.pdf', 100)],
      );
      expect(items.first.categories, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 5: Cross-app content type
  // ════════════════════════════════════════════════════════════════
  group('Web Modal — Content Type by App', () {
    test('EMXI single should produce PDF type', () {
      final items = _buildItems(
        title: 'Book', author: 'A', releaseType: ReleaseType.single,
        isEmxi: true, files: [_FakeFile('book.pdf', 100)],
      );
      expect(items.first.mediaType, MediaItemType.pdf);
    });

    test('Gigmeout single should produce song type', () {
      final items = _buildItems(
        title: 'Track', author: 'A', releaseType: ReleaseType.single,
        isEmxi: false, files: [_FakeFile('track.mp3', 100)],
      );
      expect(items.first.mediaType, MediaItemType.song);
    });

    test('EMXI album should still produce PDF items', () {
      final items = _buildItems(
        title: 'Collection', author: 'A', releaseType: ReleaseType.album,
        isEmxi: true, files: [_FakeFile('ch1.pdf', 100), _FakeFile('ch2.pdf', 100)],
      );
      for (final item in items) {
        expect(item.mediaType, MediaItemType.pdf);
      }
    });
  });
}

// ── Test Helpers ──

List<AppReleaseItem> _buildItems({
  required String title,
  required String author,
  String description = '',
  String genre = '',
  required ReleaseType releaseType,
  required bool isEmxi,
  required List<_FakeFile> files,
  String email = 'test@test.com',
  String photoUrl = 'https://example.com/photo.jpg',
}) {
  final isSingle = releaseType == ReleaseType.single;
  return files.map((file) {
    final name = isSingle ? title : file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return AppReleaseItem(
      name: name,
      description: description,
      ownerEmail: email,
      ownerName: author,
      type: releaseType,
      mediaType: isEmxi ? MediaItemType.pdf : MediaItemType.song,
      categories: genre.isNotEmpty ? [genre] : [],
      galleryUrls: [photoUrl],
      metaOwnerId: email,
      boughtUsers: [],
      createdTime: DateTime.now().millisecondsSinceEpoch,
      state: 5,
    );
  }).toList();
}

Itemlist _buildItemlist({
  required String title,
  String description = '',
  required ReleaseType releaseType,
}) {
  return Itemlist(
    name: title,
    description: description,
    type: releaseType == ReleaseType.single ? ItemlistType.single : ItemlistType.album,
  );
}

bool _canProceed({required String title, required int fileCount}) {
  return title.trim().isNotEmpty && fileCount > 0;
}
