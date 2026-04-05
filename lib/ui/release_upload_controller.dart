import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/dialog_factory.dart';
import 'package:neom_commons/utils/file_system_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/app_upload_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/data/firestore/request_firestore.dart';
import 'package:neom_core/data/implementations/geolocator_controller.dart';
import 'package:neom_core/domain/model/activity_feed.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_request.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/genre.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/domain/use_cases/audio_lite_player_service.dart';
import 'package:neom_core/domain/use_cases/band_service.dart';
import 'package:neom_core/domain/use_cases/instrument_service.dart';
import 'package:neom_core/domain/use_cases/maps_service.dart';
import 'package:neom_core/domain/use_cases/media_player_service.dart';
import 'package:neom_core/domain/use_cases/media_upload_service.dart';
import 'package:neom_core/domain/use_cases/release_upload_service.dart';
import 'package:neom_core/domain/use_cases/subscription_service.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/domain/use_cases/woo_gateway_service.dart';
import 'package:neom_core/domain/use_cases/woo_media_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/activity_feed_type.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_core/utils/enums/media_upload_destination.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';
import 'package:neom_core/utils/enums/release_status.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/neom_flow_tracker.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_maps_services/domain/models/prediction.dart';
import 'package:pdfx/pdfx.dart';
import 'package:rubber/rubber.dart';
import 'package:sint/sint.dart';

import '../data/release_cache_controller.dart';
import '../utils/constants/release_translation_constants.dart';
import 'web/release_upload_web_modal.dart';

class ReleaseUploadController extends SintController with SintTickerProviderStateMixin implements ReleaseUploadService {

  /// When true, skips all internal navigation (used when called from web modal).
  bool isWebMode = false;

  final userServiceImpl = Sint.find<UserService>();
  final MapsService? mapsServiceImpl = Sint.isRegistered<MapsService>() ? Sint.find<MapsService>() : null;
  final instrumentServiceImpl = Sint.find<InstrumentService>();
  final bandServiceImpl = Sint.find<BandService>();
  final MediaUploadService? mediaUploadServiceImpl = Sint.isRegistered<MediaUploadService>() ? Sint.find<MediaUploadService>() : null;
  final MediaPlayerService? mediaPlayerServiceImpl = Sint.isRegistered<MediaPlayerService>() ? Sint.find<MediaPlayerService>() : null;
  final wooMediaServiceImpl = Sint.find<WooMediaService>();
  final wooGatewayServiceImpl = Sint.find<WooGatewayService>();
  final AudioLitePlayerService? audioLitePlayerServiceImpl = Sint.isRegistered<AudioLitePlayerService>() ? Sint.find<AudioLitePlayerService>() : null;

  /// Cache controller for draft management
  late final ReleaseCacheController cacheController;

  AppProfile profile = AppProfile();
  AppUser user = AppUser();

  /// Flag indicating if there's a pending draft to resume
  final RxBool hasPendingDraft = false.obs;
  /// Current upload status message for UI
  final RxString uploadStatusMessage = ''.obs;
  /// Upload retry counter (max 3 attempts)
  int _uploadRetryCount = 0;
  static const int _maxRetries = 3;

  String backgroundImgUrl = "";

  late ScrollController scrollController = ScrollController();
  RubberAnimationController? rubberAnimationController;
  RubberAnimationController? releaseUploadDetailsAnimationController;

  TextEditingController authorController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController itemlistNameController = TextEditingController();
  TextEditingController itemlistDescController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController maxDistanceKmController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController paymentAmountController = TextEditingController();
  ///DEPRECATED TextEditingController digitalPriceController = TextEditingController();
  TextEditingController physicalPriceController = TextEditingController();

  final Rx<Band> selectedBand = Band().obs;
  final RxBool showItemsQtyDropDown = false.obs;
  final RxList<String> instrumentsUsed = <String>[].obs;
  RxList<Genre> genres = <Genre>[].obs;
  RxList<String> selectedGenres = <String>[].obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isPhysical = false.obs;
  final RxBool isAutoPublished = false.obs;
  final Rx<int> publishedYear = 0.obs;

  final Rx<AppReleaseItem> appReleaseItem = AppReleaseItem().obs;
  final RxList<AppReleaseItem> appReleaseItems = <AppReleaseItem>[].obs;
  final Rx<int> releaseItemsQty = 0.obs;
  final Rx<int> releaseItemIndex = 0.obs;
  final Rx<Place> publisherPlace = Place().obs;
  final Rx<AppProfile?> publisherProfile = Rx<AppProfile?>(null); // Selected publisher profile (if from search)

  final RxString releaseFilePreviewURL = "".obs;
  final RxString releaseCoverImgPath = "".obs;

  List<String> bandInstruments = [];

  String releaseFilePath = "";
  List<String> releaseFilePaths = [];

  Itemlist releaseItemlist = Itemlist();

  bool durationIsSelected = true;

  String previousItemName = '';
  bool isPlaying = false;
  String previewPath = '';

  /// Whether to share the release publicly (create post + send push notification)
  /// Set by the share confirmation dialog before upload
  bool sharePublicly = false;

