import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:just_audio/just_audio.dart';
import 'package:neom_bands/bands/ui/band_controller.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_upload_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_commons/core/utils/enums/release_type.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_instruments/genres/data/implementations/genres_controller.dart';
import 'package:neom_instruments/instruments/ui/instrument_controller.dart';
import 'package:neom_posts/neom_posts.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'package:rubber/rubber.dart';

import '../../../domain/use_cases/release_upload_service.dart';


class ReleaseUploadController extends GetxController with GetTickerProviderStateMixin implements ReleaseUploadService {

  final userController = Get.find<UserController>();
  final instrumentController = Get.put(InstrumentController());
  ///DEPRECATED final genresController = Get.put(GenresController());
  final bandController = Get.put(BandController());
  final mapsController = Get.put(MapsController());
  final postUploadController = Get.put(PostUploadController());

  AppProfile profile = AppProfile();

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
  TextEditingController digitalPriceController = TextEditingController();
  TextEditingController physicalPriceController = TextEditingController();

  final Rx<Band> selectedBand = Band().obs;
  final RxBool showSongsDropDown = false.obs;
  final RxList<String> requiredInstruments = <String>[].obs;
  RxList<Genre> genres = <Genre>[].obs;
  RxList<String> selectedGenres = <String>[].obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isPhysical = false.obs;
  final RxBool isAutoPublished = false.obs;
  final Rx<int> publishedYear = 0.obs;

  final Rx<AppReleaseItem> _appReleaseItem = AppReleaseItem().obs;
  AppReleaseItem get appReleaseItem => _appReleaseItem.value;
  set appReleaseItem(AppReleaseItem appReleaseItem) => _appReleaseItem.value = appReleaseItem;

  final RxList<AppReleaseItem> _appReleaseItems = <AppReleaseItem>[].obs;
  List<AppReleaseItem> get appReleaseItems => _appReleaseItems;
  set appReleaseItems(List<AppReleaseItem> appReleaseItems) => _appReleaseItems.value = appReleaseItems;

  final Rx<int> releaseItemIndex = 0.obs;

  final Rx<Place> publisherPlace = Place().obs;
  final Rx<FilePickerResult?> releaseFile = const FilePickerResult([]).obs;

  final Rx<File> iOSFile = File("").obs;

  final RxString releaseFilePreviewURL = "".obs;
  final RxString releaseCoverImgPath = "".obs;

  List<String> bandInstruments = [];

  String releaseFilePath = "";
  List<String> releaseFilePaths = [];

  int releaseItemsQty = 0;
  Itemlist releaseItemlist = Itemlist();

