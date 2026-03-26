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

  static final ReleaseHiveController _instance = ReleaseHiveController._internal();
  factory ReleaseHiveController() => _instance;
  ReleaseHiveController._internal();

  Box? _box;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(AppHiveBox.releases.name);
    return _box!;
  }

  // ============================================================
  // DRAFT METHODS
  // ============================================================

  /// Save a release upload draft.
  Future<void> saveDraft(ReleaseCacheDraft draft) async {
    try {
      final box = await _getBox();
      final key = '${ReleaseHiveConstants.draftPrefix}${draft.id}';
      await box.put(key, jsonEncode(draft.toJson()));
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
      final draftId = box.get(ReleaseHiveConstants.activeDraftId) as String?;
      if (draftId == null || draftId.isEmpty) return null;

      final key = '${ReleaseHiveConstants.draftPrefix}$draftId';
      final raw = box.get(key) as String?;
      if (raw == null || raw.isEmpty) return null;

      final draft = ReleaseCacheDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);

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
    final draft = await loadActiveDraft();
    if (draft != null && draft.ownerId == ownerId) return draft;
    return null;
  }

  /// Clear a specific draft and its associated file bytes.
  Future<void> clearDraft(String draftId) async {
    try {
      final box = await _getBox();
      // Remove draft
      await box.delete('${ReleaseHiveConstants.draftPrefix}$draftId');

      // Remove associated file bytes
      final keysToRemove = <String>[];
      for (final key in box.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${ReleaseHiveConstants.fileBytesPrefix}$draftId') ||
            keyStr.startsWith('${ReleaseHiveConstants.coverBytesPrefix}$draftId')) {
          keysToRemove.add(keyStr);
        }
      }
      for (final key in keysToRemove) {
        await box.delete(key);
      }

      // Clear active draft ID if it matches
      final activeDraftId = box.get(ReleaseHiveConstants.activeDraftId) as String?;
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
    try {
      final box = await _getBox();
      final key = '${ReleaseHiveConstants.fileBytesPrefix}${draftId}_$fileIndex';
      // Store as base64 string (Hive handles strings better than raw bytes for large data)
      final data = jsonEncode({
        'fileName': fileName,
        'bytes': base64Encode(bytes),
        'size': bytes.length,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await box.put(key, data);
      AppConfig.logger.t('Cached file bytes: $fileName (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'cacheFileBytes');
    }
  }

  /// Retrieve cached file bytes.
  /// Returns null if not found or expired.
  Future<({String fileName, Uint8List bytes})?> getCachedFileBytes(String draftId, int fileIndex) async {
    try {
      final box = await _getBox();
      final key = '${ReleaseHiveConstants.fileBytesPrefix}${draftId}_$fileIndex';
      final raw = box.get(key) as String?;
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final fileName = data['fileName'] as String;
      final bytes = base64Decode(data['bytes'] as String);

      return (fileName: fileName, bytes: Uint8List.fromList(bytes));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getCachedFileBytes');
    }
    return null;
  }

  /// Get all cached file bytes for a draft.
  Future<List<({String fileName, Uint8List bytes})>> getAllCachedFiles(String draftId) async {
    final files = <({String fileName, Uint8List bytes})>[];
    try {
      final box = await _getBox();
      final prefix = '${ReleaseHiveConstants.fileBytesPrefix}$draftId';

      // Collect matching keys and sort by index
      final matchingKeys = <String>[];
      for (final key in box.keys) {
        if (key.toString().startsWith(prefix)) {
          matchingKeys.add(key.toString());
        }
      }
      matchingKeys.sort();

      for (final key in matchingKeys) {
        final raw = box.get(key) as String?;
        if (raw == null) continue;

        final data = jsonDecode(raw) as Map<String, dynamic>;
        final fileName = data['fileName'] as String;
        final bytes = base64Decode(data['bytes'] as String);
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
    try {
      final box = await _getBox();
      final key = '${ReleaseHiveConstants.coverBytesPrefix}$draftId';
      await box.put(key, base64Encode(bytes));
      AppConfig.logger.t('Cached cover bytes for draft $draftId (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'cacheCoverBytes');
    }
  }

  /// Retrieve cached cover image bytes.
  Future<Uint8List?> getCachedCoverBytes(String draftId) async {
    try {
      final box = await _getBox();
      final key = '${ReleaseHiveConstants.coverBytesPrefix}$draftId';
      final raw = box.get(key) as String?;
      if (raw == null) return null;
      return Uint8List.fromList(base64Decode(raw));
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getCachedCoverBytes');
    }
    return null;
  }
}
