import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
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
import 'package:neom_core/utils/enums/media_upload_destination.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';
import 'package:neom_core/utils/enums/release_status.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_maps_services/domain/models/prediction.dart';
import 'package:pdfx/pdfx.dart';
import 'package:rubber/rubber.dart';
import 'package:sint/sint.dart';

import '../data/release_cache_controller.dart';
import '../utils/constants/release_translation_constants.dart';

class ReleaseUploadController extends SintController with SintTickerProviderStateMixin implements ReleaseUploadService {

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
  late RubberAnimationController rubberAnimationController;
  late RubberAnimationController releaseUploadDetailsAnimationController;

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

    try {
      user = userServiceImpl.user;
      profile = userServiceImpl.profile;

      // Initialize cache controller
      cacheController = Sint.put(ReleaseCacheController());

      scrollController = ScrollController();
      rubberAnimationController = RubberAnimationController(vsync: this, duration: const Duration(milliseconds: 20));
      releaseUploadDetailsAnimationController = getRubberAnimationController();

      ///DEPRECATED
      // digitalPriceController.text = AppFlavour.getInitialPrice();

      mapsServiceImpl!.goToPosition(profile.position!);

      // Check for pending draft
      await _checkForPendingDraft();
    } catch(e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e('Error checking for pending draft: $e');
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
    } catch (e) {
      AppConfig.logger.e('Error resuming from draft: $e');
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
      appReleaseItem.value.digitalPrice = Price(currency: AppCurrency.mxn, amount: double.parse(AppProperties.getInitialPrice()));
      appReleaseItem.value.ownerEmail = user.email;
      appReleaseItem.value.ownerName =  authorController.text;
      appReleaseItem.value.galleryUrls = [profile.photoUrl];
      appReleaseItem.value.categories = [];
      appReleaseItem.value.instruments = [];
      appReleaseItem.value.metaOwnerId = userServiceImpl.user.email;

      genres.value = await CoreUtilities.loadGenres();
    } catch (e) {
      AppConfig.logger.e(e.toString());
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

    try { rubberAnimationController.dispose(); } catch (_) {}
    try { releaseUploadDetailsAnimationController.dispose(); } catch (_) {}

    audioLitePlayerServiceImpl!.clear();
  }

  @override
  Future<void> setReleaseType(ReleaseType releaseType) async {
    AppConfig.logger.d("Release Type as ${releaseType.name}");
    appReleaseItem.value.type = releaseType;
    appReleaseItem.value.imgUrl == "";

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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
      // STEP 1: Upload cover image to WordPress (skip if already uploaded)
      if (resumeStep.index >= ReleaseUploadStep.coverUploaded.index
          && draft?.coverImageRemoteUrl != null && draft!.coverImageRemoteUrl!.isNotEmpty) {
        releaseCoverImgURL = draft.coverImageRemoteUrl!;
        releaseItemlist.imgUrl = releaseCoverImgURL;
        AppConfig.logger.i('Resuming: Cover already uploaded, skipping. URL: $releaseCoverImgURL');
      } else if(mediaUploadServiceImpl!.mediaFileExists()) {
        AppConfig.logger.d("Uploading releaseCoverImg from: ${mediaUploadServiceImpl!.getMediaFile().path}");
        uploadStatusMessage.value = ReleaseTranslationConstants.uploadingCover.tr;
        update([AppPageIdConstants.releaseUpload]);

        releaseCoverImgURL = await wooMediaServiceImpl.uploadMediaToWordPress(
          mediaUploadServiceImpl!.getMediaFile(),
          fileName: releaseItemlist.name
        );

        // CRITICAL: Validate cover upload was successful
        if (releaseCoverImgURL.isEmpty) {
          throw Exception(ReleaseTranslationConstants.coverUploadFailed.tr);
        }

        releaseItemlist.imgUrl = releaseCoverImgURL;

        // Save progress to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.coverUploaded,
          coverImageRemoteUrl: releaseCoverImgURL,
          itemlist: releaseItemlist,
        );
      }

