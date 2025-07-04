import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_bands/bands/ui/band_controller.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/app_alerts.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/core/data/firestore/app_upload_firestore.dart';
import 'package:neom_core/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/core/data/firestore/post_firestore.dart';
import 'package:neom_core/core/data/firestore/user_firestore.dart';
import 'package:neom_core/core/data/implementations/geolocator_controller.dart';
import 'package:neom_core/core/data/implementations/maps_controller.dart';
import 'package:neom_core/core/data/implementations/subscription_controller.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/app_release_item.dart';
import 'package:neom_core/core/domain/model/app_user.dart';
import 'package:neom_core/core/domain/model/band.dart';
import 'package:neom_core/core/domain/model/genre.dart';
import 'package:neom_core/core/domain/model/instrument.dart';
import 'package:neom_core/core/domain/model/item_list.dart';
import 'package:neom_core/core/domain/model/place.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/domain/model/price.dart';
import 'package:neom_core/core/domain/use_cases/release_upload_service.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/constants/core_constants.dart';
import 'package:neom_core/core/utils/core_utilities.dart';
import 'package:neom_core/core/utils/enums/app_currency.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';
import 'package:neom_core/core/utils/enums/app_media_type.dart';
import 'package:neom_core/core/utils/enums/itemlist_type.dart';
import 'package:neom_core/core/utils/enums/owner_type.dart';
import 'package:neom_core/core/utils/enums/post_type.dart';
import 'package:neom_core/core/utils/enums/push_notification_type.dart';
import 'package:neom_core/core/utils/enums/release_status.dart';
import 'package:neom_core/core/utils/enums/release_type.dart';
import 'package:neom_core/core/utils/enums/subscription_status.dart';
import 'package:neom_core/core/utils/enums/upload_image_type.dart';
import 'package:neom_core/core/utils/enums/verification_level.dart';
import 'package:neom_instruments/instruments/ui/instrument_controller.dart';
import 'package:neom_maps_services/places.dart';
import 'package:neom_posts/posts/ui/upload/post_upload_controller.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'package:neom_woo/woo/data/api_services/woo_media_api.dart';
import 'package:rubber/rubber.dart';

class ReleaseUploadController extends GetxController with GetTickerProviderStateMixin implements ReleaseUploadService {

  final userController = Get.find<UserController>();
  final instrumentController = Get.put(InstrumentController());
  final bandController = Get.put(BandController());
  final mapsController = Get.put(MapsController());
  final postUploadController = Get.put(PostUploadController());

  AppProfile profile = AppProfile();
  AppUser user = AppUser();

  String backgroundImgUrl = "";

  late ScrollController scrollController = ScrollController();
  late RubberAnimationController rubberAnimationController;
  late RubberAnimationController releaseUploadDetailsAnimationController;

  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController itemlistNameController = TextEditingController();
  TextEditingController itemlistDescController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController maxDistanceKmController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController paymentAmountController = TextEditingController();
  // TextEditingController digitalPriceController = TextEditingController();
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
  final Rx<FilePickerResult?> releaseFile = const FilePickerResult([]).obs;

  final RxString releaseFilePreviewURL = "".obs;
  final RxString releaseCoverImgPath = "".obs;

  List<String> bandInstruments = [];

  String releaseFilePath = "";
  List<String> releaseFilePaths = [];

  Itemlist releaseItemlist = Itemlist();

  bool durationIsSelected = true;
  AudioPlayer audioPlayer = AudioPlayer();

  String previousItemName = '';
  bool isPlaying = false;
  String previewPath = '';

  late SubscriptionController subscriptionController;

  @override
  void onInit() async {

    super.onInit();
    AppConfig.logger.d("Release Upload Controller Init");

    try {
      user = userController.user;
      profile = userController.profile;

      scrollController = ScrollController();
      rubberAnimationController = RubberAnimationController(vsync: this, duration: const Duration(milliseconds: 20));
      releaseUploadDetailsAnimationController = getRubberAnimationController();

      ///DEPRECATED
      // digitalPriceController.text = AppFlavour.getInitialPrice();

      mapsController.goToPosition(profile.position!);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }
  }


