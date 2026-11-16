import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:neom_core/utils/neom_error_logger.dart';

import '../utils/constants/release_hive_constants.dart';
import 'release_cache_controller.dart';

/// Hive-based persistence for release upload drafts and file bytes.
class ReleaseHiveController {
  static const int maxDraftJsonChars = 2 * 1024 * 1024;
  static const int maxFileBytes = 50 * 1024 * 1024;
  static const int maxCoverBytes = 10 * 1024 * 1024;
  static const int maxFileBase64Chars = ((maxFileBytes + 2) ~/ 3) * 4 + 64;
  static const int maxCoverBase64Chars = ((maxCoverBytes + 2) ~/ 3) * 4 + 64;
  static const int maxFilesPerDraft = 100;
  static final RegExp _controlChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _safeDraftIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
  static final RegExp _reservedDunderKey = RegExp(r'^__.*__$');
  static final RegExp _encodedDraftIdUnsafeRe = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );
  static final RegExp _coverActiveMarkupRe = RegExp(
    r'(?:<!doctype\s+html|<\?xml\b|<html\b|<script\b|<iframe\b|<svg\b|<foreignobject\b|<object\b|<embed\b|\bon(?:load|error|click)\s*=|javascript\s*:)',
    caseSensitive: false,
  );
  static const Set<String> _forbiddenDraftIds = <String>{
    '__proto__',
    'constructor',
    'prototype',
  };

  static final ReleaseHiveController _instance = ReleaseHiveController._internal();
  factory ReleaseHiveController() => _instance;
  ReleaseHiveController._internal();

  Box? _box;

  /// Validates a draft identifier before constructing Hive keys.
  static bool isSafeDraftId(String raw) {
    if (_controlChars.hasMatch(raw) || _encodedDraftIdUnsafeRe.hasMatch(raw)) {
      return false;
    }
    final clean = raw.trim();
    if (clean.isEmpty || clean != raw || clean.length > 128) return false;
    if (clean == '.' ||
        clean == '..' ||
        clean.contains('..') ||
        _forbiddenDraftIds.contains(clean.toLowerCase()) ||
        _reservedDunderKey.hasMatch(clean)) {
      return false;
    }
    return _safeDraftIdPattern.hasMatch(clean);
  }

  static final RegExp _windowsUnsafeFileChars = RegExp(r'[:*?"<>|/\\]');
  static final RegExp _windowsReservedStem = RegExp(
    r'^(?:con|prn|aux|nul|com[1-9]|lpt[1-9]|conin\$|conout\$|clock\$|__proto__|constructor|prototype|__.*__)$',
    caseSensitive: false,
  );

  static bool _hasActiveCoverMarkup(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    final sampleLen = bytes.length < 4096 ? bytes.length : 4096;
    final head = latin1.decode(bytes.sublist(0, sampleLen), allowInvalid: true);
    if (_coverActiveMarkupRe.hasMatch(head)) return true;
    if (head.contains('\x00') &&
        _coverActiveMarkupRe.hasMatch(head.replaceAll('\x00', ''))) {
      return true;
    }
    return false;
  }

  static String _sanitizeCachedFileName(String raw) {
    if (_encodedDraftIdUnsafeRe.hasMatch(raw)) return '';
    var cleaned = raw
        .replaceAll(_controlChars, '')
        .replaceAll(_windowsUnsafeFileChars, '_')
        .replaceAll('..', '.')
        .trim();
    while (cleaned.startsWith('.')) {
      cleaned = cleaned.substring(1).trimLeft();
    }
    while (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trimRight();
    }
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') return '';
    final dotIdx = cleaned.indexOf('.');
    final stem = (dotIdx > 0 ? cleaned.substring(0, dotIdx) : cleaned).trim();
    if (stem.isEmpty || _windowsReservedStem.hasMatch(stem)) {
      cleaned = '_$cleaned';
    }
    if (cleaned.length <= 180) return cleaned;
    var end = 180;
    final lastUnit = cleaned.codeUnitAt(end - 1);
    if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
      end -= 1;
    }
    return end <= 0 ? '' : cleaned.substring(0, end);
  }

  Future<Box?> _getBox() async {
    if (_box != null && _box!.isOpen) return _box;
    if (Hive.isBoxOpen(AppHiveBox.releases.name)) {
      _box = Hive.box(AppHiveBox.releases.name);
      return _box;
    }
    final completer = Completer<Box?>();
    runZonedGuarded(
      () async {
        try {
          final opened = await Hive.openBox(AppHiveBox.releases.name);
          _box = opened;
          if (!completer.isCompleted) completer.complete(opened);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      (_, _) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    return completer.future;
  }

  // ============================================================
  // DRAFT METHODS
  // ============================================================

  /// Save a release upload draft.
  Future<void> saveDraft(ReleaseCacheDraft draft) async {
    if (!isSafeDraftId(draft.id)) return;
    try {
      final box = await _getBox();
      if (box == null) return;
      final encoded = jsonEncode(draft.toJson());
      if (encoded.length > maxDraftJsonChars) return;
      final key = '${ReleaseHiveConstants.draftPrefix}${draft.id}';
      await box.put(key, encoded);
      await box.put(ReleaseHiveConstants.activeDraftId, draft.id);
      AppConfig.logger.t('Saved release draft: ${draft.id} [${draft.progressDescription}]');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'saveDraft');
    }
  }

  /// Load the active draft, or null if none exists / expired.
  Future<ReleaseCacheDraft?> loadActiveDraft() async {
    try {
      final box = await _getBox();
      if (box == null) return null;
      final rawDraftId = box.get(ReleaseHiveConstants.activeDraftId);
      final draftId = rawDraftId is String ? rawDraftId.trim() : null;
      if (draftId == null || !isSafeDraftId(draftId)) return null;

      final key = '${ReleaseHiveConstants.draftPrefix}$draftId';
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty || raw.length > maxDraftJsonChars) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final draft = ReleaseCacheDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      if (!draft.canResume) {
        AppConfig.logger.d('Draft $draftId expired or completed, clearing');
        await clearDraft(draftId);
        return null;
      }

      return draft;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'loadActiveDraft');
    }
    return null;
  }

  /// Load a draft for a specific user.
  Future<ReleaseCacheDraft?> loadDraftForUser(String ownerId) async {
    if (!isSafeDraftId(ownerId)) return null;
    final draft = await loadActiveDraft();
    if (draft != null && draft.ownerId == ownerId) return draft;
    return null;
  }

  /// Clear a specific draft and its associated file bytes.
  Future<void> clearDraft(String draftId) async {
    if (!isSafeDraftId(draftId)) return;
    try {
      final box = await _getBox();
      if (box == null) return;
      // Remove draft
      await box.delete('${ReleaseHiveConstants.draftPrefix}$draftId');

      // Remove associated file bytes
      final keysToRemove = <String>[];
      for (final key in box.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${ReleaseHiveConstants.fileBytesPrefix}${draftId}_') ||
            keyStr == '${ReleaseHiveConstants.coverBytesPrefix}$draftId') {
          keysToRemove.add(keyStr);
        }
      }
      for (final key in keysToRemove) {
        await box.delete(key);
      }

      // Clear active draft ID if it matches
      final activeDraftId = box.get(ReleaseHiveConstants.activeDraftId);
      if (activeDraftId == draftId) {
        await box.delete(ReleaseHiveConstants.activeDraftId);
      }

      AppConfig.logger.d('Cleared release draft $draftId and ${keysToRemove.length} cached files');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'clearDraft');
    }
  }

  /// Clear all drafts and cached files.
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      if (box == null) return;
      await box.clear();
      AppConfig.logger.d('Cleared all release cache');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'clearAll');
    }
  }

  // ============================================================
  // FILE BYTES CACHE (for web resume support)
  // ============================================================

  /// Cache a release file's bytes for resume support on web.
  /// [draftId] - the draft this file belongs to
  /// [fileIndex] - the index of the file in the release
  /// [fileName] - original file name
  /// [bytes] - the file content
  Future<void> cacheFileBytes(String draftId, int fileIndex, String fileName, Uint8List bytes) async {
    if (!isSafeDraftId(draftId) ||
        !fileIndex.isFinite ||
        fileIndex < 0 ||
        fileIndex >= maxFilesPerDraft ||
        bytes.isEmpty ||
        bytes.length > maxFileBytes) {
      return;
    }
    try {
      final box = await _getBox();
      if (box == null) return;
      final key = '${ReleaseHiveConstants.fileBytesPrefix}${draftId}_$fileIndex';
      final cleanName = _sanitizeCachedFileName(fileName);
      // Store as base64 string (Hive handles strings better than raw bytes for large data)
      final data = jsonEncode({
        'fileName': cleanName,
        'bytes': base64Encode(bytes),
        'size': bytes.length,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await box.put(key, data);
      AppConfig.logger.t('Cached file bytes: $cleanName (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'cacheFileBytes');
    }
  }

  /// Retrieve cached file bytes.
  /// Returns null if not found or expired.
  Future<({String fileName, Uint8List bytes})?> getCachedFileBytes(String draftId, int fileIndex) async {
    if (!isSafeDraftId(draftId) ||
        !fileIndex.isFinite ||
        fileIndex < 0 ||
        fileIndex >= maxFilesPerDraft) {
      return null;
    }
    try {
      final box = await _getBox();
      if (box == null) return null;
      final key = '${ReleaseHiveConstants.fileBytesPrefix}${draftId}_$fileIndex';
      final raw = box.get(key);
      if (raw is! String ||
          raw.isEmpty ||
          raw.length > maxFileBase64Chars + 4096) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final fileName = _sanitizeCachedFileName(
        decoded['fileName']?.toString() ?? '',
      );
      final b64 = decoded['bytes'];
      if (b64 is! String || b64.isEmpty || b64.length > maxFileBase64Chars) {
        return null;
      }
      final bytes = base64Decode(b64);
      if (bytes.length > maxFileBytes) return null;

      return (fileName: fileName, bytes: Uint8List.fromList(bytes));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getCachedFileBytes');
    }
    return null;
  }

  /// Get all cached file bytes for a draft.
  Future<List<({String fileName, Uint8List bytes})>> getAllCachedFiles(String draftId) async {
    final files = <({String fileName, Uint8List bytes})>[];
    if (!isSafeDraftId(draftId)) return files;
    try {
      final box = await _getBox();
      if (box == null) return files;
      final prefix = '${ReleaseHiveConstants.fileBytesPrefix}${draftId}_';

      // Collect matching keys and sort numerically by trailing file index
      final indexedKeys = <(int index, String key)>[];
      for (final key in box.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith(prefix)) {
          final suffix = keyStr.substring(prefix.length);
          final idx = int.tryParse(suffix);
          if (idx != null && idx >= 0 && idx < maxFilesPerDraft) {
            indexedKeys.add((idx, keyStr));
          }
        }
      }
      indexedKeys.sort((a, b) => a.$1.compareTo(b.$1));

      for (final entry in indexedKeys) {
        final raw = box.get(entry.$2);
        if (raw is! String ||
            raw.isEmpty ||
            raw.length > maxFileBase64Chars + 4096) {
          continue;
        }

        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final fileName = _sanitizeCachedFileName(
          decoded['fileName']?.toString() ?? '',
        );
        final b64 = decoded['bytes'];
        if (b64 is! String || b64.isEmpty || b64.length > maxFileBase64Chars) {
          continue;
        }
        final bytes = base64Decode(b64);
        if (bytes.length > maxFileBytes) continue;
        files.add((fileName: fileName, bytes: Uint8List.fromList(bytes)));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getAllCachedFiles');
    }
    return files;
  }

  // ============================================================
  // COVER IMAGE CACHE
  // ============================================================

  /// Cache cover image bytes for a draft.
  Future<void> cacheCoverBytes(String draftId, Uint8List bytes) async {
    if (!isSafeDraftId(draftId) ||
        bytes.isEmpty ||
        bytes.length > maxCoverBytes ||
        _hasActiveCoverMarkup(bytes)) {
      return;
    }
    try {
      final box = await _getBox();
      if (box == null) return;
      final key = '${ReleaseHiveConstants.coverBytesPrefix}$draftId';
      await box.put(key, base64Encode(bytes));
      AppConfig.logger.t('Cached cover bytes for draft $draftId (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'cacheCoverBytes');
    }
  }

  /// Retrieve cached cover image bytes.
  Future<Uint8List?> getCachedCoverBytes(String draftId) async {
    if (!isSafeDraftId(draftId)) return null;
    try {
      final box = await _getBox();
      if (box == null) return null;
      final key = '${ReleaseHiveConstants.coverBytesPrefix}$draftId';
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty || raw.length > maxCoverBase64Chars) {
        return null;
      }
      final decoded = base64Decode(raw);
      if (decoded.length > maxCoverBytes) return null;
      return Uint8List.fromList(decoded);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getCachedCoverBytes');
    }
    return null;
  }
}