      // STEP 2: Create Itemlist in Firestore (skip if already created)
      if (resumeStep.index >= ReleaseUploadStep.itemlistCreated.index
          && releaseItemlist.id.isNotEmpty) {
        releaseItemlistId = releaseItemlist.id;
        AppConfig.logger.i('Resuming: Itemlist already created, skipping. ID: $releaseItemlistId');
      } else {
        uploadStatusMessage.value = ReleaseTranslationConstants.creatingCatalog.tr;
        update([AppPageIdConstants.releaseUpload]);

        releaseItemlistId = await ItemlistFirestore().insert(releaseItemlist);

        // CRITICAL: Validate itemlist creation
        if (releaseItemlistId.isEmpty) {
          throw Exception(ReleaseTranslationConstants.catalogCreationFailed.tr);
        }

        releaseItemlist.id = releaseItemlistId;

        // Save progress to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.itemlistCreated,
          itemlist: releaseItemlist,
        );
      }

      // STEP 3: Upload each release item
      // If resuming, skip items that were already uploaded (have remote URL and Firestore ID)
      final resumeItemIndex = (resumeStep == ReleaseUploadStep.itemsUploading)
          ? (draft?.currentItemIndex ?? 0) : 0;

      for (AppReleaseItem releaseItem in appReleaseItems) {
        // Skip items already fully uploaded (have ID and remote preview URL)
        if (releaseItemIndex.value < resumeItemIndex && releaseItem.id.isNotEmpty
            && releaseItem.previewUrl.startsWith('http')) {
          AppConfig.logger.i('Resuming: Skipping already uploaded item ${releaseItemIndex.value}: ${releaseItem.name}');
          releaseItemIndex.value++;
          update([AppPageIdConstants.releaseUpload]);
          continue;
        }

        uploadStatusMessage.value = '${ReleaseTranslationConstants.uploadingFile.tr} ${releaseItemIndex.value + 1}/${appReleaseItems.length}';
        update([AppPageIdConstants.releaseUpload]);

        // Save current item index to cache
        await cacheController.updateDraft(
          step: ReleaseUploadStep.itemsUploading,
          currentItemIndex: releaseItemIndex.value,
        );

        // Set metadata from itemlist - preserve categories from selection
        releaseItem.imgUrl = releaseItemlist.imgUrl;
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlist.id;
        releaseItem.metaName = releaseItemlist.name;
        releaseItem.state = 5;

        // Log categories and instruments for debugging
        AppConfig.logger.d("ReleaseItem categories: ${releaseItem.categories}");
        AppConfig.logger.d("ReleaseItem instruments: ${releaseItem.instruments}");

        releaseItem.status = AppConfig.instance.appInfo.releaseRevisionEnabled
            ? ReleaseStatus.pending : ReleaseStatus.publish;

        // Step 3a: Upload release file to WordPress/Firebase
        String fileExtension = '';
        bool isPdf = false;
        if(releaseItem.previewUrl.isNotEmpty) {
          AppConfig.logger.i("Uploading file: ${releaseItem.previewUrl}");
          fileExtension = releaseItem.previewUrl.split('.').last.toLowerCase();
          isPdf = fileExtension == "pdf";

          AppMediaType mediaType = AppMediaType.audio;
          if(fileExtension == "mp3") {
            mediaType = AppMediaType.audio;
          } else if (isPdf) {
            mediaType = AppMediaType.text;
          }

          String filePath = releaseFilePaths.elementAt(releaseItemIndex.value);

          File fileToUpload = await FileSystemUtilities.getFileFromPath(filePath);
          String uploadedFileUrl = '';

          if(AppProperties.mediaToWordpressFlag()) {
            uploadedFileUrl = await wooMediaServiceImpl.uploadMediaToWordPress(fileToUpload, fileName: releaseItem.name);
          } else {
            uploadedFileUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);
          }

          // CRITICAL: Validate file upload was successful
          if (uploadedFileUrl.isEmpty) {
            throw Exception('${ReleaseTranslationConstants.fileUploadFailed.tr}: ${releaseItem.name}');
          }

          releaseItem.previewUrl = uploadedFileUrl;
          AppConfig.logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        // Step 3b: Create WooCommerce product ONLY for PDFs (to sell physical books)
        // MP3s only need file hosting, no WooCommerce product
        String wooProductId = '';
        if (isPdf && AppProperties.createWooProductFlag()) {
          AppConfig.logger.d('Creating WooCommerce product for PDF: ${releaseItem.name}');
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
        } else if (!isPdf) {
          AppConfig.logger.d('Skipping WooCommerce product for MP3 - only file hosting needed');
        }

        // Step 3c: Insert to Firestore
        // For PDFs: use WordPress product ID to maintain consistency
        // For MP3s: use auto-generated Firestore ID
        if (isPdf && wooProductId.isNotEmpty) {
          // Use WordPress ID for PDFs - set it before insert
          releaseItem.id = wooProductId;
          AppConfig.logger.d("Using WordPress ID for PDF: $wooProductId");
        }

        // Insert method will use existing ID if set, otherwise auto-generate
        String releaseItemId = await AppReleaseItemFirestore().insert(releaseItem);

        // CRITICAL: Validate item creation in Firestore
        if (releaseItemId.isEmpty) {
          throw Exception('${ReleaseTranslationConstants.itemCreationFailed.tr}: ${releaseItem.name}');
        }

        releaseItem.id = releaseItemId;
        AppConfig.logger.d("ReleaseItem Created with Id $releaseItemId");

        if(await ItemlistFirestore().addReleaseItem(releaseItemlist.id, releaseItem)) {
          AppConfig.logger.i("ReleaseItem ${releaseItem.name} successfully added to itemlist ${releaseItemlist.id}");
          releaseItemlist.appReleaseItems!.add(releaseItem);
        } else {
          AppConfig.logger.e("Something occurred when adding ReleaseItem ${releaseItem.name} adding to itemlist ${releaseItemlist.id}");
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      // Save progress - all items uploaded
      await cacheController.updateDraft(
        step: ReleaseUploadStep.itemsUploaded,
        releaseItems: appReleaseItems.toList(),
      );

      // STEP 4: Create post (only if user chose to share publicly)
      if (sharePublicly) {
        uploadStatusMessage.value = ReleaseTranslationConstants.creatingPost.tr;
        update([AppPageIdConstants.releaseUpload]);

        await createReleasePost();
        // Save progress - post created
        await cacheController.updateDraft(step: ReleaseUploadStep.postCreated);
      } else {
        AppConfig.logger.i("Skipping post creation - user chose not to share publicly");
      }

      // STEP 5: Create release approval request for admin review
      uploadStatusMessage.value = ReleaseTranslationConstants.finalizingUpload.tr;
      update([AppPageIdConstants.releaseUpload]);

      await _createReleaseApprovalRequest(releaseCoverImgURL);

      if (Sint.isRegistered<TimelineService>()) {
        // Force reload of shelf data so the new release appears on Home
        await Sint.find<TimelineService>().getReleaseItemsFromWoo();
      }

      // Mark as completed and clear cache
      await cacheController.markAsCompleted();
      _uploadRetryCount = 0;

      AppUtilities.showSnackBar(
          title: ReleaseTranslationConstants.digitalPositioning,
          message: ReleaseTranslationConstants.digitalPositioningSuccess.tr
      );

      isButtonDisabled.value = false;
      isLoading.value = false;
      uploadStatusMessage.value = '';
      Sint.offAllNamed(AppRouteConstants.home);

    } catch (e) {
      AppConfig.logger.e('Upload failed (attempt ${_uploadRetryCount + 1}/$_maxRetries): ${e.toString()}');
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
        && mediaUploadServiceImpl!.mediaFileExists());
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
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addReleaseItemToList() async {
    AppConfig.logger.d("Adding ${appReleaseItem.value.name} to itemList ${releaseItemlist.name}.");

    try {
      appReleaseItems.value.removeWhere((element) => element.name == appReleaseItem.value.name);

      if(appReleaseItems.length < releaseItemsQty.value) {
        appReleaseItems.add(AppReleaseItem.fromJSON(appReleaseItem.value.toJSON()));
        releaseFilePaths.add(releaseFilePath);
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
    } catch(e) {
      AppConfig.logger.e(e.toString());
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
    AppConfig.logger.t("Adding final info to release");

    try {

      for (AppReleaseItem releaseItem in appReleaseItems) {

        if(releaseItem.imgUrl.isEmpty) {
          releaseItem.imgUrl = releaseCoverImgPath.isNotEmpty ? releaseCoverImgPath.value : AppProperties.getAppLogoUrl();
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

    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    AppConfig.logger.d("clearReleaseCoverImg");
    try {
      mediaUploadServiceImpl!.clearMedia();
      releaseCoverImgPath.value = '';
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
          backgroundColor: AppColor.main50,
          avatar: CircleAvatar(
            backgroundColor: Colors.cyan,
            child: Text(genre.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          label: Text(genre.name.capitalize, style: const TextStyle(fontSize: 15),),
          selected: selectedGenres.contains(genre.name),
          selectedColor: AppColor.main50,
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
    bool containsCroppedImgFile = mediaUploadServiceImpl!.mediaFileExists();
    String itemImgUrl = appReleaseItem.value.imgUrl.isNotEmpty
        ? appReleaseItem.value.imgUrl
        : releaseItemlist.imgUrl.isNotEmpty
            ? releaseItemlist.imgUrl
            : AppProperties.getAppLogoUrl();

    try {
      if(containsCroppedImgFile) {
        String croppedImgFilePath = mediaUploadServiceImpl!.getMediaFile().path;
        cachedNetworkImage = Image.file(
            File(croppedImgFilePath),
            width: AppTheme.fullWidth(context)*0.45
        );
      } else if(releaseCoverImgPath.value.isNotEmpty && File(releaseCoverImgPath.value).existsSync()) {
        cachedNetworkImage = Image.file(
            File(releaseCoverImgPath.value),
            width: AppTheme.fullWidth(context)*0.45
        );
      } else {
        cachedNetworkImage = CachedNetworkImage(
            imageUrl: itemImgUrl,
            width: AppTheme.fullWidth(context)*0.45);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      cachedNetworkImage = CachedNetworkImage(imageUrl: itemImgUrl,
          width: AppTheme.fullWidth(context)*0.45);
    }

    return cachedNetworkImage;
  }

  @override
  Future<void> addReleaseFile() async {
    AppConfig.logger.d("Handling Release File From Gallery");

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

        if(AppConfig.instance.appInUse == AppInUse.g) {
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    ///DEPRECATED update([AppPageIdConstants.releaseUpload]);
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
    } catch (e) {
      AppConfig.logger.e("Error extracting PDF page count: $e");
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
    Sint.toNamed(AppRouteConstants.pdfViewer,
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
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

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }

  void gotoNameDesc() {
    if(AppConfig.instance.appInUse != AppInUse.g || appReleaseItem.value.type == ReleaseType.single) {
      Sint.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } else {
      Sint.toNamed(AppRouteConstants.releaseUploadItemlistNameDesc);
    }
  }

  Future<void> submitRelease(BuildContext context) async {
   if(AppConfig.instance.appInfo.demoReleaseEnabled || userServiceImpl.userSubscription?.status == SubscriptionStatus.active) {
     // Validate required fields before proceeding
     final missingFields = <String>[];
     if (appReleaseItem.value.name.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseTitle.tr);
     if (appReleaseItem.value.description.isEmpty && releaseItemlist.description.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseDesc.tr);
     if (appReleaseItem.value.previewUrl.isEmpty && releaseFilePaths.isEmpty) missingFields.add(ReleaseTranslationConstants.addReleaseFile.tr);
     if (!mediaUploadServiceImpl!.mediaFileExists() && releaseCoverImgPath.value.isEmpty
         && appReleaseItem.value.imgUrl.isEmpty && releaseItemlist.imgUrl.isEmpty) {
       missingFields.add(ReleaseTranslationConstants.addReleaseCoverImg.tr);
     }
     if (appReleaseItem.value.categories.isEmpty) missingFields.add(ReleaseTranslationConstants.releaseUploadGenres.tr);

     if (missingFields.isNotEmpty) {
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
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(title: ReleaseTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

    isLoading.value = false;
    update();
  }

  Future<void> playPreview(AppReleaseItem item) async {
    AppConfig.logger.d("Playing preview for item: ${item.name} - ${item.previewUrl}");

    if(isPlaying && previewPath.contains(item.previewUrl)) {
      await audioLitePlayerServiceImpl!.stop();
      isPlaying = false;
    } else {
      await audioLitePlayerServiceImpl!.stop();
      previewPath = releaseFilePaths.firstWhere((path) => path.contains(item.previewUrl));
      await audioLitePlayerServiceImpl!.setFilePath(previewPath);
      await audioLitePlayerServiceImpl!.play();
      isPlaying = true;
    }

  }

}
