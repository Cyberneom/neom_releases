import 'dart:convert';

import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sint/sint.dart';

/// Enum representing the upload steps for tracking progress
enum ReleaseUploadStep {
  initial,           // Just started
  typeSelected,      // Release type selected
  bandOrSoloSelected, // Band/Solo selection done
  itemlistNameDescSet, // Itemlist name/desc set (for albums/EPs)
  nameDescSet,       // Name and description set
  instrumentsSet,    // Instruments selected
  genresSet,         // Genres selected
  infoSet,           // Publisher info set
  coverUploaded,     // Cover image uploaded to WordPress
  itemlistCreated,   // Itemlist created in Firestore
  itemsUploading,    // Items being uploaded
  itemsUploaded,     // All items uploaded
  postCreated,       // Post created
  completed,         // All done
  failed             // Failed at some step
}

/// Model to store the cached release upload state
class ReleaseCacheDraft {
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
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

  factory ReleaseCacheDraft.fromJson(Map<String, dynamic> json) {
    return ReleaseCacheDraft(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      lastCompletedStep: ReleaseUploadStep.values[json['lastCompletedStep'] as int],
      releaseType: json['releaseType'] != null
          ? ReleaseType.values[json['releaseType'] as int]
          : null,
      itemlist: json['itemlist'] != null
          ? Itemlist.fromJSON(json['itemlist'] as Map<String, dynamic>)
          : null,
      releaseItems: (json['releaseItems'] as List<dynamic>?)
          ?.map((e) => AppReleaseItem.fromJSON(e as Map<String, dynamic>))
          .toList() ?? [],
      releaseFilePaths: (json['releaseFilePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      coverImageLocalPath: json['coverImageLocalPath'] as String?,
      coverImageRemoteUrl: json['coverImageRemoteUrl'] as String?,
      publisherPlace: json['publisherPlace'] != null
          ? Place.fromJSON(json['publisherPlace'] as Map<String, dynamic>)
          : null,
      isAutoPublished: json['isAutoPublished'] as bool? ?? false,
      publishedYear: json['publishedYear'] as int? ?? 0,
      currentItemIndex: json['currentItemIndex'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
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
      case ReleaseUploadStep.bandOrSoloSelected:
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

/// Controller to manage release upload cache/drafts
class ReleaseCacheController extends SintController {

  static const String _cacheKey = 'release_upload_draft';

  final Rx<ReleaseCacheDraft?> currentDraft = Rx<ReleaseCacheDraft?>(null);
  final RxBool hasPendingDraft = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExistingDraft();
  }

  /// Load any existing draft from SharedPreferences
  Future<void> _loadExistingDraft() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_cacheKey);

      if (draftJson != null && draftJson.isNotEmpty) {
        final draft = ReleaseCacheDraft.fromJson(jsonDecode(draftJson));
        if (draft.canResume) {
          currentDraft.value = draft;
          hasPendingDraft.value = true;
          AppConfig.logger.i('Found resumable release draft: ${draft.progressDescription}');
        } else {
          // Draft is too old or completed, clear it
          await clearDraft();
          AppConfig.logger.d('Cleared old/completed release draft');
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error loading release draft: $e');
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
    if (errorMessage != null) draft.errorMessage = errorMessage;

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
    if (currentDraft.value != null) {
      currentDraft.value!.lastCompletedStep = ReleaseUploadStep.completed;
      currentDraft.value!.updatedAt = DateTime.now();
    }
    await clearDraft();
    AppConfig.logger.i('Release upload completed successfully');
  }

  /// Save the current draft to SharedPreferences
  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (currentDraft.value != null) {
        final jsonString = jsonEncode(currentDraft.value!.toJson());
        await prefs.setString(_cacheKey, jsonString);
      }
    } catch (e) {
      AppConfig.logger.e('Error saving release draft: $e');
    }
  }

  /// Clear the current draft
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      currentDraft.value = null;
      hasPendingDraft.value = false;
      AppConfig.logger.d('Cleared release draft');
    } catch (e) {
      AppConfig.logger.e('Error clearing release draft: $e');
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
}