  @override
  void onReady() async {

    try {
      releaseItemlist.isModifiable = false;
      releaseItemlist.appReleaseItems = [];

      appReleaseItem.value.digitalPrice = Price(currency: AppCurrency.mxn, amount: double.parse(AppProperties.getInitialPrice()));
      appReleaseItem.value.ownerEmail = user.email;
      appReleaseItem.value.ownerName =  profile.name;
      appReleaseItem.value.galleryUrls = [profile.photoUrl];
      appReleaseItem.value.categories = [];
      appReleaseItem.value.instruments = [];
      appReleaseItem.value.metaOwnerId = userController.user.email;

      genres.value = await CoreUtilities.loadGenres();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void onClose() {
    if(scrollController.hasClients) {
      scrollController.dispose();
    }

    if(rubberAnimationController.isAnimating) {
      rubberAnimationController.dispose();
    }

    if(releaseUploadDetailsAnimationController.isAnimating) {
      releaseUploadDetailsAnimationController.dispose();
    }

    audioPlayer.dispose();
  }

  @override
  Future<void> setReleaseType(ReleaseType releaseType) async {
    AppConfig.logger.d("Release Type as ${releaseType.name}");
    appReleaseItem.value.type = releaseType;
    appReleaseItem.value.imgUrl == "";

    ///DEPRECATED itemsToRelease.clear();///TODO VERIFY IF NEEDED

    if(profile.verificationLevel == VerificationLevel.none) {
      if(releaseType != ReleaseType.single) {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.digitalPositioning,
            message: AppTranslationConstants.freeSingleReleaseUploadMsg.tr
        );
        return;
      } else if(userController.user.releaseItemIds?.isNotEmpty ?? false) {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.digitalPositioning,
            message: AppTranslationConstants.freeSingleReleaseUploadMsg.tr
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
    if(AppFlavour.appInUse == AppInUse.g) {
      if(appReleaseItem.value.type == ReleaseType.single) {
        releaseItemsQty.value = 1;
        showItemsQtyDropDown.value = false;
        if(bandController.bands.isNotEmpty) {
          Get.toNamed(AppRouteConstants.releaseUploadBandOrSolo);
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
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void addInstrument(int index) {
    AppConfig.logger.t("Adding instrument to required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    instrumentsUsed.add(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeInstrument(int index) {
    AppConfig.logger.t("Removing instrument from required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    instrumentsUsed.remove(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> addInstrumentsToReleaseItem() async {
    AppConfig.logger.t("Adding ${instrumentsUsed.length} instruments used in release");
    try {
      appReleaseItem.value.instruments = instrumentsUsed;
      Get.toNamed(AppRouteConstants.releaseUploadGenres);
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

    releaseItemIndex.value = 0;
    isButtonDisabled.value = true;
    isLoading.value = true;
    update([AppPageIdConstants.releaseUpload]);

    try {

      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        AppConfig.logger.d("Uploading releaseCoverImg from: ${postUploadController.croppedImageFile.value.path}");
        releaseCoverImgURL = await WooMediaAPI.uploadMediaToWordPress(postUploadController.croppedImageFile.value, fileName: releaseItemlist.name);
        // releaseCoverImgURL = await AppUploadFirestore().uploadImage(releaseItemlist.name,
        //     postUploadController.croppedImageFile.value, UploadImageType.releaseItem);
        releaseItemlist.imgUrl = releaseCoverImgURL;
      }

      releaseItemlistId = await ItemlistFirestore().insert(releaseItemlist);
      releaseItemlist.id = releaseItemlistId;

      for (AppReleaseItem releaseItem in appReleaseItems) {
        releaseItem.imgUrl = releaseItemlist.imgUrl;
        releaseItem.categories = [];
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlist.id;
        releaseItem.state = 5;

        if(userController.user.releaseItemIds?.isEmpty ?? true) {
          releaseItem.status = ReleaseStatus.publish;
        }

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

          File fileToUpload = await AppUtilities.getFileFromPath(filePath);
          if(AppProperties.mediaToWordpressFlag()) {
            releaseItem.previewUrl = await WooMediaAPI.uploadMediaToWordPress(fileToUpload, fileName: releaseItem.name);
          } else {
            releaseItem.previewUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);
          }

          AppConfig.logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        String releaseItemId = await AppReleaseItemFirestore().insert(releaseItem);

        if(releaseItemId.isNotEmpty) {
          releaseItem.id = releaseItemId;
          AppConfig.logger.d("ReleaseItem Created with Id $releaseItemId");

          if(await ItemlistFirestore().addReleaseItem(releaseItemlist.id, releaseItem)) {
            AppConfig.logger.i("ReleaseItem ${releaseItem.name} successfully added to itemlist ${releaseItemlist.id}");
            releaseItemlist.appReleaseItems!.add(releaseItem);
          } else {
            AppConfig.logger.e("Something occurred when adding ReleaseItem ${releaseItem.name} adding to itemlist ${releaseItemlist.id}");
          }
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      await createReleasePost();

      if (Get.isRegistered<TimelineController>()) {
        await Get.find<TimelineController>().getTimeline();
      } else {
        await Get.put(TimelineController()).getTimeline();
      }

      AppUtilities.showSnackBar(
          title: AppTranslationConstants.digitalPositioning,
          message: AppTranslationConstants.digitalPositioningSuccess.tr
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(title: AppTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

    isButtonDisabled.value = false;
    isLoading.value = false;
    Get.offAllNamed(AppRouteConstants.home);
    update();
  }

  @override
  Future<void> createReleasePost() async {
    AppConfig.logger.d("Creating Post");

    String postCaption = '';

    if(releaseItemlist.ownerType == OwnerType.profile) {
      postCaption = '${AppTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${releaseItemlist.name}"'
          ' ${AppTranslationConstants.releaseUploadPostCaptionMsg2.tr}';
    } else {
      postCaption = '${AppTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${releaseItemlist.name}",'
          ' ${AppTranslationConstants.of.tr} ${AppTranslationConstants.myProject.tr} "${selectedBand.value.name}",'
          ' ${AppTranslationConstants.releaseUploadPostCaptionMsg2.tr}';
    }

    try {
      Post post = Post(
        type: PostType.releaseItem,
        profileName: profile.name,
        profileImgUrl: profile.photoUrl,
        ownerId: profile.id,
        mediaUrl: releaseItemlist.imgUrl,
        referenceId: releaseItemlist.id,
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
        if(await UserFirestore().addReleaseItem(userId: userController.user.id, releaseItemId: appReleaseItem.value.id)) {
          if(userController.user.releaseItemIds != null) {
            userController.user.releaseItemIds!.add(appReleaseItem.value.id);
          } else {
            userController.user.releaseItemIds = [appReleaseItem.value.id];
          }
        }

        FirebaseMessagingCalls.sendPublicPushNotification(
            fromProfile: profile,
            toProfileId: '',
            notificationType: PushNotificationType.releaseAppItemAdded,
            title: AppTranslationConstants.addedReleaseAppItem,
            referenceId: appReleaseItem.value.id,
            imgUrl: appReleaseItem.value.imgUrl
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> getPublisherPlace(context) async {
    AppConfig.logger.t("");

    try {
      Prediction prediction = await mapsController.placeAutoComplete(context, placeController.text);
      publisherPlace.value = await mapsController.predictionToGooglePlace(prediction);
      mapsController.goToPosition(publisherPlace.value.position!);
      placeController.text = publisherPlace.value.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }

    AppConfig.logger.d("PublisherPlace: ${publisherPlace.value.name}");
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateInfo(){
    AppConfig.logger.t("validateInfo");
    return ((isAutoPublished.value || placeController.text.isNotEmpty)
        && postUploadController.croppedImageFile.value.path.isNotEmpty);
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
  void setReleaseName() {
    AppConfig.logger.t("setReleaseName");
    appReleaseItems.value.removeWhere((element) => element.name == appReleaseItem.value.name); ///VERIFY IF OK
    appReleaseItem.value.name = nameController.text.trim().capitalizeFirst;
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
    return nameController.text.isNotEmpty && (descController.text.isNotEmpty || releaseItemsQty.value > 1)
        && appReleaseItem.value.previewUrl.isNotEmpty && durationController.text.isNotEmpty && releaseFilePreviewURL.isNotEmpty;
  }

  Future<void> addGenresToReleaseItem() async {
    AppConfig.logger.d("Adding ${genres.length} to release.");

    try {
      appReleaseItem.value.categories = selectedGenres;
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

      if(appReleaseItems.length == releaseItemsQty.value) {
        Get.toNamed(AppRouteConstants.releaseUploadInfo);
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
    audioPlayer.stop();

    if(appReleaseItems.where((element) => element.name == nameController.text.trim()).isEmpty) {
      setReleaseName();
      setReleaseDesc();

      if(AppFlavour.appInUse == AppInUse.e) {
        setReleaseDuration();
        setPhysicalReleasePrice();
        ///DEPRECATED setDigitalReleasePrice();
      }

      Get.toNamed(AppRouteConstants.releaseUploadInstr);
    } else {
      AppUtilities.showSnackBar(title: AppTranslationConstants.releaseUpload, message: AppTranslationConstants.releaseItemNameMsg);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addItemlistNameDesc() async {
    AppConfig.logger.t("addItemlistNameDesc");
    setItemlistName();
    setItemlistDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
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

  ///DEPRECATED
  // Future<void> addCoverToReleaseItem() async {
  //   AppConfig.logger.t("");
  //   setReleaseName();
  //   setReleaseDesc();
  //   Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  // }

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

        if(isAutoPublished.value) {
          appReleaseItem.value.place = null;
        } else {
          appReleaseItem.value.place = publisherPlace.value;
        }

      }

      if(appReleaseItem.value.type == ReleaseType.single) {
        releaseItemlist.name = appReleaseItem.value.name;
        releaseItemlist.description = appReleaseItem.value.description;
      }

      releaseUploadDetailsAnimationController = getRubberAnimationController();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    Get.toNamed(AppRouteConstants.releaseUploadSummary);
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
      await postUploadController.handleImage(imageType: UploadImageType.releaseItem,
        ratioX: AppFlavour.appInUse != AppInUse.e ? 1 : 6,
        ratioY: AppFlavour.appInUse != AppInUse.e ? 1 : 9,
      );

      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        releaseCoverImgPath.value = postUploadController.croppedImageFile.value.path;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    AppConfig.logger.d("");
    try {
      postUploadController.clearMedia();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
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
    bool containsCroppedImgFile = postUploadController.croppedImageFile.value.path.isNotEmpty;
    String itemImgUrl = appReleaseItem.value.imgUrl.isNotEmpty ? appReleaseItem.value.imgUrl : AppProperties.getAppLogoUrl();

    try {
      if(containsCroppedImgFile) {
        String croppedImgFilePath = postUploadController.croppedImageFile.value.path;
        cachedNetworkImage = Image.file(
            File(croppedImgFilePath),
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

      releaseFile.value = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [AppFlavour.appInUse == AppInUse.e ? 'pdf':'mp3'],
      );

      if (releaseFile.value != null && (releaseFile.value?.files.isNotEmpty ?? false)) {
        String releaseFileFirstName = releaseFile.value?.files.first.name ?? "";
        if(appReleaseItems.where((element) => element.previewUrl == releaseFileFirstName).isNotEmpty) {
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.releaseUpload,
              message: AppTranslationConstants.releaseItemFileMsg,
              duration: const Duration(seconds: 5)
          );
          return;
        }

        releaseFilePath = getReleaseFilePath(releaseFile.value);

        appReleaseItem.value.previewUrl = releaseFileFirstName;
        releaseFilePreviewURL.value = releaseFileFirstName;
        
        if(nameController.text.isEmpty) {
          if(releaseFilePreviewURL.contains(".mp3")) {
            nameController.text = releaseFilePreviewURL.split(".mp3").first;
          } else if(releaseFilePreviewURL.contains(".pdf")) {
            nameController.text = releaseFilePreviewURL.split(".pdf").first;
          }
        }

        if(AppFlavour.appInUse == AppInUse.g) {
          await audioPlayer.stop();
          audioPlayer.setFilePath(releaseFilePath);
          await audioPlayer.play();
          appReleaseItem.value.duration = audioPlayer.duration?.inSeconds ?? 0;
          durationController.text = appReleaseItem.value.duration.toString();
          if(appReleaseItem.value.duration > 0 && appReleaseItem.value.duration <= CoreConstants.maxAudioDuration) {
            AppConfig.logger.i("Audio duration of ${appReleaseItem.value.duration} seconds");
          } else {
            releaseFilePath = '';
            appReleaseItem.value.previewUrl = '';
            AppUtilities.showSnackBar(title: AppTranslationConstants.releaseUpload, message: AppTranslationConstants.releaseItemDurationMsg);
          }

        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  String getReleaseFilePath(FilePickerResult? filePickerResult) {

    String releasePath = "";

    try {
      if(Platform.isIOS) {
        PlatformFile? file = filePickerResult?.files.first;
        String uriPath = file?.path ?? "";
        final fileUri = Uri.parse(uriPath);
        releasePath = File.fromUri(fileUri).path;
      } else {
        releasePath = filePickerResult?.paths.first ?? "";
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return releasePath;
  }

  List<int> getYearsList() {
    int startYear = CoreConstants.firstReleaseYear;
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - startYear + 1, (index) => startYear + index);
  }

  void gotoPdfPreview() {
    releaseFilePath = getReleaseFilePath(releaseFile.value);

    AppReleaseItem previewItem = AppReleaseItem(
      previewUrl: releaseFilePath,
      duration: int.parse(durationController.text),
    );
    Get.toNamed(AppRouteConstants.pdfViewer,
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
    nameController.clear();
    descController.clear();
    appReleaseItem.value.name = '';
    releaseFilePreviewURL.value = '';
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  void removeLastReleaseItem() {
    AppConfig.logger.d('Removing last item from list to update it and add it again');
    releaseFilePreviewURL.value = appReleaseItems.last.previewUrl;
    appReleaseItem.value.name = appReleaseItems.last.name;
    nameController.text = appReleaseItems.last.name;
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
      appReleaseItem.value.ownerName = profile.name;
      appReleaseItem.value.galleryUrls = [profile.photoUrl];
      appReleaseItem.value.ownerType = OwnerType.profile;

      releaseItemlist.ownerId = profile.id;
      releaseItemlist.ownerName = profile.name;
      releaseItemlist.ownerType = OwnerType.profile;

      if (profile.position?.latitude != 0.0) {
        releaseItemlist.position = profile.position!;
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }

  void gotoNameDesc() {
    if(AppFlavour.appInUse != AppInUse.g || appReleaseItem.value.type == ReleaseType.single) {
      Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } else {
      Get.toNamed(AppRouteConstants.releaseUploadItemlistNameDesc);
    }
  }

  Future<void> submitRelease(BuildContext context) async {
   if(userController.userSubscription?.status == SubscriptionStatus.active) {
     // uploadMedia();
   } else {
     subscriptionController = Get.put(SubscriptionController());
     AppAlerts.getSubscriptionAlert(subscriptionController, context, AppRouteConstants.releaseUpload);
   }
  }

  Future<void> uploadMedia() async {
    AppConfig.logger.d("Initiating Upload for Media ${releaseItemlist.name} "
        "- Type: ${releaseItemlist.type} with ${appReleaseItems.length} items");

    ///DEPRECATED String releaseItemlistId = "";
    String releaseCoverImgURL = '';

    releaseItemIndex.value = 0;
    isLoading.value = true;
    update([AppPageIdConstants.releaseUpload]);

    try {

      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        AppConfig.logger.d("Uploading releaseCoverImg from: ${postUploadController.croppedImageFile.value.path}");
        releaseCoverImgURL = await WooMediaAPI.uploadMediaToWordPress(postUploadController.croppedImageFile.value, fileName: releaseItemlist.name);
        releaseItemlist.imgUrl = releaseCoverImgURL;
      }

      for (AppReleaseItem releaseItem in appReleaseItems) {
        releaseItem.imgUrl = releaseItemlist.imgUrl;
        releaseItem.categories = [];
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlist.id;
        releaseItem.state = 5;

        if(userController.user.releaseItemIds?.isEmpty ?? true) {
          releaseItem.status = ReleaseStatus.publish;
        }

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

          File fileToUpload = await AppUtilities.getFileFromPath(filePath);

          if(AppProperties.mediaToWordpressFlag()) {
            releaseItem.previewUrl = await WooMediaAPI.uploadMediaToWordPress(fileToUpload, fileName: releaseItem.name);
          } else {
            releaseItem.previewUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);
          }

          AppConfig.logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      AppUtilities.showSnackBar(
          title: AppTranslationConstants.digitalPositioning,
          message: AppTranslationConstants.digitalPositioningSuccess.tr
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(title: AppTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

    isLoading.value = false;
    update();
  }

  Future<void> playPreview(AppReleaseItem item) async {

    if(isPlaying && previewPath.contains(item.previewUrl)) {
      await audioPlayer.stop();
      isPlaying = false;
    } else {
      await audioPlayer.stop();
      previewPath = releaseFilePaths.firstWhere((path) => path.contains(item.previewUrl));
      await audioPlayer.setFilePath(previewPath);
      await audioPlayer.play();
      isPlaying = true;
    }

  }

}
