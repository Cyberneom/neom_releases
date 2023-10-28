import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:just_audio/just_audio.dart';
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

  var logger = AppUtilities.logger;

  final userController = Get.find<UserController>();
  final instrumentController = Get.put(InstrumentController());
  final genresController = Get.put(GenresController());
  final mapsController = Get.put(MapsController());
  final postUploadController = Get.put(PostUploadController());

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

  final RxBool _showSongsDropDown = false.obs;
  bool get showSongsDropDown => _showSongsDropDown.value;
  set showSongsDropDown(bool showSongsDropDown) => _showSongsDropDown.value = showSongsDropDown;

  final RxList<String> _requiredInstruments = <String>[].obs;
  List<String> get requiredInstruments =>  _requiredInstruments;
  set requiredInstruments(List<String> requiredInstruments) => _requiredInstruments.value = requiredInstruments;

  RxList<Genre> genres = <Genre>[].obs;
  RxList<String> selectedGenres = <String>[].obs;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isPhysical = false.obs;
  bool get isPhysical => _isPhysical.value;
  set isPhysical(bool isPhysical) => _isPhysical.value = isPhysical;

  final RxBool _isAutoPublished = false.obs;
  bool get isAutoPublished => _isAutoPublished.value;
  set isAutoPublished(bool isAutoPublished) => _isAutoPublished.value = isAutoPublished;

  AppProfile profile = AppProfile();

  final Rx<int> _publishedYear = 0.obs;
  int get publishedYear => _publishedYear.value;
  set publishedYear(int publishedYear) => _publishedYear.value = publishedYear;

  final Rx<AppReleaseItem> _appReleaseItem = AppReleaseItem().obs;
  AppReleaseItem get appReleaseItem => _appReleaseItem.value;
  set appReleaseItem(AppReleaseItem appReleaseItem) => _appReleaseItem.value = appReleaseItem;

  final RxList<AppReleaseItem> _appReleaseItems = <AppReleaseItem>[].obs;
  List<AppReleaseItem> get appReleaseItems => _appReleaseItems;
  set appReleaseItems(List<AppReleaseItem> appReleaseItems) => _appReleaseItems.value = appReleaseItems;

  final Rx<Place> _publisherPlace = Place().obs;
  Place get publisherPlace => _publisherPlace.value;
  set publisherPlace(Place publisherPlace) => _publisherPlace.value = publisherPlace;

  final Rx<FilePickerResult?> _releaseFile = const FilePickerResult([]).obs;
  FilePickerResult? get releaseFile => _releaseFile.value;
  set releaseFile(FilePickerResult? releaseFile) => _releaseFile.value = releaseFile;

  final Rx<File?> _iOSFile = File("").obs;
  File? get iOSFile => _iOSFile.value;
  set iOSFile(File? iOSFile) => _iOSFile.value = iOSFile;

  final RxString _releaseFilePreviewURL = "".obs;
  String get releaseFilePreviewURL => _releaseFilePreviewURL.value;
  set releaseFilePreviewURL(String releaseFilePreviewURL) => _releaseFilePreviewURL.value = releaseFilePreviewURL;

  final RxString _releaseCoverImgPath = "".obs;
  String get releaseCoverImgPath => _releaseCoverImgPath.value;
  set releaseCoverImgPath(String releaseCoverImgPath) => _releaseCoverImgPath.value = releaseCoverImgPath;

  String releaseFilePath = "";
  List<String> releaseFilePaths = [];

  final Rx<int> _releaseItemIndex = 0.obs;
  int get releaseItemIndex => _releaseItemIndex.value;
  set releaseItemIndex(int releaseItemIndex) => _releaseItemIndex.value = releaseItemIndex;
  int releaseItemsQty = 0;
  Itemlist releaseItemList = Itemlist();

  bool durationIsSelected = true;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void onInit() async {

    super.onInit();
    logger.d("Release Upload Controller Init");

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
      logger.e(e.toString());
    }
  }


  @override
  void onReady() async {

    try {
      genres.value = await CoreUtilities.loadGenres();
      isLoading = false;
    } catch (e) {
      logger.e(e.toString());
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
    logger.d("Release Type as ${releaseType.name}");
    appReleaseItem.type = releaseType;
    appReleaseItem.imgUrl == "";
    // itemsToRelease.clear();///TODO VERIFY IF NEEDED

    if(AppFlavour.appInUse != AppInUse.gigmeout || releaseType == ReleaseType.single) {
      showSongsDropDown = false;
      releaseItemsQty = 1;
      appReleaseItems.clear();
      Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
    } else {
      releaseItemsQty = 2;
      showSongsDropDown = true;
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> setAppReleaseItemsQty(int itemsQty) async {
    logger.v("Settings $itemsQty Items for ${appReleaseItem.type} Release");
    releaseItemsQty = itemsQty;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void addInstrument(int index) {
    logger.v("Adding instrument to required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.add(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeInstrument(int index) {
    logger.v("Removing instrument from required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.remove(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> addInstrumentsToReleaseItem() async {
    logger.v("Adding ${requiredInstruments.length} instruments used in release");
    try {
      appReleaseItem.instruments = requiredInstruments;
      Get.toNamed(AppRouteConstants.releaseUploadGenres);
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> uploadReleaseItem() async {

    releaseItemIndex = 0;
    isButtonDisabled = true;
    isLoading = true;
    String releaseCoverImgURL = '';
    update([AppPageIdConstants.releaseUpload]);

    try {
      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        logger.d("Uploading releaseCoverImg from: ${postUploadController.croppedImageFile.value.path}");
        releaseCoverImgURL = await AppUploadFirestore().uploadImage(releaseItemList.name,
            postUploadController.croppedImageFile.value, UploadImageType.releaseItem);
      }

      String releaseItemlistId = "";
      releaseItemList.ownerId = profile.id;
      releaseItemList.ownerName = profile.name;
      releaseItemList.imgUrl = releaseCoverImgURL;
      if (profile.position?.latitude != 0.0) {
        releaseItemList.position = profile.position!;
      }

      switch(appReleaseItems.first.type) {
        case ReleaseType.single:
          releaseItemList.type = ItemlistType.single;
          break;
        case ReleaseType.ep:
          releaseItemList.type = ItemlistType.ep;
          break;
        case ReleaseType.album:
          releaseItemList.type = ItemlistType.album;
          break;
        case ReleaseType.demo:
          releaseItemList.type = ItemlistType.demo;
          break;
        case ReleaseType.episode:
          releaseItemList.type = ItemlistType.podcast;
          break;
        case ReleaseType.chapter:
          releaseItemList.type = ItemlistType.audiobook;
          break;
      }

      releaseItemlistId = await ItemlistFirestore().insert(releaseItemList);
      releaseItemList.id = releaseItemlistId;
      releaseItemList.appReleaseItems = [];

      for (AppReleaseItem releaseItem in appReleaseItems) {
        releaseItem.imgUrl = releaseCoverImgURL;
        releaseItem.watchingProfiles = [];
        releaseItem.boughtUsers = [];
        releaseItem.createdTime = DateTime.now().millisecondsSinceEpoch;
        releaseItem.metaId = releaseItemlistId;

        if(releaseItem.previewUrl.isNotEmpty) {
          logger.i("Uploading file from: ${releaseItem.previewUrl}");
          String fileExtension = releaseItem.previewUrl.split('.').last.toLowerCase();

          AppMediaType mediaType = AppMediaType.audio;
          if(fileExtension == "mp3"
              //|| fileExtension == "wav"
          ) {
            mediaType = AppMediaType.audio;
          } else if (fileExtension == "pdf"
              //|| fileExtension == "docx"
          ) {
            mediaType = AppMediaType.text;
          }

          String filePath = releaseFilePaths.elementAt(releaseItemIndex);
          if(Platform.isIOS) {
            iOSFile = await AppUtilities.getFileFromPath(filePath);
            releaseItem.previewUrl = await AppUploadFirestore()
                .uploadReleaseItem(releaseItem.name, iOSFile!.absolute, mediaType);
          } else {
            releaseItem.previewUrl = await AppUploadFirestore()
                .uploadReleaseItem(releaseItem.name, await AppUtilities.getFileFromPath(filePath), mediaType);
          }


          logger.d("Updating Remote Preview URL as: ${releaseItem.previewUrl}");
        }

        ///DEPRECATED AS THERE IS DEV ENV
        // releaseItem.isTest = kDebugMode;
        String releaseItemId = await AppReleaseItemFirestore().insert(releaseItem);
        if(releaseItemId.isNotEmpty) {
          releaseItem.id = releaseItemId;
          logger.d("ReleaseItem Created with Id $releaseItemId");
        }

        if(await ItemlistFirestore().addReleaseItem(releaseItemlistId, releaseItem)) {
          logger.i("ReleaseItem ${releaseItem.name} successfully added to itemlist $releaseItemlistId");
        } else {
          logger.e("Something occurred when adding ReleaseItem ${releaseItem.name} adding to itemlist $releaseItemlistId");
        }

        if(releaseItemList.appReleaseItems != null) {
          releaseItemList.appReleaseItems!.add(releaseItem);
          releaseItemIndex++;
        }

        update([AppPageIdConstants.releaseUpload]);
      }

      if(true || kDebugMode) { ///DEPRECATED AS THERE IS DEV ENV
        await createReleasePost();
      } else {
        logger.e("Not creating post to avoid posts in prod env");
      }

      await Get.find<TimelineController>().getTimeline();
      update([AppPageIdConstants.timeline]);
      Get.offAllNamed(AppRouteConstants.home);
    } catch (e) {
      logger.e(e.toString());
      AppUtilities.showSnackBar(title: AppTranslationConstants.digitalPositioning, message: e.toString());
      isButtonDisabled = false;
      isLoading = false;
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> createReleasePost() async {
    logger.d("Creating Post for ");

    try {
      Post post = Post(
        type: PostType.releaseItem,
        profileName: profile.name,
        profileImgUrl: profile.photoUrl,
        ownerId: profile.id,
        mediaUrl: appReleaseItem.imgUrl,
        referenceId: appReleaseItem.id,
        position: appReleaseItem.place?.position ?? profile.position,
        location: await GeoLocatorController().getAddressSimple(appReleaseItem.place?.position ?? profile.position!),
        isCommentEnabled: true,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        caption: '${AppTranslationConstants.releaseUploadPostCaptionMsg1.tr} "${appReleaseItem.name}" ${AppTranslationConstants.releaseUploadPostCaptionMsg2.tr}',
        isHidden: kDebugMode,
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
      logger.e(e.toString());
    }

  }


  @override
  Future<void> getPublisherPlace(context) async {
    logger.v("");

    try {
      Prediction prediction = await mapsController.placeAutoComplete(context, placeController.text);
      publisherPlace = await mapsController.predictionToGooglePlace(prediction);
      mapsController.goToPosition(publisherPlace.position!);
      placeController.text = publisherPlace.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("PublisherPlace: ${publisherPlace.name}");
    update([AppPageIdConstants.releaseUpload]);
  }


  @override
  bool validateInfo(){
    logger.d("");
    return ((isAutoPublished || placeController.text.isNotEmpty)
        && postUploadController.croppedImageFile.value.path.isNotEmpty);
  }

  @override
  void setPublishedYear(int year) {
    logger.d("");
    publishedYear = year;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsPhysical() async {
    logger.d("");
    isPhysical = !isPhysical;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setIsAutoPublished() async {
    logger.d("");
    isAutoPublished = !isAutoPublished;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistName() {
    logger.d("");
    itemlistNameController.text = itemlistNameController.text.capitalizeFirst ?? '';
    releaseItemList.name = itemlistNameController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setItemlistDesc() {
    logger.d("");
    itemlistDescController.text = itemlistDescController.text.capitalizeFirst ?? '';
    releaseItemList.description = itemlistDescController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseName() {
    logger.d("");
    appReleaseItem.name = nameController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseDesc() {
    logger.d("");
    descController.text =  descController.text.capitalizeFirst ?? '';
    appReleaseItem.description = descController.text;
    appReleaseItem.lyrics = descController.text;
    update([AppPageIdConstants.releaseUpload]);
  }

  void setReleaseDuration() {
    logger.d("");
    if(durationController.text.isNotEmpty) {
      appReleaseItem.duration = int.parse(durationController.text);
    }

    durationIsSelected = true;
    update([AppPageIdConstants.releaseUpload]);
  }

  void setDigitalReleasePrice() {
    logger.d("setDigitalReleasePrice");
    
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
    logger.d("Adding ${genres.length} to release.");

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
        logger.d("Adding ${appReleaseItem.name} to itemList ${releaseItemList.name}.");
        appReleaseItems.add(AppReleaseItem.fromJSON(appReleaseItem.toJSON()));
      }

      if(appReleaseItems.length == releaseItemsQty) {
        Get.toNamed(AppRouteConstants.releaseUploadInfo);
      } else {
        nameController.clear();
        descController.clear();
        releaseFilePreviewURL = '';
        Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addNameDescToReleaseItem() async {
    logger.v("addNameDescToReleaseItem");
    audioPlayer.stop();

    if(appReleaseItems.where((element) => element.name == nameController.text).isEmpty) {
      setReleaseName();
      setReleaseDesc();

      if(AppFlavour.appInUse == AppInUse.emxi) {
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
    logger.v("addItemlistNameDesc");
    setItemlistName();
    setItemlistDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  void setPhysicalReleasePrice() {
    logger.d("Setting physical release price to ${physicalPriceController.text}");

    if(physicalPriceController.text.isNotEmpty) {
      appReleaseItem.physicalPrice ??= Price(currency: AppCurrency.mxn);
      appReleaseItem.physicalPrice!.amount = double.parse(physicalPriceController.text);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  Future<void> addCoverToReleaseItem() async {
    logger.v("");
    setReleaseName();
    setReleaseDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  @override
  Future<void> gotoReleaseSummary() async {
    logger.v("Adding final info to release");

    try {

      for (AppReleaseItem releaseItem in appReleaseItems) {

        if(releaseItem.imgUrl.isEmpty) {
          releaseItem.imgUrl = releaseCoverImgPath.isNotEmpty ? releaseCoverImgPath : AppFlavour.getAppLogoUrl();
        }
        releaseItem.publishedYear = publishedYear;
        releaseItem.isPhysical = isPhysical;
        setPhysicalReleasePrice();
        if(isAutoPublished) {
          appReleaseItem.place = null;
        } else {
          appReleaseItem.place = publisherPlace;
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
      logger.e(e.toString());
    }

    Get.toNamed(AppRouteConstants.releaseUploadSummary);
    update([AppPageIdConstants.releaseUpload]);
  }


  @override
  Future<void> addReleaseCoverImg() async {
    logger.d("");
    try {
      await postUploadController.handleImage(uploadImageType: UploadImageType.releaseItem,
        ratioX: AppFlavour.appInUse != AppInUse.emxi ? 1 : 6,
        ratioY: AppFlavour.appInUse != AppInUse.emxi ? 1 : 9,
      );

      if(postUploadController.croppedImageFile.value.path.isNotEmpty) {
        releaseCoverImgPath = postUploadController.croppedImageFile.value.path;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    logger.d("");
    try {
      postUploadController.clearMedia();
    } catch (e) {
      logger.e(e.toString());
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
    try {

      if (appReleaseItem.imgUrl.isNotEmpty
          && postUploadController.croppedImageFile.value.path.isEmpty) {
        cachedNetworkImage = CachedNetworkImage(
            imageUrl: appReleaseItem.imgUrl.isNotEmpty
                ? appReleaseItem.imgUrl
                : AppFlavour.getAppLogoUrl(),
            width: AppTheme.fullWidth(context) / 2);
      } else {
        PostUploadController uploadController = Get.find<PostUploadController>();
        cachedNetworkImage = uploadController.croppedImageFile.value.path.isNotEmpty
            ? Image.file(File(uploadController.croppedImageFile.value.path), width: AppTheme.fullWidth(context) / 2)
            : CachedNetworkImage(imageUrl: appReleaseItem.imgUrl.isNotEmpty ? appReleaseItem.imgUrl
            : AppFlavour.getAppLogoUrl(),
            width: AppTheme.fullWidth(context) / 2);
      }
    } catch (e) {
      logger.e(e.toString());
      cachedNetworkImage = CachedNetworkImage(imageUrl: appReleaseItem.imgUrl.isNotEmpty
          ? appReleaseItem.imgUrl : AppFlavour.getAppLogoUrl(),
          width: AppTheme.fullWidth(context) / 2);
    }

    return cachedNetworkImage;
  }

  @override
  Future<void> addReleaseFile() async {
    logger.d("Handling Release File From Gallery");

    try {

      releaseFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [AppFlavour.appInUse == AppInUse.emxi ? 'pdf':'mp3'],
      );

      if (releaseFile != null && (releaseFile?.files.isNotEmpty ?? false)) {
        String releaseFileFirstName = releaseFile?.files.first.name ?? "";
        if(appReleaseItems.where((element) => element.previewUrl== releaseFileFirstName).isNotEmpty) {
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.releaseUpload,
              message: AppTranslationConstants.releaseItemFileMsg,
              duration: Duration(seconds: 5)
          );
          return;
        }

        releaseFilePath = getReleaseFilePath(releaseFile);

        appReleaseItem.previewUrl = releaseFileFirstName;
        releaseFilePreviewURL = releaseFileFirstName;
        
        if(nameController.text.isEmpty) {
          if(releaseFilePreviewURL.contains(".mp3")) {
            nameController.text = releaseFilePreviewURL.split(".mp3").first;
          } else if(releaseFilePreviewURL.contains(".pdf")) {
            nameController.text = releaseFilePreviewURL.split(".pdf").first;
          }
        }

        if(AppFlavour.appInUse == AppInUse.gigmeout) {
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
      logger.e(e.toString());
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
    releaseFilePath = getReleaseFilePath(releaseFile);
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
    releaseFilePreviewURL = appReleaseItems.last.previewUrl;
    nameController.text = appReleaseItems.last.name;
    descController.text = appReleaseItems.last.description;
    appReleaseItems.removeLast();
    update([AppPageIdConstants.releaseUpload]);
  }

}
