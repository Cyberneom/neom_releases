import 'dart:typed_data';

import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import 'release_hive_controller.dart';

/// Enum representing the upload steps for tracking progress
enum ReleaseUploadStep {
  initial,           // Just started
  typeSelected,      // Release type selected
  collectiveOrSoloSelected, // Collective/Solo selection done
  itemlistNameDescSet, // Itemlist name/desc set (for albums/EPs)
  nameDescSet,       // Name and description set
  instrumentsSet,    // Instruments selected
  genresSet,         // Genres selected
  infoSet,           // Publisher info set
  coverUploaded,     // Cover image uploaded
  itemlistCreated,   // Itemlist created in Firestore
  itemsUploading,    // Items being uploaded
  itemsUploaded,     // All items uploaded
  postCreated,       // Post created
  completed,         // All done
  failed             // Failed at some step
}

/// Model to store the cached release upload state
class ReleaseCacheDraft {
  static int _draftSeq = 0;
  static final RegExp _unsafeDraftChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _unsafeDraftTextChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _draftInternalTags = RegExp(
    r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\|>|$)'
    r'|<\|tool_call\s*>[\s\S]*?(?:<tool_call\|>|$)'
    r'|<\s*(think|thinking|thought|memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?(?:<\s*/\s*\1\s*>|$)'
    r'|<\s*/?\s*(?:think|thinking|thought|memory_recall|auto_memory|system_context)\b[^>]*>'
    r'|\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\](?:(?!\[\s*\2\b)[\s\S])*?\[\s*/\s*\2\s*\]'
    r'|\[\s*/?\s*(?:BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\]'
    r'|<(?:channel|turn|tool_call)\|>|<\|/?(?:turn|channel|tool_call|im_start|im_end|eot_id)\|?>',
    caseSensitive: false,
  );
  static final RegExp _encodedDraftPathUnsafeRe = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );
  static const Set<String> _sensitiveLocalSegments = <String>{
    '.ssh',
    '.aws',
    '.gnupg',
    '.kube',
    'kubeconfig',
    '.docker',
    '.git',
    '.env',
    '.secret.local',
    '.npmrc',
    '.netrc',
    'id_rsa',
    'id_ed25519',
    'cookies.sqlite',
  };
  static final RegExp _urlBasicAuthPattern = RegExp(
    r'(https?://)[^\s/@:]+:[^\s/@]+@',
    caseSensitive: false,
  );
  static final RegExp _inlineSecretPattern = RegExp(
    r'(?:Bearer\s+[A-Za-z0-9._~+/=-]+|(?:sk|rk)_(?:live|test)_[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9_-]{12,}|hf_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|([?&](?:api_key|token|access_token|refresh_token|session_token|client_secret|secret|sig|signature)=)[^&\s]+)',
    caseSensitive: false,
  );

  static String? sanitizeDraftError(Object? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .toString()
        .replaceAll(_draftInternalTags, '')
        .replaceAll(_unsafeDraftTextChars, ' ')
        .replaceAllMapped(_urlBasicAuthPattern, (m) => '${m.group(1)}[REDACTED]@')
        .replaceAllMapped(
          _inlineSecretPattern,
          (m) => m.group(1) != null ? '${m.group(1)}[REDACTED]' : '[REDACTED]',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.length <= 1024) return cleaned;
    var end = 1024;
    final prev = cleaned.codeUnitAt(end - 1);
    if (prev >= 0xD800 && prev <= 0xDBFF) end -= 1;
    return end <= 0 ? null : cleaned.substring(0, end);
  }

  static String? _cleanLocalDraftPath(Object? raw) {
    if (raw == null) return null;
    final rawStr = raw.toString();
    if (_unsafeDraftChars.hasMatch(rawStr) ||
        _encodedDraftPathUnsafeRe.hasMatch(rawStr)) {
      return null;
    }
    final clean = rawStr.trim();
    if (clean.isEmpty ||
        clean.length > 4096 ||
        clean.startsWith('//') ||
        clean.startsWith(r'\\')) {
      return null;
    }
    final norm = clean.replaceAll('\\', '/');
    final lower = norm.toLowerCase();
    if (lower.startsWith('/etc/') ||
        lower.startsWith('/private/etc/') ||
        lower.startsWith('/proc/') ||
        lower.startsWith('/sys/')) {
      return null;
    }
    for (final seg in norm.split('/')) {
      if (seg.isEmpty) continue;
      final segLower = seg.toLowerCase();
      if (seg == '..' ||
          _sensitiveLocalSegments.contains(segLower) ||
          segLower.startsWith('.env.') ||
          segLower.contains('firebase-adminsdk')) {
        return null;
      }
    }
    return clean;
  }

  static String? _cleanRemoteUrl(Object? raw) {
    if (raw == null) return null;
    final rawStr = raw.toString();
    if (_unsafeDraftChars.hasMatch(rawStr)) return null;
    final candidate = rawStr.trim();
    if (candidate.isEmpty || candidate.length > 2048 || candidate.contains(r'\')) {
      return null;
    }
    final uri = Uri.tryParse(candidate);
    if (!CoreUtilities.isSafePublicMediaUri(uri)) return null;
    return uri.toString();
  }

  String id;
  String ownerId;
  ReleaseUploadStep lastCompletedStep;
  ReleaseType? releaseType;
  Itemlist? itemlist;
  List<AppReleaseItem> releaseItems;
  List<String> releaseFilePaths;
  String? coverImageLocalPath;
  String? coverImageRemoteUrl;
  Place? publisherPlace;
  bool isAutoPublished;
  int publishedYear;
  int currentItemIndex;
  String? errorMessage;
  DateTime createdAt;
  DateTime updatedAt;

  ReleaseCacheDraft({
    String? id,
    required this.ownerId,
    this.lastCompletedStep = ReleaseUploadStep.initial,
    this.releaseType,
    this.itemlist,
    List<AppReleaseItem>? releaseItems,
    List<String>? releaseFilePaths,
    this.coverImageLocalPath,
    this.coverImageRemoteUrl,
    this.publisherPlace,
    this.isAutoPublished = false,
    this.publishedYear = 0,
    this.currentItemIndex = 0,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${++_draftSeq}',
       errorMessage = sanitizeDraftError(errorMessage),
       releaseItems = releaseItems ?? [],
       releaseFilePaths = releaseFilePaths ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'lastCompletedStep': lastCompletedStep.index,
      'releaseType': releaseType?.index,
      'itemlist': itemlist?.toJSON(),
      'releaseItems': releaseItems.map((e) => e.toJSON()).toList(),
      'releaseFilePaths': releaseFilePaths,
      'coverImageLocalPath': coverImageLocalPath,
      'coverImageRemoteUrl': coverImageRemoteUrl,
      'publisherPlace': publisherPlace?.toJSON(),
      'isAutoPublished': isAutoPublished,
      'publishedYear': publishedYear,
      'currentItemIndex': currentItemIndex,
      'errorMessage': errorMessage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static int? _parseNullableInt(Object? raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (!raw.isFinite) return null;
      return raw is int ? raw : raw.toInt();
    }
    if (raw is String) {
      final t = raw.trim();
      final asInt = int.tryParse(t);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(t);
      if (asDouble != null && asDouble.isFinite) return asDouble.toInt();
    }
    return null;
  }

  static ReleaseUploadStep _parseStep(Object? raw) {
    final idx = _parseNullableInt(raw);
    if (idx != null && idx >= 0 && idx < ReleaseUploadStep.values.length) {
      return ReleaseUploadStep.values[idx];
    }
    if (raw is String) {
      final clean = raw.trim();
      for (final step in ReleaseUploadStep.values) {
        if (step.name == clean) return step;
      }
    }
    return ReleaseUploadStep.initial;
  }

  static ReleaseType? _parseReleaseType(Object? raw) {
    if (raw == null) return null;
    final idx = _parseNullableInt(raw);
    if (idx != null && idx >= 0 && idx < ReleaseType.values.length) {
      return ReleaseType.values[idx];
    }
    if (raw is String) {
      final clean = raw.trim();
      for (final rt in ReleaseType.values) {
        if (rt.name == clean) return rt;
      }
    }
    return null;
  }

  static DateTime _parseEpoch(Object? raw) {
    final ms = _parseNullableInt(raw);
    if (ms != null && ms > 0 && ms <= 8640000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
  }

  factory ReleaseCacheDraft.fromJson(Map<String, dynamic> json) {
    final rawItemlist = json['itemlist'];
    final rawPlace = json['publisherPlace'];
    final rawItems = json['releaseItems'];
    final rawPaths = json['releaseFilePaths'];
    final parsedIndex = _parseNullableInt(json['currentItemIndex']) ?? 0;

    final rawId = json['id']?.toString().trim() ?? '';
    return ReleaseCacheDraft(
      id: ReleaseHiveController.isSafeDraftId(rawId) ? rawId : null,
      ownerId: (json['ownerId']?.toString() ?? '')
          .replaceAll(_unsafeDraftChars, '')
          .trim(),
      lastCompletedStep: _parseStep(json['lastCompletedStep']),
      releaseType: _parseReleaseType(json['releaseType']),
      itemlist: rawItemlist is Map
          ? Itemlist.fromJSON(Map<String, dynamic>.from(rawItemlist))
          : null,
      releaseItems: rawItems is List
          ? rawItems
                .whereType<Map>()
                .take(ReleaseHiveController.maxFilesPerDraft)
                .map((e) => AppReleaseItem.fromJSON(Map<String, dynamic>.from(e)))
                .toList()
          : <AppReleaseItem>[],
      releaseFilePaths: rawPaths is List
          ? rawPaths
                .take(ReleaseHiveController.maxFilesPerDraft)
                .map(_cleanLocalDraftPath)
                .whereType<String>()
                .toList()
          : <String>[],
      coverImageLocalPath: _cleanLocalDraftPath(json['coverImageLocalPath']),
      coverImageRemoteUrl: _cleanRemoteUrl(json['coverImageRemoteUrl']),
      publisherPlace: rawPlace is Map
          ? Place.fromJSON(Map<String, dynamic>.from(rawPlace))
          : null,
      isAutoPublished: json['isAutoPublished'] == true ||
          json['isAutoPublished']?.toString().toLowerCase() == 'true',
      publishedYear: (_parseNullableInt(json['publishedYear']) ?? 0).clamp(0, 9999),
      currentItemIndex: parsedIndex < 0 ? 0 : parsedIndex,
      errorMessage: sanitizeDraftError(json['errorMessage']),
      createdAt: _parseEpoch(json['createdAt']),
      updatedAt: _parseEpoch(json['updatedAt']),
    );
  }

  /// Check if draft can be resumed (not too old and has meaningful progress)
  bool get canResume {
    final hoursSinceUpdate = DateTime.now().difference(updatedAt).inHours;
    return hoursSinceUpdate < 72 && // Less than 3 days old
           lastCompletedStep.index > ReleaseUploadStep.initial.index &&
           lastCompletedStep != ReleaseUploadStep.completed &&
           lastCompletedStep != ReleaseUploadStep.failed;
  }

  /// Get a human-readable description of the current progress
  String get progressDescription {
    switch (lastCompletedStep) {
      case ReleaseUploadStep.initial:
        return 'Iniciado';
      case ReleaseUploadStep.typeSelected:
        return 'Tipo seleccionado';
      case ReleaseUploadStep.collectiveOrSoloSelected:
        return 'Artista configurado';
      case ReleaseUploadStep.itemlistNameDescSet:
        return 'Info del álbum configurada';
      case ReleaseUploadStep.nameDescSet:
        return 'Nombre y descripción listos';
      case ReleaseUploadStep.instrumentsSet:
        return 'Instrumentos seleccionados';
      case ReleaseUploadStep.genresSet:
        return 'Géneros seleccionados';
      case ReleaseUploadStep.infoSet:
        return 'Información de publicación lista';
      case ReleaseUploadStep.coverUploaded:
        return 'Portada subida';
      case ReleaseUploadStep.itemlistCreated:
        return 'Catálogo creado';
      case ReleaseUploadStep.itemsUploading:
        return 'Subiendo archivos (${currentItemIndex + 1}/${releaseItems.length})';
      case ReleaseUploadStep.itemsUploaded:
        return 'Archivos subidos';
      case ReleaseUploadStep.postCreated:
        return 'Publicación creada';
      case ReleaseUploadStep.completed:
        return 'Completado';
      case ReleaseUploadStep.failed:
        return 'Error: ${errorMessage ?? "desconocido"}';
    }
  }
}

/// Controller to manage release upload cache/drafts using Hive.
class ReleaseCacheController extends SintController {

  final _hive = ReleaseHiveController();

  final Rx<ReleaseCacheDraft?> currentDraft = Rx<ReleaseCacheDraft?>(null);
  final RxBool hasPendingDraft = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExistingDraft();
  }

  @override
  void onClose() {
    currentDraft.close();
    hasPendingDraft.close();
    isLoading.close();
    super.onClose();
  }

  /// Load any existing draft from Hive
  Future<void> _loadExistingDraft() async {
    try {
      isLoading.value = true;
      final draft = await _hive.loadActiveDraft();

      if (draft != null) {
        currentDraft.value = draft;
        hasPendingDraft.value = true;
        AppConfig.logger.i('Found resumable release draft: ${draft.progressDescription}');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: '_loadExistingDraft');
      await clearDraft();
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if there's a pending draft that can be resumed
  Future<bool> checkForPendingDraft(String ownerId) async {
    await _loadExistingDraft();
    return hasPendingDraft.value && currentDraft.value?.ownerId == ownerId;
  }

  /// Start a new draft
  Future<ReleaseCacheDraft> startNewDraft(String ownerId) async {
    await clearDraft();
    final draft = ReleaseCacheDraft(ownerId: ownerId);
    currentDraft.value = draft;
    hasPendingDraft.value = true;
    await _saveDraft();
    AppConfig.logger.d('Started new release draft: ${draft.id}');
    return draft;
  }

  /// Update the draft with new data
  Future<void> updateDraft({
    ReleaseUploadStep? step,
    ReleaseType? releaseType,
    Itemlist? itemlist,
    List<AppReleaseItem>? releaseItems,
    List<String>? releaseFilePaths,
    String? coverImageLocalPath,
    String? coverImageRemoteUrl,
    Place? publisherPlace,
    bool? isAutoPublished,
    int? publishedYear,
    int? currentItemIndex,
    String? errorMessage,
  }) async {
    if (currentDraft.value == null) return;

    final draft = currentDraft.value!;

    if (step != null) draft.lastCompletedStep = step;
    if (releaseType != null) draft.releaseType = releaseType;
    if (itemlist != null) draft.itemlist = itemlist;
    if (releaseItems != null) draft.releaseItems = releaseItems;
    if (releaseFilePaths != null) draft.releaseFilePaths = releaseFilePaths;
    if (coverImageLocalPath != null) draft.coverImageLocalPath = coverImageLocalPath;
    if (coverImageRemoteUrl != null) draft.coverImageRemoteUrl = coverImageRemoteUrl;
    if (publisherPlace != null) draft.publisherPlace = publisherPlace;
    if (isAutoPublished != null) draft.isAutoPublished = isAutoPublished;
    if (publishedYear != null) draft.publishedYear = publishedYear;
    if (currentItemIndex != null) draft.currentItemIndex = currentItemIndex;
    if (errorMessage != null) {
      draft.errorMessage = ReleaseCacheDraft.sanitizeDraftError(errorMessage);
    }

    draft.updatedAt = DateTime.now();
    currentDraft.value = draft;

    await _saveDraft();
    AppConfig.logger.t('Updated release draft: ${draft.progressDescription}');
  }

  /// Mark the upload as failed with an error message
  Future<void> markAsFailed(String errorMessage) async {
    await updateDraft(
      step: ReleaseUploadStep.failed,
      errorMessage: errorMessage,
    );
    AppConfig.logger.e('Release upload failed: $errorMessage');
  }

  /// Mark the upload as completed and clear the draft
  Future<void> markAsCompleted() async {
    final draftId = currentDraft.value?.id;
    if (currentDraft.value != null) {
      currentDraft.value!.lastCompletedStep = ReleaseUploadStep.completed;
      currentDraft.value!.updatedAt = DateTime.now();
    }
    if (draftId != null) {
      await _hive.clearDraft(draftId);
    }
    currentDraft.value = null;
    hasPendingDraft.value = false;
    AppConfig.logger.i('Release upload completed successfully');
  }

  /// Save the current draft to Hive
  Future<void> _saveDraft() async {
    try {
      if (currentDraft.value != null) {
        await _hive.saveDraft(currentDraft.value!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: '_saveDraft');
    }
  }

  /// Clear the current draft
  Future<void> clearDraft() async {
    try {
      final draftId = currentDraft.value?.id;
      if (draftId != null) {
        await _hive.clearDraft(draftId);
      }
      currentDraft.value = null;
      hasPendingDraft.value = false;
      AppConfig.logger.d('Cleared release draft');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'clearDraft');
    }
  }

  /// Get the draft if it exists and belongs to the user
  ReleaseCacheDraft? getDraftForUser(String ownerId) {
    if (currentDraft.value?.ownerId == ownerId &&
        currentDraft.value?.canResume == true) {
      return currentDraft.value;
    }
    return null;
  }

  // ============================================================
  // FILE BYTES CACHE (web resume support)
  // ============================================================

  /// Cache a release file's bytes for web resume.
  Future<void> cacheFileBytes(int fileIndex, String fileName, Uint8List bytes) async {
    final draftId = currentDraft.value?.id;
    if (draftId == null) return;
    await _hive.cacheFileBytes(draftId, fileIndex, fileName, bytes);
  }

  /// Cache the cover image bytes.
  Future<void> cacheCoverBytes(Uint8List bytes) async {
    final draftId = currentDraft.value?.id;
    if (draftId == null) return;
    await _hive.cacheCoverBytes(draftId, bytes);
  }

  /// Get cached file bytes for resume.
  Future<({String fileName, Uint8List bytes})?> getCachedFileBytes(int fileIndex) async {
    final draftId = currentDraft.value?.id;
    if (draftId == null) return null;
    return _hive.getCachedFileBytes(draftId, fileIndex);
  }

  /// Get all cached files for resume.
  Future<List<({String fileName, Uint8List bytes})>> getAllCachedFiles() async {
    final draftId = currentDraft.value?.id;
    if (draftId == null) return [];
    return _hive.getAllCachedFiles(draftId);
  }

  /// Get cached cover bytes for resume.
  Future<Uint8List?> getCachedCoverBytes() async {
    final draftId = currentDraft.value?.id;
    if (draftId == null) return null;
    return _hive.getCachedCoverBytes(draftId);
  }
}
