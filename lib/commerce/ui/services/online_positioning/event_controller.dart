import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:neom_bands/bands/ui/band_controller.dart';
import 'package:neom_bands/bands/ui/details/band_details_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/activity_feed_firestore.dart';
import 'package:neom_commons/core/data/firestore/band_firestore.dart';
import 'package:neom_commons/core/data/firestore/event_firestore.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/request_firestore.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/maps_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/activity_feed.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_request.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/band_fulfillment.dart';
import 'package:neom_commons/core/domain/model/band_member.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/domain/model/event_offer.dart';
import 'package:neom_commons/core/domain/model/event_type_model.dart';
import 'package:neom_commons/core/domain/model/genre.dart';
import 'package:neom_commons/core/domain/model/instrument.dart';
import 'package:neom_commons/core/domain/model/instrument_fulfillment.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/model/place.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import 'package:neom_commons/core/domain/use_cases/event_service.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/activity_feed_type.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/band_member_role.dart';
import 'package:neom_commons/core/utils/enums/event_action.dart';
import 'package:neom_commons/core/utils/enums/event_status.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_commons/core/utils/enums/request_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_commons/core/utils/enums/usage_reason.dart';
import 'package:neom_commons/core/utils/enums/vocal_type.dart';
import 'package:neom_instruments/instruments/ui/instrument_controller.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_item_firestore.dart';
import 'package:neom_posts/neom_posts.dart';
import 'package:neom_timeline/neom_timeline.dart';
import 'package:rubber/rubber.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class EventController extends GetxController with GetTickerProviderStateMixin implements EventService {

  var logger = AppUtilities.logger;

  final userController = Get.find<UserController>();
  final instrumentController = Get.put(InstrumentController());
  final bandController = Get.put(BandController());
  final mapsController = Get.put(MapsController());
  final postUploadController = Get.put(PostUploadController());
  final int todayDate = DateTime.now().day;

  String backgroundImgUrl = "";

  late ScrollController eventDetailsScrollController;
  late RubberAnimationController rubberAnimationController;
  late RubberAnimationController eventDetailsAnimationController;

  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController maxDistanceKmController = TextEditingController();
  TextEditingController coverageController = TextEditingController();
  TextEditingController paymentAmountController = TextEditingController();
  TextEditingController coverAmountController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;

  final RxList<Instrument> _requiredInstruments = <Instrument>[].obs;
  List<Instrument> get requiredInstruments =>  _requiredInstruments;
  set requiredInstruments(List<Instrument> requiredInstruments) => _requiredInstruments.value = requiredInstruments;

  final RxList<String> _bandImgUrls = <String>[].obs;
  List<String> get bandImgUrls =>  _bandImgUrls;
  set bandImgUrls(List<String> bandImgUrls) => _bandImgUrls.value = bandImgUrls;

  Map<String, AppItem> _totalItems = <String,AppItem>{};
  Map<String, AppItem> get totalItems => _totalItems;

  Map<String, AppItem> _totalBandItems = <String,AppItem>{};
  Map<String, AppItem> get totalBandItems => _totalBandItems;

  final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get itemlists => _itemlists;
  set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final Rxn<Itemlist> _selectedItemlist = Rxn<Itemlist>();
  Itemlist get selectedItemlist => _selectedItemlist.value ?? Itemlist();
  set selectedItemlist(Itemlist selectedItemlist) => _selectedItemlist.value = selectedItemlist;

  final RxMap<String, AppItem> _requiredItems = <String,AppItem>{}.obs;
  Map<String,AppItem> get requiredItems =>  _requiredItems;
  set requiredItems(Map<String,AppItem> requiredItems) => _requiredItems.value = requiredItems;

  RxList<InstrumentFulfillment> instrumentFulfillment = <InstrumentFulfillment>[].obs;
  RxList<String> itemImgUrls = <String>[].obs;

  RxList<Genre> genres = <Genre>[].obs;
  RxList<String> genreNames = <String>[].obs;
  RxList<String> selectedGenres = <String>[].obs;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isChecked = false.obs;
  bool get isChecked => _isChecked.value;
  set isChecked(bool isChecked) => _isChecked.value = isChecked;

  final RxBool _isOnlineEvent = false.obs;
  bool get isOnlineEvent => _isOnlineEvent.value;
  set isOnlineEvent(bool isOnlineEvent) => _isOnlineEvent.value = isOnlineEvent;

  final Rx<Event> _event = Event().obs;
  Event get event => _event.value;
  set event(Event event) => _event.value = event;

  final RxMap<String, Event> _events = <String, Event>{}.obs;
  Map<String, Event> get events => _events;
  set events(Map<String, Event> events) => _events.value = events;

  final RxMap<String, Event> _previousEvents = <String, Event>{}.obs;
  Map<String, Event> get previousEvents => _previousEvents;
  set previousEvents(Map<String, Event> previousEvents) => _previousEvents.value = previousEvents;

  RxMap<String, Event> filteredEvents = <String, Event>{}.obs;
  RxMap<String, Event> filteredPreviousEvents = <String, Event>{}.obs;

  AppProfile profile = AppProfile();

  final Rx<DateTime> _eventDate = DateTime.now().obs;
  DateTime get eventDate => _eventDate.value;
  set eventDate(DateTime eventDate) => _eventDate.value = eventDate;

  final Rx<TimeOfDay> _eventTime = TimeOfDay.now().obs;
  TimeOfDay get eventTime => _eventTime.value;
  set eventTime(TimeOfDay eventTime) => _eventTime.value = eventTime;

  final RxInt _amount = 0.obs;
  int get amount => _amount.value;
  set amount(int amount) => _amount.value = amount;

  List<EventTypeModel> eventTypes = <EventTypeModel>[];
  List<DateTime> dates = <DateTime>[];

  final Rx<Place> _eventPlace = Place().obs;
  Place get eventPlace => _eventPlace.value;
  set eventPlace(Place eventPlace) => _eventPlace.value = eventPlace;

  final Rxn<Instrument> _selectedInstrument = Rxn<Instrument>();
  Instrument get selectedInstrument => _selectedInstrument.value ?? Instrument();
  set selectedInstrument(Instrument selectedInstrument) => _selectedInstrument.value = selectedInstrument;

  final Rxn<VocalType> _selectedVocalType = Rxn<VocalType>();
  VocalType get selectedVocalType => _selectedVocalType.value ?? VocalType.main;
  set selectedVocalType(VocalType selectedVocalType) => _selectedVocalType.value = selectedVocalType;

  final Rxn<Band> _selectedBand = Rxn<Band>();
  Band get selectedBand => _selectedBand.value ?? Band();
  set selectedBand(Band selectedBand) => _selectedBand.value = selectedBand;

  final RxMap<String, Band> _allBands = <String, Band>{}.obs;
  Map<String, Band> get allBands => _allBands;
  set allBands(Map<String, Band> allBands) => _allBands.value = allBands;

  final RxMap<String, Band> _festivalBands = <String, Band>{}.obs;
  Map<String, Band> get festivalBands => _festivalBands;
  set festivalBands(Map<String, Band> festivalBands) => _festivalBands.value = festivalBands;

  EventType eventsFilterBy = EventType.any;

  @override
  void onInit() async {

    super.onInit();
    logger.d("Event Controller Init");

    try {
      profile = userController.profile;

      itemlists = profile.itemlists ?? {};

      eventDetailsScrollController = ScrollController();
      rubberAnimationController = RubberAnimationController(vsync: this, duration: const Duration(milliseconds: 20));
      eventDetailsAnimationController = RubberAnimationController(
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


      event.paymentPrice = Price();
      event.coverPrice = Price();
      event.owner = profile;
      event.genres = [];
      _totalItems = CoreUtilities.getTotalItems(profile.itemlists ?? <String, Itemlist>{});

      mapsController.goToPosition(profile.position!);

      eventTypes = CoreUtilities.getEventTypes();
      dates = AppUtilities.getDaysFromNow();


    } catch(e) {
      logger.e(e.toString());
    }
  }


  @override
  void onReady() async {
    try {
      await retrieveEvents();
      isLoading = false;
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }

  @override
  void onClose() {
    if(eventDetailsScrollController.hasClients) {
      eventDetailsScrollController.dispose();
    }

    if(rubberAnimationController.isAnimating) {
      rubberAnimationController.dispose();
    }

    if(eventDetailsAnimationController.isAnimating) {
      eventDetailsAnimationController.dispose();
    }

  }


  @override
  Future<void> setEventType(EventType eventType) async {
    logger.d("Event as ${eventType.name}");
    event.type = eventType;

    itemImgUrls.clear();
    event.coverImgUrl = "";
    event.imgUrl == "";
    requiredItems.clear();
    bandImgUrls.clear();

    switch(eventType) {
      case(EventType.festival):
        allBands = await bandController.retrieveBands();
        instrumentFulfillment.clear();
        Get.toNamed(AppRouteConstants.createEventBands);
        break;
      case(EventType.jamming):
        Get.toNamed(AppRouteConstants.createEventInstruments);
        break;
      default:
        if (profile.bands?.isNotEmpty ?? false) {
          Get.toNamed(AppRouteConstants.createEventBandOrMusicians);
        } else {
          Get.toNamed(AppRouteConstants.createEventInstruments);
        }
        break;
    }

    update([AppPageIdConstants.event]);
  }

  @override
  void setSelectedBand(Band band) async {
    logger.d("Going to Lookup for musicians - Select instruments");
    List<InstrumentFulfillment> instrFulfillmentsTemp = [];
    selectedBand = band;

    event.isFulfilled = true;

    try {
      if(selectedBand.bandMembers != null) {
        for (var bandMember in selectedBand.bandMembers!.values) {
          instrFulfillmentsTemp.add(
              InstrumentFulfillment(
                  id: "",
                  profileName: bandMember.name,
                  profileId: bandMember.profileId,
                  profileImgUrl: bandMember.imgUrl,
                  isFulfilled: true,
                  vocalType: bandMember.vocalType,
                  instrument: bandMember.instrument ?? Instrument()
              )
          );
          if(bandMember.profileId.isEmpty) {
            event.isFulfilled = false;
          }
        }
      }

      requiredItems.clear();
      if(band.appItems?.isNotEmpty ?? false) {
        _totalBandItems = await AppItemFirestore().retrieveFromList(band.appItems ?? []);
      } else {
        _totalBandItems = {};
      }

      event.instrumentFulfillments = instrFulfillmentsTemp;

      List<BandFulfillment> tempBandFulfillments = [];

      tempBandFulfillments.add(BandFulfillment(
          bandId: selectedBand.id,
          bandImgUrl: selectedBand.photoUrl,
          bandName: selectedBand.name,
          hasAccepted: true
      ));

      event.bandFulfillments = tempBandFulfillments;
      event.imgUrl = selectedBand.photoUrl;

      if(selectedBand.appItems?.isNotEmpty ?? false) {
        Get.toNamed(AppRouteConstants.createEventItems);
      } else {
        Get.toNamed(AppRouteConstants.createEventReason);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }


  @override
  void lookupForMusicians() {
    logger.d("Going to Lookup for musicians - Select instruments");
    selectedBand = Band();
    Get.toNamed(AppRouteConstants.createEventInstruments);

    update([AppPageIdConstants.event]);
  }



  @override
  void addInstrument(int index) {
    logger.d("");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    _requiredInstruments.add(instrument);

    update([AppPageIdConstants.event]);
  }


  @override
  void removeInstrument(int index) {
    logger.d("");
    Instrument instrument = instrumentController.instruments.values.elementAt(index);
    _requiredInstruments.remove(instrument);
    update([AppPageIdConstants.event]);
  }


  @override
  void createInstrumentFulfillment() {
    logger.d("");
    List<InstrumentFulfillment> instrumentFulfillmentList = [];

    if(selectedInstrument.name.isEmpty) {
      selectedInstrument = profile.instruments?.values.first ?? Instrument();
    }

    if(selectedInstrument.name.isNotEmpty) {
      InstrumentFulfillment selfInstrumentFulfilled = InstrumentFulfillment(
          id: "",
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          profileId: profile.id,
          instrument: selectedInstrument,
          vocalType: selectedVocalType,
          isFulfilled: true
      );
      instrumentFulfillmentList.add(selfInstrumentFulfilled);
    }

    int instrumentFulfillmentId = 0;
    for (var instrument in requiredInstruments) {
      instrumentFulfillmentList.add(InstrumentFulfillment(
          id: instrumentFulfillmentId.toString(),
          instrument: instrument));
      instrumentFulfillmentId++;
    }

    event.instrumentFulfillments = instrumentFulfillmentList;

    if(event.type == EventType.jamming) {
      Get.toNamed(AppRouteConstants.createEventInfo);
    } else {
      Get.toNamed(AppRouteConstants.createEventLists);
    }

    update([AppPageIdConstants.event]);
  }


  @override
  void addAppItem(AppItem appItem) {
    logger.d("");
    requiredItems[appItem.id] = appItem;
    update([AppPageIdConstants.event]);
  }


  @override
  void removeAppItem(AppItem appItem) {
    logger.d("");
    requiredItems.remove(appItem.id);
    update([AppPageIdConstants.event]);
  }


  @override
  void addItemsToEvent() {
    logger.d("");
    event.appItems = _requiredItems.values.toList();

    if(event.imgUrl.isEmpty){
      event.imgUrl = _requiredItems.values.first.albumImgUrl;
    }

    itemImgUrls.clear();

    for (var appItem in event.appItems) {

      if(appItem.albumImgUrl.isNotEmpty) {
        itemImgUrls.add(appItem.albumImgUrl);
      }

      for (var genre in appItem.genres) {
          genreNames.add(genre.name);
      }

    }

    Get.toNamed(AppRouteConstants.createEventReason);
    update([AppPageIdConstants.event]);
  }


  void updateEventImgUrl(String imgUrl) {
    event.coverImgUrl = imgUrl;

    if(event.imgUrl.isEmpty && postUploadController.croppedImageFile.path.isEmpty) {
      event.imgUrl = imgUrl;
    }
    update([AppPageIdConstants.event]);
  }

  void updateMainEventImgUrl(String imgUrl) {
    if(imgUrl.isNotEmpty && postUploadController.croppedImageFile.path.isEmpty) {
      event.imgUrl = imgUrl;
      Get.snackbar(
          MessageTranslationConstants.mainEventImg.tr,
          MessageTranslationConstants.mainEventImgMsg.tr,
          snackPosition: SnackPosition.bottom);
    }
    update([AppPageIdConstants.event]);
  }


  void updateFestivalEventImgUrl(String imgUrl) {
    event.coverImgUrl = imgUrl;
    if(postUploadController.croppedImageFile.path.isEmpty) {
      event.imgUrl = imgUrl;
    }
    update([AppPageIdConstants.event]);
  }


  @override
  void setReason(UsageReason reason){
    logger.d("ProfileType registered Reason as ${reason.name}");
    event.reason = reason;
    Get.toNamed(AppRouteConstants.createEventInfo);
    update([AppPageIdConstants.event]);
  }


  @override
  void updateEventDate(DateTime dateTime) {
    logger.d("");
    eventDate = dateTime;
    update([AppPageIdConstants.event]);
  }


  @override
  Future<void> createEvent() async {

    isButtonDisabled = true;
    isLoading = true;
    event.owner = profile;

    update([AppPageIdConstants.event]);

    event.public = true;
    event.createdTime = DateTime.now().millisecondsSinceEpoch;
    event.itemPercentageCoverage = 1;
    event.watchingProfiles = [];
    event.goingProfiles = [];

    if(event.coverImgUrl.isEmpty) {
      event.coverImgUrl = event.imgUrl;
    }

    if(event.eventDate > 0) {
      event.status = EventStatus.scheduled;
    }

    try {
      if(postUploadController.croppedImageFile.path.isNotEmpty) {
        event.coverImgUrl = event.imgUrl;
        event.imgUrl = await postUploadController.handleUploadImage(UploadImageType.event);
      }

      event.isTest = kDebugMode;

      String eventId = await EventFirestore().insert(event);

      if(eventId.isNotEmpty) {
        event.id = eventId;
        logger.d("Event Created with Id $eventId");

        if(event.bandFulfillments.isNotEmpty) {
          for (var bandFulfillment in event.bandFulfillments) {
            if(!bandFulfillment.hasAccepted) {
              await sendEventRequest(bandFulfillment.bandId);
            }else {
              await BandFirestore().addPlayingEvent(bandFulfillment.bandId, eventId);
            }

          }
        }

        await createPostEvent();
      }

      await Get.find<TimelineController>().getTimeline();

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.timeline, AppPageIdConstants.events]);
    Get.offAllNamed(AppRouteConstants.home);
  }


  @override
  Future<void> sendEventRequest(String bandId) async {
    logger.d("Preparing Event Request for Band Founder - Band Id $bandId");
    try {

      Band invitedBand = allBands[bandId]!;
      BandMember bandFounder = BandMember();

      for (var bandMember in invitedBand.bandMembers!.values) {
        if(bandMember.role == BandMemberRole.founder) {
          bandFounder = bandMember;
        }
      }

      int distanceKm = AppUtilities.distanceBetweenPositionsRounded(profile.position!, invitedBand.position!);

      AppRequest request = AppRequest();

      if(bandFounder.id.isNotEmpty) {
        request = AppRequest(
          from: profile.id,
          to: bandFounder.profileId,
          createdTime: DateTime.now().millisecondsSinceEpoch,
          message: '${AppTranslationConstants.yourBand.tr} "${invitedBand.name}" ${AppTranslationConstants.wasInvitedTotheEvent.tr} ${event.name}',
          eventId: event.id,
          bandId: invitedBand.id,
          distanceKm: distanceKm,
        );
      }

      if(event.paymentPrice!.amount != 0) {
        request.newOffer = EventOffer(amount: event.paymentPrice!.amount);
      }

      request.id = await RequestFirestore().insert(request);

      if(request.id.isNotEmpty) {
        if(await ProfileFirestore().addRequest(profile.id, request.id, RequestType.sent)) {
          userController.profile.sentRequests!.add(request.id);

          if(await ProfileFirestore().addRequest(bandFounder.profileId,
              request.id, RequestType.invitation)) {
            ActivityFeed activityFeed = ActivityFeed();
            activityFeed.ownerId =  bandFounder.id;
            activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
            activityFeed.activityReferenceId = event.id;
            activityFeed.activityFeedType = ActivityFeedType.request;
            activityFeed.profileId = profile.id;
            activityFeed.profileName = profile.name;
            activityFeed.profileImgUrl = profile.photoUrl;
            activityFeed.mediaUrl = event.imgUrl;
            await ActivityFeedFirestore().insert(activityFeed);
            logger.d("Request was sent to Profile ${bandFounder.id}");

            FirebaseMessagingCalls.sendPrivatePushNotification(
                toProfileId: bandFounder.id,
                fromProfile: profile,
                notificationType: PushNotificationType.request,
                referenceId: event.id,
                message: request.message,
                imgUrl: event.imgUrl
            );

            FirebaseMessagingCalls.sendGlobalPushNotification(
                fromProfile: profile,
                toProfile: await ProfileFirestore().retrieve(bandFounder.id,),
                notificationType: PushNotificationType.request,
                referenceId: event.id,
                imgUrl: event.imgUrl
            );

          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  Future<void> createPostEvent() async {
    logger.d("Creating Post for Event");

    try {
      Post post = Post(
          type: PostType.event,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          ownerId: profile.id,
          mediaUrl: event.imgUrl,
          eventId: event.id,
          position: event.place!.position ?? profile.position,
          location: await GeoLocatorController().getAddressSimple(event.place!.position ?? profile.position!),
          isCommentEnabled: true,
          createdTime: DateTime.now().millisecondsSinceEpoch);

      post.id = await PostFirestore().insert(post);

      if(post.id.isNotEmpty){
        if(await ProfileFirestore().addEvent(profile.id, event.id, EventAction.organize)) {
          profile.events!.add(event.id);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  Future<void> getEventPlace(context) async {
    logger.d("");

    try {
      Prediction prediction = await mapsController.placeAutocomplate(context, placeController.text);
      eventPlace = await CoreUtilities.predictionToEventPlace(prediction);
      mapsController.goToPosition(eventPlace.position!);
      placeController.text = eventPlace.name;
      FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("");
    update([AppPageIdConstants.event]);
  }


  @override
  bool validateInfo(){
    logger.d("");
    return (placeController.text.isEmpty && !isOnlineEvent) ? false :
      eventDate.isBlank! ? false :
        eventTime.isBlank! ? false :
        true;
  }


  @override
  void addInfoToEvent() {
    logger.d("");

    if(!isChecked) {
      event.place = eventPlace;
      event.eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day, eventTime.hour, eventTime.minute).millisecondsSinceEpoch;
      event.isOnline = isOnlineEvent;
    } else {
      event.place = Place();
      event.eventDate = DateTime.now().millisecondsSinceEpoch;
    }

    Get.toNamed(AppRouteConstants.createEventNameDesc);
    update([AppPageIdConstants.event]);
  }


  @override
  void setEventDate(DateRangePickerSelectionChangedArgs args) {

    DateTime? pickedDateTime;

    logger.d("");
    if (args.value is DateTime) {
      pickedDateTime = args.value;
    }

    if (pickedDateTime != eventDate && pickedDateTime != DateTime.now()) {
      eventDate = pickedDateTime!;
    }

    update([AppPageIdConstants.event]);
  }


  @override
  void setCheckboxState() async {
    logger.d("");
    isChecked = isChecked ? false : true;
    update([AppPageIdConstants.event]);
  }

  @override
  void setIsOnlineCheckboxState() async {
    logger.d("");
    isOnlineEvent = isOnlineEvent ? false : true;
    update([AppPageIdConstants.event]);
  }


  @override
  Future<void> setEventTime(context) async {
    logger.d("");
    try {
      TimeOfDay? pickedTime = await showTimePicker(
          context: context,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColor.white,
                onPrimary: AppColor.bondiBlue75,
                surface: AppColor.getMain(),
                onSurface: AppColor.white,
              ),
              // button colors
              buttonTheme: const ButtonThemeData(
                colorScheme: ColorScheme.light(
                  primary: Colors.green,
                ),
              ),
            ),
            child: child!,
          );
        },
          cancelText: AppTranslationConstants.cancel.tr,
          helpText: AppTranslationConstants.selectTime.tr,
          initialTime: TimeOfDay.now(),

      );
      if (pickedTime != null && pickedTime != eventTime) {
        eventTime = pickedTime;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }


  @override
  void setPaymentAmount() {
    logger.d("");
    if(paymentAmountController.text.isNotEmpty) {
      event.paymentPrice!.amount = double.parse(paymentAmountController.text);
    }

    update([AppPageIdConstants.event]);
  }


  void setCoverAmount() {
    logger.d("");
    if(coverAmountController.text.isNotEmpty) {
      event.coverPrice!.amount = double.parse(coverAmountController.text);
    }

    update([AppPageIdConstants.event]);
  }


  @override
  void setEventName() {
    logger.d("");
    event.name = nameController.text.trim();
    update([AppPageIdConstants.event]);
  }


  @override
  void setEventDesc() {
    logger.d("");
    event.description = descController.text.trim();
    update([AppPageIdConstants.event]);
  }

  @override
  void setEventMaxDistance() {
    logger.d("");
    event.distanceKm = int.parse(maxDistanceKmController.text.isNotEmpty
        ? maxDistanceKmController.text : "0");
    update([AppPageIdConstants.event]);
  }


  @override
  bool validateNameDesc(){
    //TODO Implement musician payment
    return nameController.text.isEmpty ? false : true;
  }


  Future<void> addCoverGenresToEvent() async {
    logger.d("");
    setEventName();
    setEventDesc();
    setEventMaxDistance();
    setPaymentAmount();

    try {
      genres.value = await CoreUtilities.loadGenres();

      for (var genre in genres) {
        genreNames.add(genre.name);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    if(selectedBand.photoUrl.isNotEmpty && requiredItems.isEmpty) {
      event.imgUrl = selectedBand.photoUrl;
      event.coverImgUrl = selectedBand.coverImgUrl;
    } if (event.type == EventType.festival) {
      event.imgUrl = festivalBands.values.first.photoUrl;
      if(festivalBands.length > 1) {
        event.coverImgUrl = festivalBands.values.elementAt(1).photoUrl;
      }
    }

    Get.toNamed(AppRouteConstants.createEventCoverGenres);
  }


  @override
  Future<void> gotoEventSummary() async {
    logger.d("");

    if(event.imgUrl.isEmpty) {
      event.imgUrl = AppFlavour.getAppLogoUrl();
    }

    if(event.coverImgUrl.isEmpty) {
      event.imgUrl = AppFlavour.getAppLogoUrl();
    }

    try {
      eventDetailsAnimationController = RubberAnimationController(
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
    } catch (e) {
      logger.e(e.toString());
    }

    Get.toNamed(AppRouteConstants.createEventEventSummary);
  }


  @override
  Future<void> addEventImage() async {
    logger.d("");
    try {
      await postUploadController.handleEventImage();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }


  void clearEventImage() {
    logger.d("");
    try {
      itemImgUrls.remove(postUploadController.mediaUrl);
      postUploadController.clearImage();
    } catch (e) {
      logger.e(e.toString());
    }



    update([AppPageIdConstants.event]);
  }


  @override
  Future<void> retrieveEvents() async {
    logger.d("");
    try {
      events = await EventFirestore().getEvents();

      for (var event in events.values) {
        if(event.eventDate < DateTime.now().millisecondsSinceEpoch) {
          previousEvents[event.id] = event;
        }
      }

      for (var previousEventId in previousEvents.keys) {
        events.remove(previousEventId);
      }

      filteredEvents.addAll(_events);
      filteredPreviousEvents.addAll(_previousEvents);

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.events]);
  }


  @override
  void updateEventType(EventType eventType) {
    // TODO: implement updateEventType
    throw UnimplementedError();
  }

  void addGenre(Genre genre) {
    selectedGenres.add(genre.name);
    event.genres?.add(genre.name);
    update([AppPageIdConstants.event]);
  }

  void removeGenre(Genre genre){
    selectedGenres.removeWhere((String name) {
      return name == genre.name;
      }
    );

    event.genres!.removeWhere((String name) {
      return name == genre.name;
      }
    );
    update([AppPageIdConstants.event]);
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
              style: const TextStyle(color: Colors.white),
            ),
          ),
          label: Text(genre.name.capitalize!, style: const TextStyle(fontSize: 12),),
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

      if ((event.imgUrl.isNotEmpty || event.coverImgUrl.isNotEmpty)
          && postUploadController.croppedImageFile.path.isEmpty) {
        cachedNetworkImage = CachedNetworkImage(
            imageUrl: event.imgUrl.isNotEmpty
                ? event.imgUrl
                : AppFlavour.getAppLogoUrl(),
            width: AppTheme.fullWidth(context) / 2);
      } else {
        PostUploadController uploadController = Get.find<PostUploadController>();
        cachedNetworkImage = uploadController.croppedImageFile.path.isNotEmpty
            ? Image.file(File(uploadController.croppedImageFile.path), width: AppTheme.fullWidth(context) / 2)
            : CachedNetworkImage(imageUrl: event.imgUrl.isNotEmpty ? event.imgUrl
            : AppFlavour.getAppLogoUrl(),
            width: AppTheme.fullWidth(context) / 2);
      }
    } catch (e) {
      logger.e(e.toString());
      cachedNetworkImage = CachedNetworkImage(imageUrl: event.imgUrl.isNotEmpty
          ? event.imgUrl : AppFlavour.getAppLogoUrl(),
          width: AppTheme.fullWidth(context) / 2);
    }

    return cachedNetworkImage;
  }

  Future<void> deleteEvent(Event event) async {
    logger.d("Removing for $event");
    isLoading = true;
    update([AppPageIdConstants.events]);

    try {

      if(await EventFirestore().remove(event)){
        logger.d("Event ${event.id} removed");
        events.remove(event.id);
        previousEvents.remove(event.id);
        filteredEvents.remove(event.id);
        filteredPreviousEvents.remove(event.id);
      } else {
        logger.e("Something happens trying to remove itemlist");
      }

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.events]);
  }


  @override
  void setInstrumentToFulfill({String selectedInstr = ""}) {
    logger.d("");
    Instrument instrumentToFulfill = Instrument();

    if(selectedInstr.isNotEmpty && selectedInstr != AppTranslationConstants.none){
      instrumentToFulfill = profile.instruments?[selectedInstr] ??  Instrument();
    } else {
      instrumentToFulfill.name = AppTranslationConstants.none;
    }


    selectedInstrument = instrumentToFulfill;
    logger.d("Setting ${instrumentToFulfill.name} as instrument to fulfill");
    update([AppPageIdConstants.event]);

  }


  //TODO
  @override
  void setVocalTypeToFulfill(String vocalType) {
    logger.d("");
    selectedVocalType = EnumToString.fromString(VocalType.values, vocalType) ?? VocalType.none;
    logger.d("Setting ${selectedVocalType.name} as vocal type to fulfill");
    update([AppPageIdConstants.event]);

  }


  @override
  void addBandToFestival(Band band) {
    logger.d("");
    festivalBands[band.id] = band;
    update([AppPageIdConstants.event]);
  }


  @override
  void removeBandFromFestival(Band band) {
    logger.d("");
    festivalBands.remove(band.id);
    update([AppPageIdConstants.event]);
  }


  @override
  void gotoBandDetails(Band band) {
    logger.i("Going to Band Details for ${band.name}");
    try {
      Get.delete<BandDetailsController>();
    } catch (e) {
      logger.e(e.toString());
    }

    Get.toNamed(AppRouteConstants.bandDetails, arguments: [band]);
    update([AppPageIdConstants.event]);
  }

  @override
  void addBandsToFestival() {
    logger.d("");

    event.bandFulfillments = [];
    bandImgUrls.clear();

    try {
      for (var band in festivalBands.values) {

        BandMember founder = BandMember();
        for (var bandMember in band.bandMembers!.values) {
          if(bandMember.role == BandMemberRole.founder) {
            founder = bandMember;
          }
        }

        event.bandFulfillments.add(
            BandFulfillment(
                bandId: band.id,
                bandImgUrl: band.photoUrl,
                bandName: band.name,
                hasAccepted: founder.profileId == profile.id
            )
        );

        if(band.photoUrl.isNotEmpty) {
          bandImgUrls.add(band.photoUrl);
        }
      }

      if(bandImgUrls.isEmpty) {
        event.imgUrl = festivalBands.values.first.photoUrl;
        if(festivalBands.length > 1) {
          event.coverImgUrl = festivalBands.values.elementAt(1).photoUrl;
        }
      }

    } catch (e) {
      logger.e(e.toString());
    }


    Get.toNamed(AppRouteConstants.createEventReason);
    update([AppPageIdConstants.event]);
  }


  void setSelectedItemlist(Itemlist itemlist) {
    logger.d("Setting itemlist ${itemlist.name} items as the ones to play");
    selectedItemlist = itemlist;
    requiredItems.clear();
    selectedItemlist.appItems?.forEach((appItem) {
      requiredItems[appItem.id] = appItem;
    });

    addItemsToEvent();

  }

  void gotoTotalItems(){
    requiredItems.clear();
    Get.toNamed(AppRouteConstants.createEventItems);
  }


  @override
  void setCurrency(String chosenCurrency) {
    event.coverPrice!.currency = EnumToString.fromString(AppCurrency.values, chosenCurrency) ?? AppCurrency.appCoin;
    event.paymentPrice!.currency = EnumToString.fromString(AppCurrency.values, chosenCurrency) ?? AppCurrency.appCoin;
    update([AppPageIdConstants.event]);
  }

  @override
  void filterEventsBy(EventType eventType) {
    logger.d("Filtering Events By ${eventType.name}");

    eventsFilterBy = eventType;
    filteredEvents.clear();
    filteredPreviousEvents.clear();

    if(eventType == EventType.any) {
      filteredEvents.addAll(events);
      filteredPreviousEvents.addAll(previousEvents);
    } else {
      for (var event in events.values) {
        if(event.type == eventType) {
          filteredEvents[event.id] = event;
        }
      }

      for (var event in previousEvents.values) {
        if(event.type == eventType) {
          filteredPreviousEvents[event.id] = event;
        }
      }
    }

    update([AppPageIdConstants.events]);
  }


  final RxString _message = "".obs;
  String get message => _message.value;
  set message(String message) => _message.value = message;

  RxList<String> invitedProfiles = <String>[].obs;

  @override
  void setMessage(String text) {
    message = text;
    //update([GigPageIdConstants.gigBandRoom]);
  }

  @override
  Future<void> sendEventInvitation(AppProfile mate, Instrument instrument) async {

    isLoading = true;
    isButtonDisabled = true;
    update([AppPageIdConstants.bandRoom]);

    int distanceKm = AppUtilities.distanceBetweenPositionsRounded(profile.position!, mate.position!);

    AppRequest request = AppRequest(
        from: profile.id,
        to: mate.id,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        message: message,
        eventId: event.id,
        instrument: instrument,
        distanceKm: distanceKm
    );

    try {
      request.id = await RequestFirestore().insert(request);

      if(request.id.isNotEmpty) {
        await ProfileFirestore().addRequest(profile.id, request.id, RequestType.sent);
        if(await ProfileFirestore().addRequest(mate.id, request.id, RequestType.invitation)){
          ActivityFeed activityFeed = ActivityFeed();
          activityFeed.ownerId =  mate.id;
          activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
          activityFeed.activityReferenceId = event.id;
          activityFeed.activityFeedType = ActivityFeedType.eventInvitationRequest;
          activityFeed.profileName = profile.name;
          activityFeed.profileImgUrl = profile.photoUrl;
          activityFeed.profileId = profile.id;
          activityFeed.mediaUrl = event.imgUrl;
          await ActivityFeedFirestore().insert(activityFeed);

          FirebaseMessagingCalls.sendPrivatePushNotification(
              toProfileId: mate.id,
              fromProfile: profile,
              notificationType: PushNotificationType.request,
              referenceId: event.id,
              message: request.message,
              imgUrl: event.imgUrl
          );

          FirebaseMessagingCalls.sendGlobalPushNotification(
              fromProfile: profile,
              toProfile: await ProfileFirestore().retrieve(mate.id),
              notificationType: PushNotificationType.request,
              referenceId: event.id,
              imgUrl: event.imgUrl
          );

          invitedProfiles.add(mate.id);
        }

        userController.profile.sentRequests?.add(request.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    isButtonDisabled = false;
    update([AppPageIdConstants.bandRoom,
      AppPageIdConstants.requests,
      AppPageIdConstants.request]
    );

  }

}