  @override
  void onInit() async {

    super.onInit();
    AppConfig.logger.d("Release Upload Controller Init");
    NeomFlowTracker.startFlow('release_upload');
    NeomFlowTracker.trackScreen('release_upload');

    try {
      user = userServiceImpl.user;
      profile = userServiceImpl.profile;

      // Initialize cache controller
      cacheController = Sint.put(ReleaseCacheController());

      scrollController = ScrollController();

      if (!kIsWeb) {
        rubberAnimationController = RubberAnimationController(vsync: this, duration: const Duration(milliseconds: 20));
        releaseUploadDetailsAnimationController = getRubberAnimationController();
      }

      ///DEPRECATED
      // digitalPriceController.text = AppFlavour.getInitialPrice();

      if (mapsServiceImpl != null && profile.position != null) {
        mapsServiceImpl!.goToPosition(profile.position!);
      }

      // Check for pending draft
      await _checkForPendingDraft();
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'onInit');
    }
  }

  /// Check if there's a pending draft that can be resumed
  Future<void> _checkForPendingDraft() async {
    try {
      final hasDraft = await cacheController.checkForPendingDraft(profile.id);
      hasPendingDraft.value = hasDraft;
      if (hasDraft) {
        AppConfig.logger.i('Found pending release draft: ${cacheController.currentDraft.value?.progressDescription}');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: '_checkForPendingDraft');
    }
  }

  /// Resume from a pending draft
  Future<void> resumeFromDraft() async {
    final draft = cacheController.currentDraft.value;
    if (draft == null) return;

    AppConfig.logger.i('Resuming release from draft: ${draft.progressDescription}');

    try {
      // Restore release type
      if (draft.releaseType != null) {
        appReleaseItem.value.type = draft.releaseType!;
      }

      // Restore itemlist
      if (draft.itemlist != null) {
        releaseItemlist = draft.itemlist!;
        itemlistNameController.text = releaseItemlist.name;
        itemlistDescController.text = releaseItemlist.description;
      }

      // Restore release items and validate local file paths
      if (draft.releaseItems.isNotEmpty) {
        appReleaseItems.value = draft.releaseItems;

        // Sync the main appReleaseItem with the first cached item
        final firstItem = draft.releaseItems.first;
        appReleaseItem.value = firstItem;
        titleController.text = firstItem.name;
        descController.text = firstItem.description;
        authorController.text = firstItem.ownerName;
        if (firstItem.duration > 0) {
          durationController.text = firstItem.duration.toString();
        }

        // Validate that local files still exist
        final validPaths = <String>[];
        for (final path in draft.releaseFilePaths) {
          if (path.isNotEmpty && File(path).existsSync()) {
            validPaths.add(path);
          } else {
            AppConfig.logger.w('Draft file no longer exists: $path');
          }
        }
        releaseFilePaths = validPaths;

        // If files are missing but were already uploaded (remote URLs exist), that's ok
        // If files are missing and not yet uploaded, we need to go back to file selection
        if (validPaths.length < draft.releaseFilePaths.length
            && draft.lastCompletedStep.index < ReleaseUploadStep.itemsUploaded.index) {
          AppConfig.logger.w('Some local files are missing, falling back to info step');
          draft.lastCompletedStep = ReleaseUploadStep.genresSet;
        }
      }

      // Restore publisher info
      if (draft.publisherPlace != null) {
        publisherPlace.value = draft.publisherPlace!;
        placeController.text = draft.publisherPlace!.name;
      }
      isAutoPublished.value = draft.isAutoPublished;
      publishedYear.value = draft.publishedYear;

      // Restore cover image - check local file first, then fall back to remote URL
      if (draft.coverImageLocalPath != null && draft.coverImageLocalPath!.isNotEmpty
          && File(draft.coverImageLocalPath!).existsSync()) {
        releaseCoverImgPath.value = draft.coverImageLocalPath!;
        try {
          mediaUploadServiceImpl!.setMediaFile(File(draft.coverImageLocalPath!));
        } catch (e) {
          AppConfig.logger.w('Could not restore media file to service: $e');
        }
      } else if (draft.coverImageRemoteUrl != null && draft.coverImageRemoteUrl!.isNotEmpty) {
        // Cover was already uploaded, use remote URL
        appReleaseItem.value.imgUrl = draft.coverImageRemoteUrl!;
        releaseItemlist.imgUrl = draft.coverImageRemoteUrl!;
        AppConfig.logger.i('Using remote cover URL from draft: ${draft.coverImageRemoteUrl}');
      }

      // Ensure loading state is reset when resuming
      isLoading.value = false;
      isButtonDisabled.value = false;

      // Navigate to the appropriate step based on last completed step
      _navigateToResumeStep(draft.lastCompletedStep);

      update([AppPageIdConstants.releaseUpload]);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'resumeFromDraft');
      isLoading.value = false;
      AppUtilities.showSnackBar(
        title: ReleaseTranslationConstants.releaseUpload,
        message: ReleaseTranslationConstants.draftResumeError.tr,
      );
    }
  }

  /// Navigate to the appropriate step based on last completed step
  void _navigateToResumeStep(ReleaseUploadStep step) {
    switch (step) {
      case ReleaseUploadStep.initial:
      case ReleaseUploadStep.typeSelected:
        Sint.toNamed(AppRouteConstants.releaseUploadType);
        break;
      case ReleaseUploadStep.bandOrSoloSelected:
        gotoNameDesc();
        break;
      case ReleaseUploadStep.itemlistNameDescSet:
        Sint.toNamed(AppRouteConstants.releaseUploadNameDesc);
        break;
      case ReleaseUploadStep.nameDescSet:
        Sint.toNamed(AppRouteConstants.releaseUploadInstr);
        break;
      case ReleaseUploadStep.instrumentsSet:
        Sint.toNamed(AppRouteConstants.releaseUploadGenres);
        break;
      case ReleaseUploadStep.genresSet:
        Sint.toNamed(AppRouteConstants.releaseUploadInfo);
        break;
      case ReleaseUploadStep.infoSet:
      case ReleaseUploadStep.coverUploaded:
      case ReleaseUploadStep.itemlistCreated:
      case ReleaseUploadStep.itemsUploading:
        Sint.toNamed(AppRouteConstants.releaseUploadSummary);
        break;
      default:
        Sint.toNamed(AppRouteConstants.releaseUploadType);
    }
  }

  /// Start a new release (clear any existing draft)
  Future<void> startNewRelease() async {
    await cacheController.startNewDraft(profile.id);
    hasPendingDraft.value = false;
    Sint.toNamed(AppRouteConstants.releaseUploadType);
  }

  /// Discard the current draft and start fresh
  Future<void> discardDraft() async {
    await cacheController.clearDraft();
    hasPendingDraft.value = false;
  }


  @override
  void onReady() async {

    try {
      releaseItemlist.isModifiable = false;
      releaseItemlist.appReleaseItems = [];

      authorController.text = profile.name;
      appReleaseItem.value.digitalPrice = Price(currency: AppCurrency.mxn, amount: double.tryParse(AppProperties.getInitialPrice()) ?? 0.0);
      appReleaseItem.value.ownerEmail = user.email;
      appReleaseItem.value.ownerName =  authorController.text;
      appReleaseItem.value.galleryUrls = [profile.photoUrl];
      appReleaseItem.value.categories = [];
      appReleaseItem.value.instruments = [];
      appReleaseItem.value.metaOwnerId = userServiceImpl.user.email;

      genres.value = await CoreUtilities.loadReleaseGenres();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'onReady');
    }

    isLoading.value = false;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void onClose() {
    authorController.dispose();
    titleController.dispose();
    descController.dispose();
    itemlistNameController.dispose();
    itemlistDescController.dispose();
    placeController.dispose();
    maxDistanceKmController.dispose();
    durationController.dispose();
    paymentAmountController.dispose();
    physicalPriceController.dispose();

    if(scrollController.hasClients) {
      scrollController.dispose();
    }

    try { rubberAnimationController?.dispose(); } catch (_) {}
    try { releaseUploadDetailsAnimationController?.dispose(); } catch (_) {}

    audioLitePlayerServiceImpl?.clear();
  }

  @override
  Future<void> setReleaseType(ReleaseType releaseType) async {
    AppConfig.logger.d("Release Type as ${releaseType.name}");
    appReleaseItem.value.type = releaseType;
    appReleaseItem.value.imgUrl = "";

    if(profile.verificationLevel == VerificationLevel.none) {
      if(releaseType != ReleaseType.single) {
        AppUtilities.showSnackBar(
            title: ReleaseTranslationConstants.digitalPositioning,
            message: ReleaseTranslationConstants.freeSingleReleaseUploadMsg.tr
        );
        return;
      } else if(userServiceImpl.user.releaseItemIds?.isNotEmpty ?? false) {
        AppUtilities.showSnackBar(
            title: ReleaseTranslationConstants.digitalPositioning,
            message: ReleaseTranslationConstants.freeSingleReleaseUploadMsg.tr
        );
        return;
      }
    }

    switch(releaseType) {
      case ReleaseType.single:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.single;
        break;
      case ReleaseType.ep:
        releaseItemsQty.value = 2;
        releaseItemlist.type = ItemlistType.ep;
        break;
      case ReleaseType.album:
        releaseItemsQty.value = 4;
        releaseItemlist.type = ItemlistType.album;
        break;
      case ReleaseType.demo:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.demo;
        break;
      case ReleaseType.episode:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.podcast;
        break;
      case ReleaseType.chapter:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.audiobook;
        break;
    }

    appReleaseItems.clear();

    // Save to cache after type selection
    await cacheController.updateDraft(
      step: ReleaseUploadStep.typeSelected,
      releaseType: releaseType,
      itemlist: releaseItemlist,
    );

    if(AppConfig.instance.appInUse == AppInUse.g) {
      if(appReleaseItem.value.type == ReleaseType.single) {
        releaseItemsQty.value = 1;
        showItemsQtyDropDown.value = false;
        if(bandServiceImpl.bands.isNotEmpty) {
          Sint.toNamed(AppRouteConstants.releaseUploadBandOrSolo);
        } else {
          setAsSolo();
        }
      } else {
        showItemsQtyDropDown.value = true;
      }
    } else {
      releaseItemsQty.value = 1;
      setAsSolo();
    }


    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> setAppReleaseItemsQty(int itemsQty) async {
    AppConfig.logger.t("Settings $itemsQty Items for ${appReleaseItem.value.type} Release");
    releaseItemsQty.value = itemsQty;
    appReleaseItems.clear();

    // Update cache
    await cacheController.updateDraft(itemlist: releaseItemlist);

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void addInstrument(int index) {
    AppConfig.logger.t("Adding instrument to required ones");
    Instrument instrument = instrumentServiceImpl.instruments.values.elementAt(index);
    instrumentsUsed.add(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeInstrument(int index) {
    AppConfig.logger.t("Removing instrument from required ones");
    Instrument instrument = instrumentServiceImpl.instruments.values.elementAt(index);
    instrumentsUsed.remove(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> addInstrumentsToReleaseItem() async {
    AppConfig.logger.t("Adding ${instrumentsUsed.length} instruments used in release");
    try {
      appReleaseItem.value.instruments = instrumentsUsed;

      // Save progress to cache
      await cacheController.updateDraft(step: ReleaseUploadStep.instrumentsSet);

      Sint.toNamed(AppRouteConstants.releaseUploadGenres);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addInstrumentsToReleaseItem');
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> uploadReleaseItem() async {
    AppConfig.logger.d("Initiating Upload for Itemlist ${releaseItemlist.name} "
        "- Type: ${releaseItemlist.type} with ${appReleaseItems.length} items");

    String releaseItemlistId = "";
    String releaseCoverImgURL = '';

    // Check if we're resuming from a cached draft
    final draft = cacheController.currentDraft.value;
    final resumeStep = draft?.lastCompletedStep ?? ReleaseUploadStep.initial;

    releaseItemIndex.value = 0;
    isButtonDisabled.value = true;
    isLoading.value = true;
    uploadStatusMessage.value = ReleaseTranslationConstants.uploadingCover.tr;
    update([AppPageIdConstants.releaseUpload]);

    try {
      // ══════════════════════════════════════════════════════════
      // STEP 1: Upload cover image
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('━━━ STEP 1: Cover Image Upload ━━━');
      AppConfig.logger.d('  resumeStep: ${resumeStep.name}, mediaFileExists: ${mediaUploadServiceImpl?.mediaFileExists()}, '
          'mediaBytes: ${mediaUploadServiceImpl?.mediaBytes != null ? "${mediaUploadServiceImpl!.mediaBytes!.length} bytes" : "null"}, '
          'kIsWeb: $kIsWeb');

      if (resumeStep.index >= ReleaseUploadStep.coverUploaded.index
          && draft?.coverImageRemoteUrl != null && draft!.coverImageRemoteUrl!.isNotEmpty) {
        releaseCoverImgURL = draft.coverImageRemoteUrl!;
        releaseItemlist.imgUrl = releaseCoverImgURL;
        AppConfig.logger.i('  ↳ Resuming: Cover already uploaded → $releaseCoverImgURL');
      } else if(mediaUploadServiceImpl!.mediaFileExists() || (kIsWeb && mediaUploadServiceImpl!.mediaBytes != null)) {
        AppConfig.logger.d('  ↳ Uploading cover: ${kIsWeb ? "web bytes (${mediaUploadServiceImpl!.mediaBytes?.length ?? 0})" : mediaUploadServiceImpl!.getMediaFile().path}');
        uploadStatusMessage.value = ReleaseTranslationConstants.uploadingCover.tr;
        update([AppPageIdConstants.releaseUpload]);

        // Web: upload cover from bytes. Mobile: upload from File via WordPress.
        if (kIsWeb && mediaUploadServiceImpl!.mediaBytes != null) {
          AppConfig.logger.d('  ↳ Web path: uploading ${mediaUploadServiceImpl!.mediaBytes!.length} bytes via Firebase');
          releaseCoverImgURL = await AppUploadFirestore().uploadMediaBytes(
            mediaUploadServiceImpl!.getMediaId(),
            mediaUploadServiceImpl!.mediaBytes!,
            MediaType.image,
            MediaUploadDestination.releaseItem,
          );
        } else {
          AppConfig.logger.d('  ↳ Mobile path: uploading via WordPress');
          releaseCoverImgURL = await wooMediaServiceImpl.uploadMediaToWordPress(
            mediaUploadServiceImpl!.getMediaFile(),
            fileName: releaseItemlist.name
          );
        }

        // CRITICAL: Validate cover upload was successful
        if (releaseCoverImgURL.isEmpty) {
          AppConfig.logger.e('  ✗ Cover upload returned EMPTY URL');
          throw Exception(ReleaseTranslationConstants.coverUploadFailed.tr);
        }

        AppConfig.logger.i('  ✓ Cover uploaded → $releaseCoverImgURL');
        releaseItemlist.imgUrl = releaseCoverImgURL;

        // Save progress to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.coverUploaded,
          coverImageRemoteUrl: releaseCoverImgURL,
          itemlist: releaseItemlist,
        );
      } else {
        AppConfig.logger.w('  ⚠ No cover image to upload — mediaFileExists=false, mediaBytes=null');
      }

      // ══════════════════════════════════════════════════════════
      // STEP 2: Create Itemlist in Firestore
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('━━━ STEP 2: Create Itemlist ━━━');
      AppConfig.logger.d('  itemlist: name="${releaseItemlist.name}", type=${releaseItemlist.type}, '
          'imgUrl=${releaseItemlist.imgUrl.isNotEmpty ? "SET (${releaseItemlist.imgUrl.length} chars)" : "EMPTY"}');

      if (resumeStep.index >= ReleaseUploadStep.itemlistCreated.index
          && releaseItemlist.id.isNotEmpty) {
        releaseItemlistId = releaseItemlist.id;
        AppConfig.logger.i('  ↳ Resuming: Itemlist already created → ID: $releaseItemlistId');
      } else {
        uploadStatusMessage.value = ReleaseTranslationConstants.creatingCatalog.tr;
        update([AppPageIdConstants.releaseUpload]);

        releaseItemlistId = await ItemlistFirestore().insert(releaseItemlist);

        // CRITICAL: Validate itemlist creation
        if (releaseItemlistId.isEmpty) {
          AppConfig.logger.e('  ✗ Itemlist insert returned EMPTY ID');
          throw Exception(ReleaseTranslationConstants.catalogCreationFailed.tr);
        }

        releaseItemlist.id = releaseItemlistId;
        AppConfig.logger.i('  ✓ Itemlist created → ID: $releaseItemlistId');

        // Save progress to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.itemlistCreated,
          itemlist: releaseItemlist,
        );
      }

      // ══════════════════════════════════════════════════════════
      // STEP 3: Upload each release item
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('━━━ STEP 3: Upload Release Items (${appReleaseItems.length} total) ━━━');

      // If resuming, skip items that were already uploaded (have remote URL and Firestore ID)
      final resumeItemIndex = (resumeStep == ReleaseUploadStep.itemsUploading)
          ? (draft?.currentItemIndex ?? 0) : 0;

      for (AppReleaseItem releaseItem in appReleaseItems) {
        final itemIdx = releaseItemIndex.value;

        // Skip items already fully uploaded (have ID and remote preview URL)
        if (itemIdx < resumeItemIndex && releaseItem.id.isNotEmpty
            && releaseItem.previewUrl.startsWith('http')) {
          AppConfig.logger.i('  [$itemIdx] ↳ Resuming: Skipping "${releaseItem.name}" (already uploaded)');
          releaseItemIndex.value++;
          update([AppPageIdConstants.releaseUpload]);
          continue;
        }

        AppConfig.logger.i('  [$itemIdx] Processing "${releaseItem.name}"');
        AppConfig.logger.d('  [$itemIdx]   previewUrl (local): "${releaseItem.previewUrl}"');
        AppConfig.logger.d('  [$itemIdx]   imgUrl: "${releaseItem.imgUrl}"');
        AppConfig.logger.d('  [$itemIdx]   mediaType: ${releaseItem.mediaType}, type: ${releaseItem.type}');
        AppConfig.logger.d('  [$itemIdx]   owner: ${releaseItem.ownerName} (${releaseItem.ownerEmail})');

        uploadStatusMessage.value = '${ReleaseTranslationConstants.uploadingFile.tr} ${itemIdx + 1}/${appReleaseItems.length}';
        update([AppPageIdConstants.releaseUpload]);

        // Save current item index to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.itemsUploading,
          currentItemIndex: itemIdx,
        );

        // Set metadata from itemlist - preserve categories from selection
        releaseItem.imgUrl = releaseItemlist.imgUrl;
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlist.id;
        releaseItem.metaName = releaseItemlist.name;
        releaseItem.state = 5;

        // Generate slug if not already set (mobile path)
        if (releaseItem.slug.isEmpty && releaseItem.name.isNotEmpty) {
          releaseItem.slug = releaseItem.name.toLowerCase()
              .replaceAll(RegExp(r'[áàäâ]'), 'a')
              .replaceAll(RegExp(r'[éèëê]'), 'e')
              .replaceAll(RegExp(r'[íìïî]'), 'i')
              .replaceAll(RegExp(r'[óòöô]'), 'o')
              .replaceAll(RegExp(r'[úùüû]'), 'u')
              .replaceAll(RegExp(r'[ñ]'), 'n')
              .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
              .trim()
              .replaceAll(RegExp(r'\s+'), '-');
        }

        AppConfig.logger.d('  [$itemIdx]   imgUrl (from itemlist): "${releaseItem.imgUrl}"');
        AppConfig.logger.d('  [$itemIdx]   categories: ${releaseItem.categories}');
        AppConfig.logger.d('  [$itemIdx]   instruments: ${releaseItem.instruments}');

        releaseItem.status = AppConfig.instance.appInfo.releaseRevisionEnabled
            ? ReleaseStatus.pending : ReleaseStatus.publish;
        AppConfig.logger.d('  [$itemIdx]   status: ${releaseItem.status.name} (revision=${AppConfig.instance.appInfo.releaseRevisionEnabled})');

        // Step 3a: Upload release file to WordPress/Firebase
        String fileExtension = '';
        bool isPdf = false;
        if(releaseItem.previewUrl.isNotEmpty) {
          fileExtension = releaseItem.previewUrl.split('.').last.toLowerCase();
          isPdf = fileExtension == "pdf";

          AppMediaType mediaType = AppMediaType.audio;
          if(fileExtension == "mp3") {
            mediaType = AppMediaType.audio;
          } else if (isPdf) {
            mediaType = AppMediaType.text;
          }

          AppConfig.logger.i('  [$itemIdx]   Uploading file: ext=$fileExtension, isPdf=$isPdf, mediaType=${mediaType.name}');

          String uploadedFileUrl = '';

          // Web: upload from bytes. Mobile: upload from file path.
          if (kIsWeb && mediaUploadServiceImpl != null) {
            final bytes = mediaUploadServiceImpl!.getReleaseFileBytes(itemIdx);
            AppConfig.logger.d('  [$itemIdx]   Web upload: bytes=${bytes != null ? "${bytes.length}" : "NULL"}');
            if (bytes != null && bytes.isNotEmpty) {
              uploadedFileUrl = await AppUploadFirestore().uploadReleaseItemBytes(releaseItem.name, bytes, mediaType);
            } else {
              AppConfig.logger.e('  [$itemIdx]   ✗ No bytes available for web upload!');
            }
          } else {
            String filePath = releaseFilePaths.elementAt(itemIdx);
            AppConfig.logger.d('  [$itemIdx]   Mobile upload: filePath="$filePath"');
            File fileToUpload = await FileSystemUtilities.getFileFromPath(filePath);

            if(AppProperties.mediaToWordpressFlag()) {
              AppConfig.logger.d('  [$itemIdx]   Uploading via WordPress');
              uploadedFileUrl = await wooMediaServiceImpl.uploadMediaToWordPress(fileToUpload, fileName: releaseItem.name);
            } else {
              AppConfig.logger.d('  [$itemIdx]   Uploading via Firebase Storage');
              uploadedFileUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);
            }
          }

          // CRITICAL: Validate file upload was successful
          if (uploadedFileUrl.isEmpty) {
            AppConfig.logger.e('  [$itemIdx]   ✗ File upload returned EMPTY URL');
            throw Exception('${ReleaseTranslationConstants.fileUploadFailed.tr}: ${releaseItem.name}');
          }

          releaseItem.previewUrl = uploadedFileUrl;
          AppConfig.logger.i('  [$itemIdx]   ✓ File uploaded → ${releaseItem.previewUrl}');
        } else {
          AppConfig.logger.w('  [$itemIdx]   ⚠ previewUrl is EMPTY — no file to upload');
        }

        // Step 3b: Create WooCommerce product ONLY for PDFs (to sell physical books)
        // MP3s only need file hosting, no WooCommerce product
        String wooProductId = await _createWooProduct(itemIdx, releaseItem, releaseCoverImgURL);
        if(wooProductId.isNotEmpty) {
          releaseItem.id = wooProductId;
          AppConfig.logger.d('  [$itemIdx]   Using WordPress ID: $wooProductId');
        }

        // Step 3c: Insert to Firestore
        AppConfig.logger.i('  [$itemIdx]   Inserting to Firestore...');
        // Snapshot of what will be inserted
        AppConfig.logger.d('  [$itemIdx]   → Firestore payload: name="${releaseItem.name}", '
            'imgUrl=${releaseItem.imgUrl.isNotEmpty ? "SET" : "EMPTY"}, '
            'previewUrl=${releaseItem.previewUrl.isNotEmpty ? "SET" : "EMPTY"}, '
            'status=${releaseItem.status.name}, mediaType=${releaseItem.mediaType?.name}, '
            'galleryUrls=${releaseItem.galleryUrls?.length ?? 0} items');

        // Insert method will use existing ID if set, otherwise auto-generate
        String releaseItemId = await AppReleaseItemFirestore().insert(releaseItem);

        // CRITICAL: Validate item creation in Firestore
        if (releaseItemId.isEmpty) {
          AppConfig.logger.e('  [$itemIdx]   ✗ Firestore insert returned EMPTY ID');
          throw Exception('${ReleaseTranslationConstants.itemCreationFailed.tr}: ${releaseItem.name}');
        }

        releaseItem.id = releaseItemId;
        AppConfig.logger.i('  [$itemIdx]   ✓ Firestore insert → ID: $releaseItemId');

        if(await ItemlistFirestore().addReleaseItem(releaseItemlist.id, releaseItem)) {
          AppConfig.logger.i('  [$itemIdx]   ✓ Added to itemlist ${releaseItemlist.id}');
          releaseItemlist.appReleaseItems!.add(releaseItem);
        } else {
          AppConfig.logger.e('  [$itemIdx]   ✗ Failed to add to itemlist ${releaseItemlist.id}');
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      // Save progress - all items uploaded
      await cacheController.updateDraft(
        step: ReleaseUploadStep.itemsUploaded,
        releaseItems: appReleaseItems.toList(),
      );
      AppConfig.logger.i('━━━ All ${appReleaseItems.length} items uploaded successfully ━━━');

      // ══════════════════════════════════════════════════════════
      // STEP 4: Create post (optional)
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('━━━ STEP 4: Post Creation (sharePublicly=$sharePublicly) ━━━');
      if (sharePublicly) {
        uploadStatusMessage.value = ReleaseTranslationConstants.creatingPost.tr;
        update([AppPageIdConstants.releaseUpload]);

        await createReleasePost();
        await cacheController.updateDraft(step: ReleaseUploadStep.postCreated);
        AppConfig.logger.i('  ✓ Post created');
      } else {
        AppConfig.logger.i('  ↳ Skipped — user chose not to share publicly');
      }

      // ══════════════════════════════════════════════════════════
      // STEP 5: Finalize (approval request + timeline refresh)
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('━━━ STEP 5: Finalize ━━━');
      uploadStatusMessage.value = ReleaseTranslationConstants.finalizingUpload.tr;
      update([AppPageIdConstants.releaseUpload]);

      await _createReleaseApprovalRequest(releaseCoverImgURL);

      if (Sint.isRegistered<TimelineService>()) {
        AppConfig.logger.d('  Refreshing timeline shelf...');
        await Sint.find<TimelineService>().getReleaseItemsFromWoo();
      }

      // Mark as completed and clear cache
      await cacheController.markAsCompleted();
      _uploadRetryCount = 0;
      NeomFlowTracker.endFlow('release_upload');

      // ══════════════════════════════════════════════════════════
      // UPLOAD COMPLETE — Summary
      // ══════════════════════════════════════════════════════════
      AppConfig.logger.i('╔══════════════════════════════════════════╗');
      AppConfig.logger.i('║  RELEASE UPLOAD COMPLETE                 ║');
      AppConfig.logger.i('╚══════════════════════════════════════════╝');
      AppConfig.logger.i('  Itemlist: "${releaseItemlist.name}" (${releaseItemlist.id})');
      AppConfig.logger.i('  Cover: ${releaseCoverImgURL.isNotEmpty ? releaseCoverImgURL : "NONE"}');
      AppConfig.logger.i('  Items: ${appReleaseItems.length}');
      for (final item in appReleaseItems) {
        AppConfig.logger.i('    • "${item.name}" id=${item.id} '
            'imgUrl=${item.imgUrl.isNotEmpty ? "OK" : "EMPTY"} '
            'previewUrl=${item.previewUrl.isNotEmpty ? "OK" : "EMPTY"} '
            'status=${item.status.name}');
      }

      isButtonDisabled.value = false;
      isLoading.value = false;
      uploadStatusMessage.value = '';

      if (!isWebMode) {
        AppUtilities.showSnackBar(
            title: ReleaseTranslationConstants.digitalPositioning,
            message: ReleaseTranslationConstants.digitalPositioningSuccess.tr
        );
        Sint.offAllNamed(AppRouteConstants.home);
      }
      // Web mode: the web modal handles its own success UI

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'uploadReleaseItem');
      _uploadRetryCount++;

      // Save failed state to cache with error message
      await cacheController.markAsFailed(e.toString());

      if (_uploadRetryCount < _maxRetries) {
        // Attempts 1 & 2: show snackbar with retry option
        AppUtilities.showSnackBar(
          title: AppTranslationConstants.uploadError,
          message: ReleaseTranslationConstants.uploadFailedRetry.tr,
          duration: const Duration(seconds: 5),
        );
      } else {
        // Attempt 3: show "try later" message and reset counter
        AppUtilities.showSnackBar(
          title: AppTranslationConstants.uploadError,
          message: AppTranslationConstants.uploadErrorTryLater.tr,
          duration: const Duration(seconds: 7),
        );
        _uploadRetryCount = 0;
      }

      isButtonDisabled.value = false;
      isLoading.value = false;
      uploadStatusMessage.value = '';

      // DON'T navigate away - let user see the error and potentially retry
      update([AppPageIdConstants.releaseUpload]);
    }
  }

  Future<String> _createWooProduct(int itemIdx, AppReleaseItem releaseItem, String releaseCoverImgURL) async {
    String wooProductId = '';
    if (AppProperties.createWooProductFlag()) {
      AppConfig.logger.i('  [$itemIdx]   Creating WooCommerce product for: ${releaseItem.name}');
      final result = await wooGatewayServiceImpl.createProductFromReleaseItem(
        releaseItem,
        coverImageUrl: releaseCoverImgURL,
        downloadFileUrl: releaseItem.previewUrl,
      );

      if (result != null && result.isNotEmpty) {
        wooProductId = result['id'] ?? '';
        final permalink = result['permalink'] ?? '';
        releaseItem.externalUrl = permalink;
        releaseItem.webPreviewUrl = permalink;
        AppConfig.logger.i('WooProduct created with ID: $wooProductId, permalink: $permalink');
      } else {
        // WooProduct creation failed — stop the process
        throw Exception(ReleaseTranslationConstants.wooProductCreationFailed.tr);
      }
    }
    return wooProductId;
  }

  /// Creates a global notification when release is published (revision disabled)
  /// or creates an AppRequest for admin review (revision enabled)
  /// Note: When revision is enabled, releases are stored with status=pending
  /// and support+ users can review them via AppRequest in the Requests page
  Future<void> _createReleaseApprovalRequest(String coverImageUrl) async {
    try {
      // If release revision is disabled, create a GLOBAL notification for all users
      if (!AppConfig.instance.appInfo.releaseRevisionEnabled) {
        AppConfig.logger.d("Creating GLOBAL notification for new release: ${releaseItemlist.name}");

        // Create a global activity feed notification that all users will see
        final globalActivityFeed = ActivityFeed.fromGlobalNewRelease(
          releaseId: releaseItemlist.id,
          releaseTitle: releaseItemlist.name,
          releaseCoverUrl: coverImageUrl,
          authorProfile: profile,
        );

        final globalFeedId = await ActivityFeedFirestore().insertGlobal(globalActivityFeed);

        if (globalFeedId.isNotEmpty) {
          AppConfig.logger.i("Global notification created with ID: $globalFeedId");
        }
        return;
      }

      // If revision is enabled, create an AppRequest for support+ users to review
      AppConfig.logger.d("Creating AppRequest for release '${releaseItemlist.name}' review");

      // Get the first release item ID (for singles) or itemlist ID (for albums/eps)
      final releaseItemId = appReleaseItems.isNotEmpty
          ? appReleaseItems.first.id
          : releaseItemlist.id;

      // Create release approval request
      // 'to' is set to appBot so support+ users can query for these requests
      final releaseRequest = AppRequest.releaseApproval(
        from: profile.id,
        to: CoreConstants.appBot,
        releaseItemId: releaseItemId,
        releaseName: releaseItemlist.name,
        authorName: profile.name,
        message: 'Solicitud de aprobación: "${releaseItemlist.name}" por ${profile.name}',
      );

      // Insert the request to Firestore
      final requestId = await RequestFirestore().insert(releaseRequest);

      if (requestId.isNotEmpty) {
        AppConfig.logger.i("Release approval request created with ID: $requestId");

        // Create activity feed for the author (confirmation of submission)
        final authorActivityFeed = ActivityFeed.fromAppBot(
          toProfileId: profile.id,
          referenceId: releaseItemId,
          type: ActivityFeedType.sentRequest,
          message: 'Tu publicación "${releaseItemlist.name}" ha sido enviada para revisión',
          mediaUrl: coverImageUrl,
        );
        await ActivityFeedFirestore().insert(authorActivityFeed);

        AppConfig.logger.i("Author notification sent. Release awaits review by support+ users.");
      }
    } catch (e) {
      AppConfig.logger.w("Failed to create release approval request: $e");
      // Don't throw - this is not critical to the upload process
    }
  }

  @override
  Future<void> createReleasePost() async {
    AppConfig.logger.d("Creating Post");

    String postCaption = '';

    if(releaseItemlist.ownerType == OwnerType.profile) {
      postCaption = '${ReleaseTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${releaseItemlist.name}"'
          ' ${ReleaseTranslationConstants.releaseUploadPostCaptionMsg2.tr}';
    } else {
      postCaption = '${ReleaseTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${releaseItemlist.name}",'
          ' ${AppTranslationConstants.of.tr} ${ReleaseTranslationConstants.myProject.tr} "${selectedBand.value.name}",'
          ' ${ReleaseTranslationConstants.releaseUploadPostCaptionMsg2.tr}';
    }

    try {
      Post post = Post(
        type: PostType.releaseItem,
        profileName: profile.name,
        profileImgUrl: profile.photoUrl,
        ownerId: profile.id,
        mediaUrl: releaseItemlist.imgUrl,
        referenceId: releaseItemlist.appReleaseItems?.first.id ?? '',
        position: releaseItemlist.position ?? profile.position,
        location: await GeoLocatorController().getAddressSimple(releaseItemlist.position ?? profile.position!),
        isCommentEnabled: true,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        caption: postCaption,
        verificationLevel: profile.verificationLevel,
        lastInteraction: DateTime.now().millisecondsSinceEpoch,
      );

      post.id = await PostFirestore().insert(post);

      if(post.id.isNotEmpty){
        // Add post directly to timeline cache so it's visible immediately on Home
        if (Sint.isRegistered<TimelineService>()) {
          Sint.find<TimelineService>().addNewPostToTimeline(post);
        }

        if(!kDebugMode) {
          FirebaseMessagingCalls.sendPublicPushNotification(
              fromProfile: profile,
              toProfileId: '',
              notificationType: PushNotificationType.releaseAppItemAdded,
              title: ReleaseTranslationConstants.addedReleaseAppItem,
              referenceId: appReleaseItem.value.id,
              imgUrl: appReleaseItem.value.imgUrl
          );
        }

      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'createReleasePost');
    }

  }

  @override
  Future<void> getPublisherPlace(context) async {
    AppConfig.logger.t("");

    try {
      Prediction prediction = await mapsServiceImpl!.placeAutoComplete(context, placeController.text);
      publisherPlace.value = await mapsServiceImpl!.predictionToGooglePlace(prediction);
      mapsServiceImpl!.goToPosition(publisherPlace.value.position!);
      placeController.text = publisherPlace.value.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }

    AppConfig.logger.d("PublisherPlace: ${publisherPlace.value.name}");
    update([AppPageIdConstants.releaseUpload]);
  }

  /// Called when a publisher is selected from the search field
  /// If profile is null, the user entered custom text (not a registered user)
  void onPublisherSelected(AppProfile? profile) {
    AppConfig.logger.d("Publisher selected: ${profile?.name ?? placeController.text}");
    publisherProfile.value = profile;

    if (profile != null) {
      // Create a Place from the profile data
      publisherPlace.value = Place(
        name: profile.name,
        position: profile.position,
      );
    } else {
      // Custom text entered - create Place with just the name
      publisherPlace.value = Place(
        name: placeController.text.trim(),
      );
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateInfo(){
    AppConfig.logger.t("validateInfo");
    // Publisher name is valid if auto-published OR if placeController has text
    // No longer requires coordinates - just the publisher name
    return ((isAutoPublished.value || placeController.text.trim().isNotEmpty)
        && (mediaUploadServiceImpl?.mediaFileExists() ?? false));
  }

  @override
  void setPublishedYear(int year) {
    AppConfig.logger.t("setPublishedYear $year");
    publishedYear.value = year;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsPhysical() async {
    AppConfig.logger.d("");
    isPhysical.value = !isPhysical.value;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsAutoPublished() async {
    AppConfig.logger.t("setIsAutoPublished");
    isAutoPublished.value = !isAutoPublished.value;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistName() {
    AppConfig.logger.t("setItemlistName");
    releaseItemlist.name = itemlistNameController.text.trim().capitalizeFirst;
    appReleaseItem.value.metaName = releaseItemlist.name;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistDesc() {
    AppConfig.logger.d("setItemlistDesc");
    releaseItemlist.description = itemlistDescController.text.trim().capitalizeFirst;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseAuthor() {
    AppConfig.logger.t("setReleaseAuthor");
    appReleaseItem.value.ownerName = authorController.text.trim().capitalizeFirst;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseTitle() {
    AppConfig.logger.t("setReleaseTitle");
    appReleaseItems.value.removeWhere((element) => element.name == appReleaseItem.value.name); ///VERIFY IF OK
    appReleaseItem.value.name = titleController.text.trim().capitalizeFirst;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseDesc() {
    AppConfig.logger.t("setReleaseDesc");
    appReleaseItem.value.description = descController.text;
    appReleaseItem.value.lyrics = descController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  void setReleaseDuration() {
    AppConfig.logger.d("");
    if(durationController.text.isNotEmpty) {
      appReleaseItem.value.duration = int.parse(durationController.text);
    }

    durationIsSelected = true;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateItemlistNameDesc() {
    return itemlistNameController.text.isNotEmpty
        && itemlistDescController.text.isNotEmpty;
  }

  @override
  bool validateNameDesc() {
    return titleController.text.isNotEmpty && (descController.text.isNotEmpty || releaseItemsQty.value > 1)
        && appReleaseItem.value.previewUrl.isNotEmpty && durationController.text.isNotEmpty && releaseFilePreviewURL.isNotEmpty;
  }

  Future<void> addGenresToReleaseItem() async {
    AppConfig.logger.d("Adding ${genres.length} to release.");

    try {
      appReleaseItem.value.categories = selectedGenres;

      // Save progress to cache
      await cacheController.updateDraft(step: ReleaseUploadStep.genresSet);

      addReleaseItemToList();
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addGenresToReleaseItem');
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addReleaseItemToList() async {
    AppConfig.logger.d("Adding ${appReleaseItem.value.name} to itemList ${releaseItemlist.name}.");
    AppConfig.logger.d("  item state: previewUrl=\"${appReleaseItem.value.previewUrl}\", "
        "imgUrl=\"${appReleaseItem.value.imgUrl}\", mediaType=${appReleaseItem.value.mediaType?.name}, "
        "owner=${appReleaseItem.value.ownerName}, releaseFilePath=\"$releaseFilePath\"");

    try {
      appReleaseItems.value.removeWhere((element) => element.name == appReleaseItem.value.name);

      if(appReleaseItems.length < releaseItemsQty.value) {
        appReleaseItems.add(AppReleaseItem.fromJSON(appReleaseItem.value.toJSON()));
        releaseFilePaths.add(releaseFilePath);
        AppConfig.logger.d("  → items count: ${appReleaseItems.length}/${releaseItemsQty.value}, filePaths: ${releaseFilePaths.length}");
      }

      // Save release items to cache
      await cacheController.updateDraft(
        releaseItems: appReleaseItems.toList(),
        releaseFilePaths: releaseFilePaths,
      );

      if(appReleaseItems.length == releaseItemsQty.value) {
        Sint.toNamed(AppRouteConstants.releaseUploadInfo);
      } else {
        gotoNextItemNameDesc();
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addReleaseItemToList');
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addNameDescToReleaseItem() async {
    AppConfig.logger.t("addNameDescToReleaseItem");
    audioLitePlayerServiceImpl!.stop();

    if(appReleaseItems.where((element) => element.name == titleController.text.trim()).isEmpty) {
      setReleaseTitle();
      setReleaseDesc();

      if(AppConfig.instance.appInUse == AppInUse.e) {
        setReleaseDuration();
        setPhysicalReleasePrice();
        ///DEPRECATED setDigitalReleasePrice();
      }

      Sint.toNamed(AppRouteConstants.releaseUploadInstr);
    } else {
      AppUtilities.showSnackBar(title: ReleaseTranslationConstants.releaseUpload, message: ReleaseTranslationConstants.releaseItemNameMsg);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addItemlistNameDesc() async {
    AppConfig.logger.t("addItemlistNameDesc");
    setItemlistName();
    setItemlistDesc();
    Sint.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  void setPhysicalReleasePrice() {
    AppConfig.logger.d("Setting physical release price to ${physicalPriceController.text.isNotEmpty ? physicalPriceController.text : null}");

    if(physicalPriceController.text.isNotEmpty) {
      if(double.parse(physicalPriceController.text) > 0) {
        isPhysical.value = true;
        appReleaseItem.value.physicalPrice ??= Price(currency: AppCurrency.mxn);
        appReleaseItem.value.physicalPrice!.amount = double.parse(physicalPriceController.text);
      } else {
        appReleaseItem.value.physicalPrice = null;
        isPhysical.value = false;
      }
    } else {
      appReleaseItem.value.physicalPrice = null;
      isPhysical.value = false;
    }

    durationIsSelected = false;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> gotoReleaseSummary() async {
    AppConfig.logger.i("━━━ PRE-UPLOAD SUMMARY ━━━");
    AppConfig.logger.d("  itemlist: name=\"${releaseItemlist.name}\", type=${releaseItemlist.type}, imgUrl=\"${releaseItemlist.imgUrl}\"");
    AppConfig.logger.d("  releaseCoverImgPath: \"${releaseCoverImgPath.value}\"");
    AppConfig.logger.d("  mediaUpload: fileExists=${mediaUploadServiceImpl?.mediaFileExists()}, "
        "bytes=${mediaUploadServiceImpl?.mediaBytes != null ? "${mediaUploadServiceImpl!.mediaBytes!.length}" : "null"}");
    AppConfig.logger.d("  appReleaseItems: ${appReleaseItems.length}, releaseFilePaths: ${releaseFilePaths.length}");
    for (int i = 0; i < appReleaseItems.length; i++) {
      final ri = appReleaseItems[i];
      AppConfig.logger.d("    [$i] name=\"${ri.name}\", previewUrl=\"${ri.previewUrl}\", imgUrl=\"${ri.imgUrl}\", mediaType=${ri.mediaType?.name}");
    }

    try {

      for (AppReleaseItem releaseItem in appReleaseItems) {

        if(releaseItem.imgUrl.isEmpty) {
          releaseItem.imgUrl = releaseCoverImgPath.isNotEmpty ? releaseCoverImgPath.value : AppProperties.getAppLogoUrl();
          AppConfig.logger.d("  Set imgUrl fallback for \"${releaseItem.name}\" → \"${releaseItem.imgUrl}\"");
        }
        releaseItem.publishedYear = publishedYear.value;

        if(physicalPriceController.text.isNotEmpty) setPhysicalReleasePrice();
        releaseItem.physicalPrice = appReleaseItem.value.physicalPrice;

        if(isAutoPublished.value) {
          appReleaseItem.value.place = null;
          appReleaseItem.value.metaOwner = ReleaseTranslationConstants.selfPublished.tr;
        } else {
          appReleaseItem.value.place = publisherPlace.value;
          appReleaseItem.value.metaOwner = publisherPlace.value.name;
        }

      }

      if(appReleaseItem.value.type == ReleaseType.single) {
        releaseItemlist.name = appReleaseItem.value.name;
        releaseItemlist.description = appReleaseItem.value.description;
      }

      // Save all info to cache before going to summary
      await cacheController.updateDraft(
        step: ReleaseUploadStep.infoSet,
        itemlist: releaseItemlist,
        releaseItems: appReleaseItems.toList(),
        publisherPlace: publisherPlace.value,
        isAutoPublished: isAutoPublished.value,
        publishedYear: publishedYear.value,
        coverImageLocalPath: releaseCoverImgPath.value,
      );

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'gotoReleaseSummary');
    }

    Sint.toNamed(AppRouteConstants.releaseUploadSummary);
    update([AppPageIdConstants.releaseUpload]);
  }

  RubberAnimationController getRubberAnimationController() {
    return RubberAnimationController(
        vsync: this,
        lowerBoundValue: AnimationControllerValue(pixel: 400),
        dismissable: false,
        upperBoundValue: AnimationControllerValue(percentage: 0.9),
        duration: const Duration(milliseconds: 300),
        springDescription: SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: Stiffness.LOW,
          ratio: DampingRatio.MEDIUM_BOUNCY,
        )
    );
  }

  @override
  Future<void> addReleaseCoverImg() async {
    AppConfig.logger.t("addReleaseCoverImg");
    if (mediaUploadServiceImpl == null) {
      AppUtilities.showSnackBar(
        title: ReleaseTranslationConstants.releaseUpload,
        message: CommonTranslationConstants.notAvailable,
      );
      return;
    }
    try {
      await mediaUploadServiceImpl!.handleImage(
        uploadDestination: MediaUploadDestination.releaseItem,
        crop: false,
        ratioX: AppConfig.instance.appInUse != AppInUse.e ? 1 : 6,
        ratioY: AppConfig.instance.appInUse != AppInUse.e ? 1 : 9,
      );

      if(mediaUploadServiceImpl!.mediaFileExists()) {
        releaseCoverImgPath.value = mediaUploadServiceImpl!.getMediaFile().path;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addReleaseCoverImg');
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    AppConfig.logger.d("clearReleaseCoverImg");
    try {
      mediaUploadServiceImpl?.clearMedia();
      releaseCoverImgPath.value = '';
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'clearReleaseCoverImg');
    }

  }

  @override
  void addGenre(Genre genre) {
    selectedGenres.add(genre.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeGenre(Genre genre){
    selectedGenres.removeWhere((String name) {
      return name == genre.name;
      }
    );

    update([AppPageIdConstants.releaseUpload]);
  }

  Iterable<Widget> get genreChips sync* {

    for (Genre genre in genres) {
      yield Padding(
        padding: const EdgeInsets.all(5.0),
        child: FilterChip(
          backgroundColor: AppColor.surfaceBright,
          avatar: CircleAvatar(
            backgroundColor: Colors.cyan,
            child: Text(genre.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          label: Text(genre.name.capitalize, style: const TextStyle(fontSize: 15),),
          selected: selectedGenres.contains(genre.name),
          selectedColor: AppColor.surfaceCard,
          onSelected: (bool selected) {
            if (selected) {
              addGenre(genre);
            } else {
              removeGenre(genre);
            }
          },
        ),
      );
    }
  }

  Widget getCoverImageWidget(BuildContext context) {

    Widget cachedNetworkImage;
    bool containsCroppedImgFile = mediaUploadServiceImpl?.mediaFileExists() ?? false;
    String itemImgUrl = appReleaseItem.value.imgUrl.isNotEmpty
        ? appReleaseItem.value.imgUrl
        : releaseItemlist.imgUrl.isNotEmpty
            ? releaseItemlist.imgUrl
            : AppProperties.getAppLogoUrl();

    final coverWidth = (kIsWeb ? 800.0 : AppTheme.fullWidth(context)) * 0.45;

    try {
      if(!kIsWeb && containsCroppedImgFile) {
        String croppedImgFilePath = mediaUploadServiceImpl!.getMediaFile().path;
        cachedNetworkImage = Image.file(
            File(croppedImgFilePath) as dynamic,
            width: coverWidth
        );
      } else if(!kIsWeb && releaseCoverImgPath.value.isNotEmpty && File(releaseCoverImgPath.value).existsSync()) {
        cachedNetworkImage = Image.file(
            File(releaseCoverImgPath.value) as dynamic,
            width: coverWidth
        );
      } else {
        cachedNetworkImage = HandledCachedNetworkImage(
            itemImgUrl,
            width: coverWidth,
            enableFullScreen: false,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'getCoverImageWidget');
      cachedNetworkImage = HandledCachedNetworkImage(itemImgUrl,
          width: coverWidth,
          enableFullScreen: false,
      );
    }

    return cachedNetworkImage;
  }

  @override
  Future<void> addReleaseFile() async {
    AppConfig.logger.d("Handling Release File From Gallery");

    if (mediaUploadServiceImpl == null) {
      AppUtilities.showSnackBar(
        title: ReleaseTranslationConstants.releaseUpload,
        message: CommonTranslationConstants.notAvailable,
      );
      return;
    }

    try {

      await mediaUploadServiceImpl!.pickMultipleMedia();

      if(mediaUploadServiceImpl!.releaseFiles.isNotEmpty) {
        AppConfig.logger.d("Found ${mediaUploadServiceImpl!.releaseFiles.length} files");
        String releaseFileFirstName = FileSystemUtilities.getFileNameWithExtension(mediaUploadServiceImpl!.releaseFiles.first.path);
        if(appReleaseItems.where((element) => element.previewUrl == releaseFileFirstName).isNotEmpty) {
          AppUtilities.showSnackBar(
              title: ReleaseTranslationConstants.releaseUpload,
              message: ReleaseTranslationConstants.releaseItemFileMsg,
              duration: const Duration(seconds: 5)
          );
          return;
        }

        releaseFilePath = mediaUploadServiceImpl!.getReleaseFilePath();
        appReleaseItem.value.previewUrl = releaseFileFirstName;
        releaseFilePreviewURL.value = releaseFileFirstName;

        if(titleController.text.isEmpty) {
          AppConfig.logger.d("Setting name from file name");
          String tempTitleName = '';
          if(releaseFilePreviewURL.contains(".mp3")) {
            tempTitleName = releaseFilePreviewURL.split(".mp3").first;
          } else if(releaseFilePreviewURL.contains(".pdf")) {
            tempTitleName = releaseFilePreviewURL.split(".pdf").first;
          }
          tempTitleName = tempTitleName.replaceAll(authorController.text, '');
          tempTitleName = tempTitleName.replaceAll(RegExp(r'^[\s\-_]+'), '').trim();
          titleController.text = tempTitleName;
        }

        if(audioLitePlayerServiceImpl != null && appReleaseItem.value.isAudioContent) {
          await audioLitePlayerServiceImpl!.stop();
          audioLitePlayerServiceImpl!.setFilePath(releaseFilePath);
          await audioLitePlayerServiceImpl!.play();
          appReleaseItem.value.duration = audioLitePlayerServiceImpl!.durationInSeconds;
          durationController.text = appReleaseItem.value.duration.toString();
          if(appReleaseItem.value.duration > 0 && appReleaseItem.value.duration <= CoreConstants.maxAudioDuration) {
            AppConfig.logger.i("Audio duration of ${appReleaseItem.value.duration} seconds");
          } else {
            releaseFilePath = '';
            appReleaseItem.value.previewUrl = '';
            AppUtilities.showSnackBar(title: ReleaseTranslationConstants.releaseUpload, message: ReleaseTranslationConstants.releaseItemDurationMsg);
          }
        } else if (releaseFilePreviewURL.value.toLowerCase().endsWith('.pdf')) {
          // Extract PDF page count for EMXI
          await _extractPdfPageCount(releaseFilePath);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addReleaseFile');
    }

    ///DEPRECATED update([AppPageIdConstants.releaseUpload]);
  }

  /// Picks multiple audio files and populates the track list for web album uploads.
  /// Returns the number of tracks added. Each file becomes a track in appReleaseItems.
  Future<int> addReleaseFilesWeb() async {
    AppConfig.logger.d("addReleaseFilesWeb — multi-track pick");

    if (mediaUploadServiceImpl == null) {
      AppUtilities.showSnackBar(
        title: ReleaseTranslationConstants.releaseUpload,
        message: CommonTranslationConstants.notAvailable,
      );
      return 0;
    }

    try {
      await mediaUploadServiceImpl!.pickMultipleMedia();
      final pickedFiles = mediaUploadServiceImpl!.releaseFiles;
      if (pickedFiles.isEmpty) return 0;

      AppConfig.logger.d("Web picked ${pickedFiles.length} files");

      // Clear previous tracks and paths
      appReleaseItems.clear();
      releaseFilePaths.clear();

      for (int i = 0; i < pickedFiles.length; i++) {
        final fileName = mediaUploadServiceImpl!.getReleaseFileName(i);
        if (fileName.isEmpty) continue;

        // Extract track name from file name
        String trackName = fileName;
        if (trackName.contains('.')) {
          trackName = trackName.substring(0, trackName.lastIndexOf('.'));
        }
        // Clean up common prefixes (track numbers like "01 - ", "01. ")
        trackName = trackName.replaceAll(RegExp(r'^\d+[\s.\-_]+'), '').trim();

        final trackItem = AppReleaseItem.fromJSON(appReleaseItem.value.toJSON());
        trackItem.name = trackName;
        trackItem.previewUrl = fileName;
        trackItem.ownerEmail = user.email;
        trackItem.ownerName = authorController.text.trim();
        trackItem.galleryUrls = [profile.photoUrl];
        trackItem.ownerType = OwnerType.profile;

        appReleaseItems.add(trackItem);
        releaseFilePaths.add(fileName); // On web, just the filename
      }

      // Update quantity to match picked files
      releaseItemsQty.value = appReleaseItems.length;
      releaseFilePreviewURL.value = '${appReleaseItems.length} tracks';

      update([AppPageIdConstants.releaseUpload]);
      return appReleaseItems.length;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'addReleaseFilesWeb');
    }
    return 0;
  }

  /// Removes a track from the web track list by index.
  void removeTrackAt(int index) {
    if (index >= 0 && index < appReleaseItems.length) {
      appReleaseItems.removeAt(index);
      if (index < releaseFilePaths.length) {
        releaseFilePaths.removeAt(index);
      }
      releaseItemsQty.value = appReleaseItems.length;
      releaseFilePreviewURL.value = appReleaseItems.isNotEmpty
          ? '${appReleaseItems.length} tracks' : '';
      update([AppPageIdConstants.releaseUpload]);
    }
  }

  /// Reorders tracks in the web track list.
  void reorderTrack(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = appReleaseItems.removeAt(oldIndex);
    appReleaseItems.insert(newIndex, item);
    if (oldIndex < releaseFilePaths.length && newIndex <= releaseFilePaths.length) {
      final path = releaseFilePaths.removeAt(oldIndex);
      releaseFilePaths.insert(newIndex, path);
    }
    update([AppPageIdConstants.releaseUpload]);
  }

  /// Updates the name of a track at the given index.
  void updateTrackName(int index, String name) {
    if (index >= 0 && index < appReleaseItems.length) {
      appReleaseItems[index].name = name;
      update([AppPageIdConstants.releaseUpload]);
    }
  }

  /// Extracts the page count from a PDF file and sets it in durationController
  Future<void> _extractPdfPageCount(String pdfPath) async {
    try {
      AppConfig.logger.d("Extracting PDF page count from: $pdfPath");
      final document = await PdfDocument.openFile(pdfPath);
      final pageCount = document.pagesCount;
      await document.close();

      appReleaseItem.value.duration = pageCount;
      durationController.text = pageCount.toString();
      AppConfig.logger.i("PDF page count extracted: $pageCount pages");

      update([AppPageIdConstants.releaseUpload]);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: '_extractPdfPageCount');
      // Don't clear the file, just log the error - user can still enter manually
    }
  }


  List<int> getYearsList() {
    int startYear = CoreConstants.firstReleaseYear;
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - startYear + 1, (index) => startYear + index);
  }

  void gotoPdfPreview() {
    releaseFilePath = mediaUploadServiceImpl!.getReleaseFilePath();

    AppReleaseItem previewItem = AppReleaseItem(
      previewUrl: releaseFilePath,
      duration: int.parse(durationController.text),
    );
    Sint.toNamed(AppRouteConstants.readingPath(previewItem.id),
        arguments: [previewItem, false]);
  }

  void increase() {
    if(durationIsSelected) {
      int currentValue = int.tryParse(durationController.text) ?? 0;
      durationController.text = (currentValue + 1).toString();
    } else {
      int currentValue = int.tryParse(physicalPriceController.text) ?? 0;
      physicalPriceController.text = (currentValue + 1).toString();
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  void decrease() {
    if(durationIsSelected) {
      int currentValue = int.tryParse(durationController.text) ?? 0;
      if (currentValue > 0) {
        durationController.text = (currentValue - 1).toString();
      }
    } else {
      int currentValue = int.tryParse(physicalPriceController.text) ?? 0;
      if (currentValue > 0) {
        physicalPriceController.text = (currentValue - 1).toString();
      }
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  void gotoNextItemNameDesc() {
    AppConfig.logger.d('Removing info from textControllers to insert next item info');
    titleController.clear();
    descController.clear();
    appReleaseItem.value.name = '';
    releaseFilePreviewURL.value = '';
    Sint.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  void removeLastReleaseItem() {
    AppConfig.logger.d('Removing last item from list to update it and add it again');
    releaseFilePreviewURL.value = appReleaseItems.last.previewUrl;
    appReleaseItem.value.name = appReleaseItems.last.name;
    titleController.text = appReleaseItems.last.name;
    descController.text = appReleaseItems.last.description;
    appReleaseItems.removeLast();
    releaseFilePaths.removeLast();

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setSelectedBand(Band band) async {
    AppConfig.logger.d("Going to Upload Release for Band: ${band.name}");
    selectedBand.value = band;

    try {
      if(selectedBand.value.members != null) {
        for (var bandMember in selectedBand.value.members!.values) {
          if (bandMember.instrument != null) {
            bandInstruments.add(bandMember.instrument!.name);
          }
        }
        appReleaseItem.value.instruments = bandInstruments;
      }

      appReleaseItem.value.ownerEmail = selectedBand.value.email;
      appReleaseItem.value.ownerName = selectedBand.value.name;
      appReleaseItem.value.galleryUrls = [selectedBand.value.photoUrl];
      appReleaseItem.value.ownerType = OwnerType.band;

      releaseItemlist.ownerId = selectedBand.value.id;
      releaseItemlist.ownerName = selectedBand.value.name;
      releaseItemlist.ownerType = OwnerType.band;
      if (selectedBand.value.position?.latitude != 0.0) {
        releaseItemlist.position = selectedBand.value.position!;
      }

      // Save progress to cache
      await cacheController.updateDraft(
        step: ReleaseUploadStep.bandOrSoloSelected,
        itemlist: releaseItemlist,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'setSelectedBand');
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setAsSolo() async {
    AppConfig.logger.d("Going to Upload Release as Soloist");

    try {
      selectedBand.value = Band();
      bandInstruments = [];

      appReleaseItem.value.ownerEmail = user.email;
      appReleaseItem.value.ownerName = authorController.text.trim();
      appReleaseItem.value.galleryUrls = [profile.photoUrl];
      appReleaseItem.value.ownerType = OwnerType.profile;

      releaseItemlist.ownerId = profile.id;
      releaseItemlist.ownerName = authorController.text.trim();
      releaseItemlist.ownerType = OwnerType.profile;

      if (profile.position?.latitude != 0.0) {
        releaseItemlist.position = profile.position!;
      }

      // Save progress to cache
      await cacheController.updateDraft(
        step: ReleaseUploadStep.bandOrSoloSelected,
        itemlist: releaseItemlist,
      );

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'setAsSolo');
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void showUploadModal(BuildContext context) {
    AppConfig.logger.d("showUploadModal");
    ReleaseUploadWebModal.show(context);
  }

  void gotoNameDesc() {
    if (isWebMode) return; // Web modal handles its own navigation
    if(AppConfig.instance.appInUse != AppInUse.g || appReleaseItem.value.type == ReleaseType.single) {
      Sint.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } else {
      Sint.toNamed(AppRouteConstants.releaseUploadItemlistNameDesc);
    }
  }

  /// Sets release type without navigating to the next page.
  /// Used by the web single-page form (ReleaseUploadWebPage).
  void setReleaseTypeWeb(ReleaseType releaseType) {
    AppConfig.logger.d("setReleaseTypeWeb: ${releaseType.name}");

    if(profile.verificationLevel == VerificationLevel.none) {
      if(releaseType != ReleaseType.single) {
        AppUtilities.showSnackBar(
            title: ReleaseTranslationConstants.digitalPositioning,
            message: ReleaseTranslationConstants.freeSingleReleaseUploadMsg.tr
        );
        return;
      } else if(userServiceImpl.user.releaseItemIds?.isNotEmpty ?? false) {
        AppUtilities.showSnackBar(
            title: ReleaseTranslationConstants.digitalPositioning,
            message: ReleaseTranslationConstants.freeSingleReleaseUploadMsg.tr
        );
        return;
      }
    }

    switch(releaseType) {
      case ReleaseType.single:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.single;
        break;
      case ReleaseType.ep:
        releaseItemsQty.value = 2;
        releaseItemlist.type = ItemlistType.ep;
        break;
      case ReleaseType.album:
        releaseItemsQty.value = 4;
        releaseItemlist.type = ItemlistType.album;
        break;
      case ReleaseType.demo:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.demo;
        break;
      case ReleaseType.episode:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.podcast;
        break;
      case ReleaseType.chapter:
        releaseItemsQty.value = 1;
        releaseItemlist.type = ItemlistType.audiobook;
        break;
    }

    appReleaseItems.clear();

    // Set as solo for web single-page flow (skip band selection)
    selectedBand.value = Band();
    bandInstruments = [];
    appReleaseItem.value.ownerEmail = user.email;
    appReleaseItem.value.ownerName = authorController.text.trim();
    appReleaseItem.value.galleryUrls = [profile.photoUrl];
    appReleaseItem.value.ownerType = OwnerType.profile;
    releaseItemlist.ownerId = profile.id;
    releaseItemlist.ownerName = authorController.text.trim();
    releaseItemlist.ownerType = OwnerType.profile;
    if (profile.position?.latitude != 0.0) {
      releaseItemlist.position = profile.position!;
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  /// Creates a release directly from the web single-page form.
  /// Combines all the logic from addNameDescToReleaseItem + addInstrumentsToReleaseItem
  /// + addGenresToReleaseItem + gotoReleaseSummary + submitRelease without navigation.
  Future<void> createReleaseDirect(BuildContext context) async {
    AppConfig.logger.d("createReleaseDirect — web single-page flow");

    try {
      // 1. Set name/desc/duration/price
      setReleaseTitle();
      setReleaseDesc();
      if (AppConfig.instance.appInUse == AppInUse.e) {
        setReleaseDuration();
        setPhysicalReleasePrice();
      }

      // 2. Instruments are already set via chip selection (addInstrument/removeInstrument)
      appReleaseItem.value.instruments = instrumentsUsed;

      // 3. Genres/categories are already set via chip selection (addGenre/removeGenre)
      appReleaseItem.value.categories = selectedGenres;

      // 4. Add release items to list
      // On web with multi-track (album/EP), tracks are already populated by addReleaseFilesWeb().
      // For singles or if tracks weren't pre-populated, add the current item.
      if (appReleaseItems.isEmpty) {
        appReleaseItems.add(AppReleaseItem.fromJSON(appReleaseItem.value.toJSON()));
        releaseFilePaths.add(releaseFilePath);
      }

      // 5. Set final metadata on all items (same as gotoReleaseSummary)
      final place = isAutoPublished.value ? null : publisherPlace.value;
      final metaOwner = isAutoPublished.value
          ? ReleaseTranslationConstants.selfPublished.tr
          : publisherPlace.value.name;

      for (AppReleaseItem releaseItem in appReleaseItems) {
        if (releaseItem.imgUrl.isEmpty) {
          releaseItem.imgUrl = releaseCoverImgPath.isNotEmpty
              ? releaseCoverImgPath.value
              : AppProperties.getAppLogoUrl();
        }
        releaseItem.publishedYear = publishedYear.value;
        if (physicalPriceController.text.isNotEmpty) setPhysicalReleasePrice();
        releaseItem.physicalPrice = appReleaseItem.value.physicalPrice;
        releaseItem.place = place;
        releaseItem.metaOwner = metaOwner;
        // Propagate shared metadata to all tracks
        if (releaseItem.instruments == null || releaseItem.instruments!.isEmpty) {
          releaseItem.instruments = instrumentsUsed;
        }
        if (releaseItem.categories.isEmpty) {
          releaseItem.categories = selectedGenres;
        }
        releaseItem.ownerEmail = user.email;
        releaseItem.ownerName = authorController.text.trim();
      }

      // For singles, use the item name as the itemlist name
      if (appReleaseItem.value.type == ReleaseType.single) {
        releaseItemlist.name = appReleaseItem.value.name;
        releaseItemlist.description = appReleaseItem.value.description;
      }

      // 6. Save to cache
      await cacheController.updateDraft(
        step: ReleaseUploadStep.infoSet,
        itemlist: releaseItemlist,
        releaseItems: appReleaseItems.toList(),
        publisherPlace: publisherPlace.value,
        isAutoPublished: isAutoPublished.value,
        publishedYear: publishedYear.value,
        coverImageLocalPath: releaseCoverImgPath.value,
      );

      // 7. Submit (same as submitRelease)
      submitRelease(context);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'createReleaseDirect');
      AppUtilities.showSnackBar(
        title: ReleaseTranslationConstants.releaseUpload,
        message: e.toString(),
      );
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> submitRelease(BuildContext context) async {
   AppConfig.logger.i('━━━ SUBMIT RELEASE ━━━');
   AppConfig.logger.d('  demoEnabled=${AppConfig.instance.appInfo.demoReleaseEnabled}, '
       'subscription=${userServiceImpl.userSubscription?.status?.name}');

   if(AppConfig.instance.appInfo.demoReleaseEnabled || userServiceImpl.userSubscription?.status == SubscriptionStatus.active) {
     // Validate required fields before proceeding
     final missingFields = <String>[];
     if (appReleaseItem.value.name.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseTitle.tr);
     if (appReleaseItem.value.description.isEmpty && releaseItemlist.description.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseDesc.tr);
     if (appReleaseItem.value.previewUrl.isEmpty && releaseFilePaths.isEmpty) missingFields.add(ReleaseTranslationConstants.addReleaseFile.tr);
     if (!(mediaUploadServiceImpl?.mediaFileExists() ?? false) && releaseCoverImgPath.value.isEmpty
         && appReleaseItem.value.imgUrl.isEmpty && releaseItemlist.imgUrl.isEmpty) {
       missingFields.add(ReleaseTranslationConstants.addReleaseCoverImg.tr);
     }
     if (appReleaseItem.value.categories.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseUploadGenres.tr);

     AppConfig.logger.d('  Validation: name=${appReleaseItem.value.name.isNotEmpty}, '
         'desc=${appReleaseItem.value.description.isNotEmpty || releaseItemlist.description.isNotEmpty}, '
         'file=${appReleaseItem.value.previewUrl.isNotEmpty || releaseFilePaths.isNotEmpty}, '
         'cover=${(mediaUploadServiceImpl?.mediaFileExists() ?? false) || releaseCoverImgPath.value.isNotEmpty || appReleaseItem.value.imgUrl.isNotEmpty || releaseItemlist.imgUrl.isNotEmpty}, '
         'genres=${appReleaseItem.value.categories.isNotEmpty}');

     if (missingFields.isNotEmpty) {
       AppConfig.logger.w('  ⚠ Missing fields: ${missingFields.join(", ")}');
       AppUtilities.showSnackBar(
         title: ReleaseTranslationConstants.releaseUpload,
         message: '${ReleaseTranslationConstants.missingRequiredFields.tr}: ${missingFields.join(', ')}',
         duration: const Duration(seconds: 4),
       );
       return;
     }

     // When revision is disabled, always ask if user wants to share publicly
     // When revision is enabled, releases go to review first (don't share publicly)
     if (!AppConfig.instance.appInfo.releaseRevisionEnabled) {
       // Show confirmation dialog asking if user wants to share publicly
       final shouldShare = await DialogFactory.showConfirmDialog(
         context: context,
         title: ReleaseTranslationConstants.sharePubliclyTitle.tr,
         message: ReleaseTranslationConstants.sharePubliclyMessage.tr,
         confirmText: ReleaseTranslationConstants.sharePubliclyYes.tr,
         cancelText: ReleaseTranslationConstants.sharePubliclyNo.tr,
         icon: Icons.share_rounded,
       );
       sharePublicly = shouldShare;
     } else {
       // Releases need review first, don't share publicly
       sharePublicly = false;
     }

     uploadReleaseItem();
   } else {
     AppAlerts.getSubscriptionAlert(Sint.find<SubscriptionService>(), context, AppRouteConstants.releaseUpload);
   }
  }

  Future<void> uploadMedia() async {
    AppConfig.logger.d("Initiating Upload for Media ${releaseItemlist.name} "
        "- Type: ${releaseItemlist.type} with ${appReleaseItems.length} items");

    String releaseCoverImgURL = '';

    releaseItemIndex.value = 0;
    isLoading.value = true;
    update([AppPageIdConstants.releaseUpload]);

    try {

      if(mediaUploadServiceImpl!.mediaFileExists()) {
        AppConfig.logger.d("Uploading releaseCoverImg from: ${mediaUploadServiceImpl!.getMediaFile().path}");
        releaseCoverImgURL = await wooMediaServiceImpl.uploadMediaToWordPress(mediaUploadServiceImpl!.getMediaFile(), fileName: releaseItemlist.name);
        releaseItemlist.imgUrl = releaseCoverImgURL;
      }

      for (AppReleaseItem releaseItem in appReleaseItems) {
        releaseItem.imgUrl = releaseItemlist.imgUrl;
        releaseItem.categories = [];
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlist.id;
        releaseItem.state = 5;

        releaseItem.status = AppConfig.instance.appInfo.releaseRevisionEnabled
            ? ReleaseStatus.pending : ReleaseStatus.publish;

        if(releaseItem.previewUrl.isNotEmpty) {
          AppConfig.logger.i("Uploading file: ${releaseItem.previewUrl}");
          String fileExtension = releaseItem.previewUrl.split('.').last.toLowerCase();

          AppMediaType mediaType = AppMediaType.audio;
          if(fileExtension == "mp3") {
            mediaType = AppMediaType.audio;
          } else if (fileExtension == "pdf") {
            mediaType = AppMediaType.text;
          }

          String filePath = releaseFilePaths.elementAt(releaseItemIndex.value);

          File fileToUpload = await FileSystemUtilities.getFileFromPath(filePath);

          if(AppProperties.mediaToWordpressFlag()) {
            releaseItem.previewUrl = await wooMediaServiceImpl.uploadMediaToWordPress(fileToUpload, fileName: releaseItem.name);
          } else {
            releaseItem.previewUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);
          }

          AppConfig.logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      AppUtilities.showSnackBar(
          title: ReleaseTranslationConstants.digitalPositioning,
          message: ReleaseTranslationConstants.digitalPositioningSuccess.tr
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'uploadMedia');
      AppUtilities.showSnackBar(title: ReleaseTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

    isLoading.value = false;
    update();
  }

  Future<void> playPreview(AppReleaseItem item) async {
    if(audioLitePlayerServiceImpl == null) return;
    AppConfig.logger.d("Playing preview for item: ${item.name} - ${item.previewUrl}");

    try {
      if(isPlaying && previewPath.contains(item.previewUrl)) {
        await audioLitePlayerServiceImpl!.stop();
        isPlaying = false;
      } else {
        await audioLitePlayerServiceImpl!.stop();
        // Try multi-track paths first, fallback to single-track path
        previewPath = releaseFilePaths.isNotEmpty
            ? releaseFilePaths.firstWhere(
                (path) => path.contains(item.previewUrl),
                orElse: () => releaseFilePath,
              )
            : releaseFilePath;
        if(previewPath.isEmpty) return;
        await audioLitePlayerServiceImpl!.setFilePath(previewPath);
        await audioLitePlayerServiceImpl!.play();
        isPlaying = true;
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'playPreview');
      isPlaying = false;
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  /// Toggles play/pause for single-track audio preview in the summary page.
  Future<void> playPreviewSingle() async {
    if(audioLitePlayerServiceImpl == null || releaseFilePath.isEmpty) return;
    AppConfig.logger.d("Playing single preview: $releaseFilePath");

    try {
      if(isPlaying) {
        await audioLitePlayerServiceImpl!.stop();
        isPlaying = false;
      } else {
        await audioLitePlayerServiceImpl!.stop();
        await audioLitePlayerServiceImpl!.setFilePath(releaseFilePath);
        await audioLitePlayerServiceImpl!.play();
        isPlaying = true;
        previewPath = releaseFilePath;
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'playPreviewSingle');
      isPlaying = false;
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  // ── Web Modal Helpers ──

  /// Cover image bytes from web file picker (used by web modal)
  Uint8List? releaseCoverImgBytes;

  /// Web file bytes map: filename → bytes
  final List<MapEntry<String, Uint8List>> _webFileEntries = [];

  void addWebFileBytes(String fileName, Uint8List bytes) {
    _webFileEntries.add(MapEntry(fileName, bytes));
  }

  /// Build release items from the web form data (called before uploadReleaseItem).
  void buildItemsFromWebForm() {
    appReleaseItems.clear();

    // Removed: isEmxi check — using AppFlavour instead

    releaseItemlist.name = titleController.text.trim().isNotEmpty
        ? titleController.text.trim()
        : itemlistNameController.text.trim();
    releaseItemlist.description = descController.text.trim().isNotEmpty
        ? descController.text.trim()
        : itemlistDescController.text.trim();
    releaseItemlist.ownerName = authorController.text.trim().isNotEmpty
        ? authorController.text.trim()
        : profile.name;
    releaseItemlist.ownerType = OwnerType.profile;

    for (int i = 0; i < _webFileEntries.length; i++) {
      final entry = _webFileEntries[i];
      final name = releaseItemsQty.value == 1
          ? titleController.text.trim()
          : entry.key.replaceAll(RegExp(r'\.[^.]+$'), '');

      final item = AppReleaseItem(
        name: name,
        description: descController.text.trim(),
        ownerEmail: user.email,
        ownerName: authorController.text.trim().isNotEmpty ? authorController.text.trim() : profile.name,
        ownerType: OwnerType.profile,
        type: appReleaseItem.value.type,
        mediaType: AppFlavour.singleAcceptsPdf() ? MediaItemType.pdf : MediaItemType.song,
        categories: selectedGenres.toList(),
        galleryUrls: [profile.photoUrl],
        metaOwnerId: user.email,
        boughtUsers: [],
        createdTime: DateTime.now().millisecondsSinceEpoch,
        state: 5,
      );

      // Set previewUrl to filename so the upload gate passes and extension is extractable
      item.previewUrl = entry.key;
      // Generate slug from name for vanity URLs
      item.slug = name.toLowerCase()
          .replaceAll(RegExp(r'[áàäâ]'), 'a')
          .replaceAll(RegExp(r'[éèëê]'), 'e')
          .replaceAll(RegExp(r'[íìïî]'), 'i')
          .replaceAll(RegExp(r'[óòöô]'), 'o')
          .replaceAll(RegExp(r'[úùüû]'), 'u')
          .replaceAll(RegExp(r'[ñ]'), 'n')
          .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      appReleaseItems.add(item);
    }

    // Store bytes in mediaUploadService for the upload pipeline
    if (mediaUploadServiceImpl != null) {
      // Transfer cover bytes so the upload pipeline can find them
      if (releaseCoverImgBytes != null) {
        mediaUploadServiceImpl!.setMediaBytes(releaseCoverImgBytes!);
      }
      for (final entry in _webFileEntries) {
        mediaUploadServiceImpl!.addWebReleaseFileBytes(entry.key, entry.value);
      }
    }
  }

}