  bool durationIsSelected = true;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void onInit() async {

    super.onInit();
    AppUtilities.logger.d("Release Upload Controller Init");

    try {
      profile = userController.profile;

      scrollController = ScrollController();
      rubberAnimationController = RubberAnimationController(vsync: this, duration: const Duration(milliseconds: 20));
      releaseUploadDetailsAnimationController = RubberAnimationController(
          vsync: this,
          //lowerBoundValue: AnimationControllerValue(pixel: MediaQuery.of(context).size.height * 0.75),
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

      digitalPriceController.text = AppFlavour.getInitialPrice();
      appReleaseItem.digitalPrice = Price(currency: AppCurrency.mxn, amount: double.parse(AppFlavour.getInitialPrice()));
      appReleaseItem.ownerId = profile.id;
      appReleaseItem.ownerName = profile.name;
      appReleaseItem.ownerImgUrl = profile.photoUrl;
      appReleaseItem.genres = [];

      mapsController.goToPosition(profile.position!);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  @override
  void onReady() async {

    try {
      genres.value = await CoreUtilities.loadGenres();
      isLoading.value = false;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

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
  }

  @override
  Future<void> setReleaseType(ReleaseType releaseType) async {
    AppUtilities.logger.d("Release Type as ${releaseType.name}");
    appReleaseItem.type = releaseType;
    appReleaseItem.imgUrl == "";

    ///DEPRECATED itemsToRelease.clear();///TODO VERIFY IF NEEDED

    switch(releaseType) {
      case ReleaseType.single:
        releaseItemlist.type = ItemlistType.single;
        break;
      case ReleaseType.ep:
        releaseItemlist.type = ItemlistType.ep;
        break;
      case ReleaseType.album:
        releaseItemlist.type = ItemlistType.album;
        break;
      case ReleaseType.demo:
        releaseItemlist.type = ItemlistType.demo;
        break;
      case ReleaseType.episode:
        releaseItemlist.type = ItemlistType.podcast;
        break;
      case ReleaseType.chapter:
        releaseItemlist.type = ItemlistType.audiobook;
        break;
    }

    if(AppFlavour.appInUse != AppInUse.g || appReleaseItem.type == ReleaseType.single) {
      releaseItemsQty = 1;
      showSongsDropDown.value = false;
      appReleaseItems.clear();
      Get.toNamed(AppRouteConstants.releaseUploadBandOrSolo);
    } else {
      releaseItemsQty = 2;
      showSongsDropDown.value = true;
      ///VERIFY IF appReleaseItems.clear(); is not needed here
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> setAppReleaseItemsQty(int itemsQty) async {
    AppUtilities.logger.v("Settings $itemsQty Items for ${appReleaseItem.type} Release");
    releaseItemsQty = itemsQty;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void addInstrument(int index) {
    AppUtilities.logger.v("Adding instrument to required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.add(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeInstrument(int index) {
    AppUtilities.logger.v("Removing instrument from required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.remove(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> addInstrumentsToReleaseItem() async {
    AppUtilities.logger.v("Adding ${requiredInstruments.length} instruments used in release");
    try {
      appReleaseItem.instruments = requiredInstruments;
      Get.toNamed(AppRouteConstants.releaseUploadGenres);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> uploadReleaseItem() async {

    releaseItemIndex.value = 0;
    isButtonDisabled.value = true;
    isLoading.value = true;
    String releaseCoverImgURL = '';
    update([AppPageIdConstants.releaseUpload]);

    try {
      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        AppUtilities.logger.d("Uploading releaseCoverImg from: ${postUploadController.croppedImageFile.value.path}");
        releaseCoverImgURL = await AppUploadFirestore().uploadImage(releaseItemlist.name,
            postUploadController.croppedImageFile.value, UploadImageType.releaseItem);
      }

      String releaseItemlistId = "";
      if(selectedBand.value.id.isEmpty) {
        releaseItemlist.ownerId = profile.id;
        releaseItemlist.ownerName = profile.name;
      } else {
        releaseItemlist.ownerId = selectedBand.value.id;
        releaseItemlist.ownerName = selectedBand.value.name;
        releaseItemlist.ownerType = OwnerType.band;
      }
      releaseItemlist.isModifiable = false;
      releaseItemlist.imgUrl = releaseCoverImgURL;

      if (profile.position?.latitude != 0.0) {
        releaseItemlist.position = profile.position!;
      }

      ///DEPRECATED
      // switch(appReleaseItems.first.type) {
      //   case ReleaseType.single:
      //     releaseItemList.type = ItemlistType.single;
      //     break;
      //   case ReleaseType.ep:
      //     releaseItemList.type = ItemlistType.ep;
      //     break;
      //   case ReleaseType.album:
      //     releaseItemList.type = ItemlistType.album;
      //     break;
      //   case ReleaseType.demo:
      //     releaseItemList.type = ItemlistType.demo;
      //     break;
      //   case ReleaseType.episode:
      //     releaseItemList.type = ItemlistType.podcast;
      //     break;
      //   case ReleaseType.chapter:
      //     releaseItemList.type = ItemlistType.audiobook;
      //     break;
      // }

      releaseItemlistId = await ItemlistFirestore().insert(releaseItemlist);
      releaseItemlist.id = releaseItemlistId;
      releaseItemlist.appReleaseItems = [];

      for (AppReleaseItem releaseItem in appReleaseItems) {
        releaseItem.imgUrl = releaseCoverImgURL;
        releaseItem.watchingProfiles = [];
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlistId;
        releaseItem.state = 5;

        if(releaseItem.previewUrl.isNotEmpty) {
          AppUtilities.logger.i("Uploading file: ${releaseItem.previewUrl}");
          String fileExtension = releaseItem.previewUrl.split('.').last.toLowerCase();

          AppMediaType mediaType = AppMediaType.audio;
          if(fileExtension == "mp3") {
            mediaType = AppMediaType.audio;
          } else if (fileExtension == "pdf") {
            mediaType = AppMediaType.text;
          }

          String filePath = releaseFilePaths.elementAt(releaseItemIndex.value);

          ///DEPRECATED
          // if(Platform.isIOS) {
          //   iOSFile.value = await AppUtilities.getFileFromPath(filePath);
          //   releaseItem.previewUrl = await AppUploadFirestore()
          //       .uploadReleaseItem(releaseItem.name, iOSFile.value!.absolute, mediaType);
          // } else {
          //   releaseItem.previewUrl = await AppUploadFirestore()
          //       .uploadReleaseItem(releaseItem.name, await AppUtilities.getFileFromPath(filePath), mediaType);
          // }

          File fileToUpload = await AppUtilities.getFileFromPath(filePath);
          releaseItem.previewUrl = await AppUploadFirestore().uploadReleaseItem(releaseItem.name, fileToUpload, mediaType);

          AppUtilities.logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        String releaseItemId = await AppReleaseItemFirestore().insert(releaseItem);

        if(releaseItemId.isNotEmpty) {
          releaseItem.id = releaseItemId;
          AppUtilities.logger.d("ReleaseItem Created with Id $releaseItemId");

          if(await ItemlistFirestore().addReleaseItem(releaseItemlistId, releaseItem)) {
            AppUtilities.logger.i("ReleaseItem ${releaseItem.name} successfully added to itemlist $releaseItemlistId");
            releaseItemlist.appReleaseItems!.add(releaseItem);
          } else {
            AppUtilities.logger.e("Something occurred when adding ReleaseItem ${releaseItem.name} adding to itemlist $releaseItemlistId");
          }
        }

        releaseItemIndex.value++;
        update([AppPageIdConstants.releaseUpload]);
      }

      await createReleasePost();
      await Get.find<TimelineController>().getTimeline();
      update([AppPageIdConstants.timeline]);
      Get.offAllNamed(AppRouteConstants.home);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.showSnackBar(title: AppTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled.value = false;
      isLoading.value = false;
    }

    isButtonDisabled.value = false;
    isLoading.value = false;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> createReleasePost() async {
    AppUtilities.logger.d("Creating Post");

    try {
      Post post = Post(
        type: PostType.releaseItem,
        profileName: profile.name,
        profileImgUrl: profile.photoUrl,
        ownerId: profile.id,
        mediaUrl: releaseItemlist.imgUrl,
        referenceId: releaseItemlist.id,
        position: appReleaseItem.place?.position ?? profile.position,
        location: await GeoLocatorController().getAddressSimple(appReleaseItem.place?.position ?? profile.position!),
        isCommentEnabled: true,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        caption: '${AppTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${appReleaseItem.name}" ${AppTranslationConstants.releaseUploadPostCaptionMsg2.tr}',
      );

      post.id = await PostFirestore().insert(post);

      if(post.id.isNotEmpty){
        if(await UserFirestore().addReleaseItem(userId: userController.user!.id, releaseItemId: appReleaseItem.id)) {
          if(userController.user?.releaseItemIds != null) {
            userController.user!.releaseItemIds!.add(appReleaseItem.id);
          } else {
            userController.user!.releaseItemIds = [appReleaseItem.id];
          }
        }

        FirebaseMessagingCalls.sendGlobalPushNotification(
            fromProfile: profile,
            notificationType: PushNotificationType.releaseAppItemAdded,
            referenceId: appReleaseItem.id,
            imgUrl: appReleaseItem.imgUrl
        );
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }


  @override
  Future<void> getPublisherPlace(context) async {
    AppUtilities.logger.v("");

    try {
      Prediction prediction = await mapsController.placeAutoComplete(context, placeController.text);
      publisherPlace.value = await mapsController.predictionToGooglePlace(prediction);
      mapsController.goToPosition(publisherPlace.value.position!);
      placeController.text = publisherPlace.value.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      AppUtilities.logger.d(e.toString());
    }

    AppUtilities.logger.d("PublisherPlace: ${publisherPlace.value.name}");
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateInfo(){
    AppUtilities.logger.t("validateInfo");
    return ((isAutoPublished.value || placeController.text.isNotEmpty)
        && postUploadController.croppedImageFile.value.path.isNotEmpty);
  }

  @override
  void setPublishedYear(int year) {
    AppUtilities.logger.t("setPublishedYear $year");
    publishedYear.value = year;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsPhysical() async {
    AppUtilities.logger.d("");
    isPhysical.value = !isPhysical.value;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsAutoPublished() async {
    AppUtilities.logger.t("setIsAutoPublished");
    isAutoPublished.value = !isAutoPublished.value;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistName() {
    AppUtilities.logger.t("setItemlistName");
    itemlistNameController.text = itemlistNameController.text.capitalizeFirst;
    releaseItemlist.name = itemlistNameController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistDesc() {
    AppUtilities.logger.d("setItemlistDesc");
    itemlistDescController.text = itemlistDescController.text.capitalizeFirst;
    releaseItemlist.description = itemlistDescController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseName() {
    AppUtilities.logger.t("setReleaseName");
    appReleaseItem.name = nameController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseDesc() {
    AppUtilities.logger.t("setReleaseDesc");
    descController.text =  descController.text.capitalizeFirst;
    appReleaseItem.description = descController.text;
    appReleaseItem.lyrics = descController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  void setReleaseDuration() {
    AppUtilities.logger.d("");
    if(durationController.text.isNotEmpty) {
      appReleaseItem.duration = int.parse(durationController.text);
    }

    durationIsSelected = true;
    update([AppPageIdConstants.releaseUpload]);
  }

  void setDigitalReleasePrice() {
    AppUtilities.logger.d("setDigitalReleasePrice");
    
    if(digitalPriceController.text.isNotEmpty) {
      appReleaseItem.digitalPrice!.amount = double.parse(digitalPriceController.text);
    }

    durationIsSelected = false;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateItemlistNameDesc() {
    return itemlistNameController.text.isNotEmpty
        && itemlistDescController.text.isNotEmpty;
  }

  @override
  bool validateNameDesc() {
    return nameController.text.isNotEmpty && (descController.text.isNotEmpty || releaseItemsQty > 1)
        && appReleaseItem.previewUrl.isNotEmpty && durationController.text.isNotEmpty && releaseFilePreviewURL.isNotEmpty;
  }

  Future<void> addGenresToReleaseItem() async {
    AppUtilities.logger.d("Adding ${genres.length} to release.");

    try {
      appReleaseItem.genres = selectedGenres;
      addReleaseItemToList();
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addReleaseItemToList() async {

    try {
      if(appReleaseItems.length < releaseItemsQty) {
        AppUtilities.logger.d("Adding ${appReleaseItem.name} to itemList ${releaseItemlist.name}.");
        appReleaseItems.add(AppReleaseItem.fromJSON(appReleaseItem.toJSON()));
      }

      if(appReleaseItems.length == releaseItemsQty) {
        Get.toNamed(AppRouteConstants.releaseUploadInfo);
      } else {
        nameController.clear();
        descController.clear();
        releaseFilePreviewURL.value = '';
        Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addNameDescToReleaseItem() async {
    AppUtilities.logger.v("addNameDescToReleaseItem");
    audioPlayer.stop();

    if(appReleaseItems.where((element) => element.name == nameController.text).isEmpty) {
      setReleaseName();
      setReleaseDesc();

      if(AppFlavour.appInUse == AppInUse.e) {
        setReleaseDuration();
        setDigitalReleasePrice();
      }

      if(appReleaseItem.type == ReleaseType.single) {
        setItemlistName();
        setItemlistDesc();
      }

      Get.toNamed(AppRouteConstants.releaseUploadInstr);
    } else {
      AppUtilities.showSnackBar(title: AppTranslationConstants.releaseUpload, message: AppTranslationConstants.releaseItemNameMsg);
    }

  }

  Future<void> addItemlistNameDesc() async {
    AppUtilities.logger.v("addItemlistNameDesc");
    setItemlistName();
    setItemlistDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  void setPhysicalReleasePrice() {
    AppUtilities.logger.d("Setting physical release price to ${physicalPriceController.text}");

    if(physicalPriceController.text.isNotEmpty) {
      appReleaseItem.physicalPrice ??= Price(currency: AppCurrency.mxn);
      appReleaseItem.physicalPrice!.amount = double.parse(physicalPriceController.text);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addCoverToReleaseItem() async {
    AppUtilities.logger.v("");
    setReleaseName();
    setReleaseDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  @override
  Future<void> gotoReleaseSummary() async {
    AppUtilities.logger.v("Adding final info to release");

    try {

      for (AppReleaseItem releaseItem in appReleaseItems) {

        if(releaseItem.imgUrl.isEmpty) {
          releaseItem.imgUrl = releaseCoverImgPath.isNotEmpty ? releaseCoverImgPath.value : AppFlavour.getAppLogoUrl();
        }
        releaseItem.publishedYear = publishedYear.value;
        releaseItem.isPhysical = isPhysical.value;
        setPhysicalReleasePrice();
        if(isAutoPublished.value) {
          appReleaseItem.place = null;
        } else {
          appReleaseItem.place = publisherPlace.value;
        }

      }

      releaseUploadDetailsAnimationController = RubberAnimationController(
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
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    Get.toNamed(AppRouteConstants.releaseUploadSummary);
    update([AppPageIdConstants.releaseUpload]);
  }


  @override
  Future<void> addReleaseCoverImg() async {
    AppUtilities.logger.t("addReleaseCoverImg");
    try {
      await postUploadController.handleImage(uploadImageType: UploadImageType.releaseItem,
        ratioX: AppFlavour.appInUse != AppInUse.e ? 1 : 6,
        ratioY: AppFlavour.appInUse != AppInUse.e ? 1 : 9,
      );

      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        releaseCoverImgPath.value = postUploadController.croppedImageFile.value.path;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    AppUtilities.logger.d("");
    try {
      postUploadController.clearMedia();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
    String itemImgUrl = appReleaseItem.imgUrl.isNotEmpty ? appReleaseItem.imgUrl : AppFlavour.getAppLogoUrl();

    try {
      if(containsCroppedImgFile) {
        String croppedImgFilePath = postUploadController.croppedImageFile.value.path;
        cachedNetworkImage = Image.file(
            File(croppedImgFilePath),
            width: AppTheme.fullWidth(context)/2
        );
      } else {
        cachedNetworkImage = CachedNetworkImage(
            imageUrl: itemImgUrl,
            width: AppTheme.fullWidth(context)/2);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      cachedNetworkImage = CachedNetworkImage(imageUrl: itemImgUrl,
          width: AppTheme.fullWidth(context)/2);
    }

    return cachedNetworkImage;
  }

  @override
  Future<void> addReleaseFile() async {
    AppUtilities.logger.d("Handling Release File From Gallery");

    try {

      releaseFile.value = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [AppFlavour.appInUse == AppInUse.e ? 'pdf':'mp3'],
      );

      if (releaseFile.value != null && (releaseFile.value?.files.isNotEmpty ?? false)) {
        String releaseFileFirstName = releaseFile.value?.files.first.name ?? "";
        if(appReleaseItems.where((element) => element.previewUrl== releaseFileFirstName).isNotEmpty) {
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.releaseUpload,
              message: AppTranslationConstants.releaseItemFileMsg,
              duration: Duration(seconds: 5)
          );
          return;
        }

        releaseFilePath = getReleaseFilePath(releaseFile.value);

        appReleaseItem.previewUrl = releaseFileFirstName;
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
          appReleaseItem.duration = audioPlayer.duration?.inSeconds ?? 0;
          durationController.text = appReleaseItem.duration.toString();
          if(appReleaseItem.duration > 0 && appReleaseItem.duration <= AppConstants.maxAudioDuration) {
            AppUtilities.logger.i("Audio duration of ${appReleaseItem.duration} seconds");
            releaseFilePaths.add(releaseFilePath.toString());
          } else {
            releaseFilePath = '';
            appReleaseItem.previewUrl = '';
            AppUtilities.showSnackBar(title: AppTranslationConstants.releaseUpload, message: AppTranslationConstants.releaseItemDurationMsg);
          }

        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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
      AppUtilities.logger.e(e.toString());
    }

    return releasePath;
  }

  List<int> getYearsList() {
    int startYear = AppConstants.firstReleaseYear;
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - startYear + 1, (index) => startYear + index);
  }

  void gotoPdfPreview() {
    releaseFilePath = getReleaseFilePath(releaseFile.value);
    Get.toNamed(AppRouteConstants.PDFViewer,
        arguments: [releaseFilePath, false]);
  }

  void increase() {
    if(durationIsSelected) {
      int currentValue = int.tryParse(durationController.text) ?? 0;
      durationController.text = (currentValue + 1).toString();
    } else {
      int currentValue = int.tryParse(digitalPriceController.text) ?? 0;
      digitalPriceController.text = (currentValue + 1).toString();
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
      int currentValue = int.tryParse(digitalPriceController.text) ?? 0;
      if (currentValue > 0) {
        digitalPriceController.text = (currentValue - 1).toString();
      }
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  void removeLastReleaseItem() {
    releaseFilePreviewURL.value = appReleaseItems.last.previewUrl;
    nameController.text = appReleaseItems.last.name;
    descController.text = appReleaseItems.last.description;
    appReleaseItems.removeLast();
    update([AppPageIdConstants.releaseUpload]);
  }



  @override
  void setSelectedBand(Band band) async {
    AppUtilities.logger.d("Going to Upload Release for Band: ${band.name}");
    selectedBand.value = band;

    try {
      if(selectedBand.value.members != null) {
        for (var bandMember in selectedBand.value.members!.values) {
          if (bandMember.instrument != null) {
            bandInstruments.add(bandMember.instrument!.name);
          }
        }

        appReleaseItem.instruments = bandInstruments;
      }

      appReleaseItem.bandId = selectedBand.value.id;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }


  @override
  void setAsSolo() async {
    AppUtilities.logger.d("Going to Upload Release as Solist");

    try {
      selectedBand.value = Band();
      bandInstruments = [];
      appReleaseItem.bandId = '';

      Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    gotoNameDesc();
    update([AppPageIdConstants.releaseUpload]);
  }

  void gotoNameDesc() {
    if(AppFlavour.appInUse != AppInUse.g || appReleaseItem.type == ReleaseType.single) {
      Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } else {
      Get.toNamed(AppRouteConstants.releaseUploadItemlistNameDesc);
    }
  }

}
