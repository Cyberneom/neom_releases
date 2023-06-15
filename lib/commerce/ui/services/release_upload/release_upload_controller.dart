import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_upload_firestore.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
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
  TextEditingController placeController = TextEditingController();
  TextEditingController maxDistanceKmController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController paymentAmountController = TextEditingController();
  TextEditingController digitalPriceController = TextEditingController();
  TextEditingController physicalPriceController = TextEditingController();

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

  final Rx<Place> _publisherPlace = Place().obs;
  Place get publisherPlace => _publisherPlace.value;
  set publisherPlace(Place publisherPlace) => _publisherPlace.value = publisherPlace;

  final RxMap<String, AppItem> _itemsToRelease = <String,AppItem>{}.obs;
  Map<String,AppItem> get itemsToRelease =>  _itemsToRelease;
  set itemsToRelease(Map<String,AppItem> itemsToRelease) => _itemsToRelease.value = itemsToRelease;

  final Rx<FilePickerResult?> _releaseFile = const FilePickerResult([]).obs;
  FilePickerResult? get releaseFile => _releaseFile.value;
  set releaseFile(FilePickerResult? releaseFile) => _releaseFile.value = releaseFile;

  String releaseFilePath = "";
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
    itemsToRelease.clear();

    Get.toNamed(AppRouteConstants.releaseUploadInstr);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void addInstrument(int index) {
    logger.d("Adding instrument to required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.add(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void removeInstrument(int index) {
    logger.d("Removing instrument from required ones");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    requiredInstruments.remove(instrument.name);
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  Future<void> addInstrumentsToReleaseItem() async {
    logger.d("Adding ${requiredInstruments.length} instruments used in release");
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

    isButtonDisabled = true;
    isLoading = true;

    update([AppPageIdConstants.releaseUpload]);

    appReleaseItem.watchingProfiles = [];
    appReleaseItem.boughtUsers = [];

    try {
      if(postUploadController.croppedImageFile.path.isNotEmpty) {
        logger.d("Uploading releaseCoverImg from: ${postUploadController.croppedImageFile.path}");
        appReleaseItem.imgUrl = await AppUploadFirestore().uploadImage(appReleaseItem.name,
            postUploadController.croppedImageFile,
            UploadImageType.releaseItem
        );
      }

      if(appReleaseItem.previewUrl.isNotEmpty) {
        logger.d("Uploading file from: ${appReleaseItem.previewUrl}");
        appReleaseItem.previewUrl = await AppUploadFirestore()
            .uploadPdf(appReleaseItem.name, AppUtilities.getFileFromPath(releaseFilePath));

        logger.d("Updating Remote Preview URL as: ${appReleaseItem.previewUrl}");
      }

      appReleaseItem.isTest = kDebugMode;

      String releaseItemId = await AppReleaseItemFirestore().insert(appReleaseItem);

      if(releaseItemId.isNotEmpty) {
        appReleaseItem.id = releaseItemId;
        logger.d("ReleaseItem Created with Id $releaseItemId");
        await createReleasePost();
      }

      await Get.find<TimelineController>().getTimeline();

    } catch (e) {
      logger.e(e.toString());
      AppUtilities.showSnackBar(AppTranslationConstants.digitalPositioning, e.toString());
    }

    update([AppPageIdConstants.timeline]);
    Get.offAllNamed(AppRouteConstants.home);
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
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  Future<void> getPublisherPlace(context) async {
    logger.v("");

    try {
      Prediction prediction = await mapsController.placeAutocomplate(context, placeController.text);
      publisherPlace = await CoreUtilities.predictionToGooglePlace(prediction);
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
        && postUploadController.croppedImageFile.path.isNotEmpty);
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
  void setReleaseName() {
    logger.d("");
    appReleaseItem.name = nameController.text.trim();
    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  void setReleaseDesc() {
    logger.d("");
    appReleaseItem.description = descController.text.trim();
    update([AppPageIdConstants.releaseUpload]);
  }

  void setReleaseDuration() {
    logger.d("");
    if(durationController.text.isNotEmpty) {
      appReleaseItem.duration = int.parse(durationController.text);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  void setDigitalReleasePrice() {
    logger.d("");
    
    if(digitalPriceController.text.isNotEmpty) {
      appReleaseItem.digitalPrice!.amount = double.parse(digitalPriceController.text);
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  @override
  bool validateNameDesc() {
    //TODO Implement musician payment
    return nameController.text.isNotEmpty && descController.text.isNotEmpty
        && durationController.text.isNotEmpty && appReleaseItem.previewUrl.isNotEmpty;
  }

  Future<void> addGenresToReleaseItem() async {
    logger.d("Adding ${genres.length} to release.");
    appReleaseItem.genres = selectedGenres;
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  Future<void> addNameDescToReleaseItem() async {
    logger.d("");
    setReleaseName();
    setReleaseDesc();
    setReleaseDuration();
    setDigitalReleasePrice();
    Get.toNamed(AppRouteConstants.releaseUploadInfo);
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
    logger.d("");
    setReleaseName();
    setReleaseDesc();
    Get.toNamed(AppRouteConstants.releaseUploadNameDesc);
  }

  @override
  Future<void> gotoReleaseSummary() async {
    logger.d("Adding final info to release");

    if(appReleaseItem.imgUrl.isEmpty) {
      appReleaseItem.imgUrl = AppFlavour.getAppLogoUrl();
    }

    appReleaseItem.publishedYear = publishedYear;
    appReleaseItem.isPhysical = isPhysical;
    setPhysicalReleasePrice();

    if(isAutoPublished) {
      appReleaseItem.place = null;
    } else {
      appReleaseItem.place = publisherPlace;
    }


    try {
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
      await postUploadController.handleImage(ratioX: 6, ratioY: 9, uploadImageType: UploadImageType.releaseItem);
    } catch (e) {
      logger.e(e.toString());
    }

    validateInfo();
    update([AppPageIdConstants.releaseUpload]);
  }

  void clearReleaseCoverImg() {
    logger.d("");
    try {
      postUploadController.clearImage();
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
          label: Text(genre.name.capitalize!, style: const TextStyle(fontSize: 15),),
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
          && postUploadController.croppedImageFile.path.isEmpty) {
        cachedNetworkImage = CachedNetworkImage(
            imageUrl: appReleaseItem.imgUrl.isNotEmpty
                ? appReleaseItem.imgUrl
                : AppFlavour.getAppLogoUrl(),
            width: AppTheme.fullWidth(context) / 2);
      } else {
        PostUploadController uploadController = Get.find<PostUploadController>();
        cachedNetworkImage = uploadController.croppedImageFile.path.isNotEmpty
            ? Image.file(File(uploadController.croppedImageFile.path), width: AppTheme.fullWidth(context) / 2)
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
        allowedExtensions: ['pdf'],
      );

      if (releaseFile != null && (releaseFile?.files.isNotEmpty ?? false)) {
        appReleaseItem.previewUrl = releaseFile?.files.first.name ?? "";
        releaseFilePath = releaseFile?.paths.first ?? "";
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.releaseUpload]);
  }

  List<int> getYearsList() {
    int startYear = AppConstants.firstReleaseYear;
    int currentYear = DateTime.now().year;
    return List.generate(currentYear - startYear + 1, (index) => startYear + index);
  }

}
