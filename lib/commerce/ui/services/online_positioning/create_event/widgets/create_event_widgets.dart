import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_bands/bands/ui/details/band_details_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/band_fulfillment.dart';
import 'package:neom_commons/core/domain/model/instrument_fulfillment.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/vocal_type.dart';
import 'package:neom_instruments/instruments/data/firestore/profile_instruments_firestore.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../event_controller.dart';

Widget buildFulfillmentInstrument(BuildContext context, EventController _, InstrumentFulfillment instrumentFulfillment, {bool isNotSelf = true}) {
  return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 20.0,
            )
          ]
      ),
      child: Column(
        children: [
          GestureDetector(
            child: CircleAvatar(
                radius: 30,
                backgroundImage: instrumentFulfillment.profileImgUrl.isNotEmpty
                    ? Image.network(instrumentFulfillment.profileImgUrl).image
                : Image.asset(AppAssets.unknownItemmate).image),
            onTap: () => {
              if(instrumentFulfillment.profileId.isNotEmpty) {
                if(isNotSelf) {
                  Get.toNamed(AppRouteConstants.mateDetails, arguments: instrumentFulfillment.profileId)
                } else {
                  Get.toNamed(AppRouteConstants.profileDetails, arguments: instrumentFulfillment.profileId)
                }
              } else {
                Alert(
                context: context,
                style: AlertStyle(
                  backgroundColor: AppColor.main50,
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                title: AppTranslationConstants.sendInvitation.tr,
                content: SizedBox(
                  width: 300,
                  child: Column(
                    children: <Widget> [
                      TextField(
                        onChanged: (text) {
                          _.setMessage(text);
                        },
                        decoration: InputDecoration(
                            labelText: AppTranslationConstants.optionalMessage.tr
                        ),
                      ),
                      AppTheme.heightSpace10,
                      FutureBuilder<Map<String,AppProfile>>(
                        future: ProfileInstrumentsFirestore().retrieveProfilesBySpecs(
                            instrumentId: instrumentFulfillment.instrument.id,
                            selfProfileId: _.profile.id,
                            currentPosition: _.profile.position!
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return SizedBox(
                              height: 270,
                              child: snapshot.data?.isEmpty ?? true
                                  ? SizedBox(
                                  height: 250,
                                  child: Center(
                                    child:Text(AppTranslationConstants.noBandmatesWereFound.tr,
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                              ) :
                              SingleChildScrollView(
                                child: ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    shrinkWrap: true,
                                    controller: ScrollController(),
                                    itemBuilder: (context, index) {
                                      AppProfile bandmate = snapshot.data!.values.elementAt(index);
                                      return ListTile(
                                        contentPadding: const EdgeInsets.all(0),
                                        title: GestureDetector(
                                            onTap: () => Get.toNamed(AppRouteConstants.mateDetails, arguments: bandmate.id),
                                            child: Text(bandmate.name)
                                        ),
                                        subtitle: GestureDetector(
                                          onTap: () => Get.toNamed(AppRouteConstants.mateDetails, arguments: bandmate.id),
                                          child: Row(
                                              children: [
                                                Text(bandmate.appItems?.length.toString() ?? ""),
                                                Icon(AppFlavour.getAppItemIcon(),
                                                    color: Colors.blueGrey, size: 20),
                                                Text(bandmate.mainFeature.tr.capitalize!),
                                              ]
                                          ),
                                        ),
                                        leading: Hero(
                                            tag: bandmate.photoUrl,
                                            child: FutureBuilder<CachedNetworkImageProvider>(
                                              future: CoreUtilities.handleCachedImageProvider(bandmate.photoUrl),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return GestureDetector(
                                                    onTap: () => Get.toNamed(AppRouteConstants.mateDetails, arguments: bandmate.id),
                                                    child: CircleAvatar(backgroundImage: snapshot.data),
                                                  );
                                                } else {
                                                  return const CircleAvatar(
                                                      backgroundColor: Colors.transparent,
                                                      child: CircularProgressIndicator()
                                                  );
                                                }
                                              },
                                            )
                                        ),
                                        trailing: Obx(()=>DialogButton(
                                            width: 80,
                                            height: 30,
                                            color: _.invitedProfiles.contains(bandmate.id)
                                                ? AppColor.bondiBlue50 : AppColor.bondiBlue75,
                                            onPressed: () async {
                                              if(!_.isButtonDisabled && !_.invitedProfiles.contains(bandmate.id)) {
                                                _.sendEventInvitation(bandmate, instrumentFulfillment.instrument);
                                              }
                                            },
                                            child: Text(_.invitedProfiles.contains(bandmate.id) ?
                                            AppTranslationConstants.invited.tr : AppTranslationConstants.invite.tr,
                                            )
                                        ),
                                        ),
                                      );
                                    }
                                ),),
                            );
                          } else {
                            return SizedBox(
                                height: 250,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Center(
                                        child: CircularProgressIndicator()
                                    ),
                                    AppTheme.heightSpace20,
                                    Text(AppTranslationConstants.loadingPossibleBandmates.tr,
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  ],
                                ));
                          }
                        },
                      ),
                    ],
                  ),),
                buttons: [
                  DialogButton(
                    color: AppColor.bondiBlue75,
                    onPressed: () => {
                      Get.back()
                    },
                    child: Text(AppTranslationConstants.goBack.tr,
                      style: const TextStyle(fontSize: 15),
                    ),
                  )
                ]
            ).show()
              }
            },
          ),

              instrumentFulfillment.instrument.name.toLowerCase() == AppTranslationConstants.none
              ? Container()
              : Text(
            instrumentFulfillment.instrument.name.toLowerCase().tr.capitalizeFirst!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
            ),
          ),
          (instrumentFulfillment.vocalType == VocalType.none)
          || (instrumentFulfillment.instrument.name.toLowerCase() == AppTranslationConstants.vocal
              && instrumentFulfillment.vocalType == VocalType.main)
          ? Container()
          : Text(instrumentFulfillment.vocalType == VocalType.main
              ? AppTranslationConstants.vocal.tr
              : instrumentFulfillment.vocalType.name.toLowerCase().tr,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0),
          ),
          Text(
            instrumentFulfillment.profileName.length >= 2 ?
              instrumentFulfillment.profileName.split(" ").first
            : instrumentFulfillment.profileName,
            style: const TextStyle(
              color: AppColor.yellow,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
  );
}


Widget eventImageCarouselSlider(BuildContext buildContext, EventController _) {
  return CarouselSlider(
    options: CarouselOptions(
        height: AppTheme.fullHeight(buildContext) * 0.35,
        aspectRatio: 16/9,
        onPageChanged: (int pageIndex, CarouselPageChangedReason carouselPageChangedReason) {
          if(carouselPageChangedReason == CarouselPageChangedReason.manual){
            _.updateEventImgUrl(_.itemImgUrls.elementAt(pageIndex));
          }
        },
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        autoPlay: _.event.imgUrl.isEmpty ? true : false,
        scrollDirection: Axis.horizontal,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn
    ),
    items: _.itemImgUrls.map((imgUrl) {
      return Builder(
        builder: (BuildContext context) {
          return GestureDetector(
              child: SizedBox(
                  width: AppTheme.fullWidth(context),
                  child: CachedNetworkImage(imageUrl: imgUrl.isNotEmpty ? imgUrl
                  : AppFlavour.getNoImageUrl(),
                      fit: BoxFit.fill)),
            onTap: () => _.updateMainEventImgUrl(imgUrl),
          );
        },
      );
    }).toList(),
  );
}


Widget festivalImageCarouselSlider(BuildContext buildContext, EventController _) {
  return CarouselSlider(
    options: CarouselOptions(
        height: AppTheme.fullHeight(buildContext) * 0.35,
        aspectRatio: 16/9,
        onPageChanged: (int pageIndex, CarouselPageChangedReason carouselPageChangedReason) {
          if(carouselPageChangedReason == CarouselPageChangedReason.manual){
            _.updateFestivalEventImgUrl(_.bandImgUrls.elementAt(pageIndex));
          }
        },
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        autoPlay: _.event.imgUrl.isEmpty ? true : false,
        scrollDirection: Axis.horizontal,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn
    ),
    items: _.bandImgUrls.map((imgUrl) {
      return Builder(
        builder: (BuildContext context) {
          return SizedBox(
              width: AppTheme.fullWidth(context),
              child: CachedNetworkImage(imageUrl: imgUrl.isNotEmpty ? imgUrl
                  : AppFlavour.getNoImageUrl(),
                  fit: BoxFit.fill)
          );
        },
      );
    }).toList(),
  );
}



Widget buildCreateEventButton(BuildContext context, EventController _) {
  return Container(
    width: AppTheme.fullWidth(context) * 0.5,
    height: AppTheme.fullHeight(context) * 0.06,
    margin: EdgeInsets.symmetric(vertical: AppTheme.fullWidth(context) * 0.05),
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColor.bondiBlue75,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      onPressed: () => {
       if(!_.isButtonDisabled) _.createEvent(),
      },
      child: Obx(()=>_.isLoading ? const Center(child: CircularProgressIndicator())
      : Text(AppTranslationConstants.createEvent.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
      ),
    ),
  );
}


Widget buildEventItems(BuildContext context, EventController _) {
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
    itemCount: _.requiredItems.length,
    itemBuilder: (context, index) {
      AppItem appItem = _.requiredItems.values.elementAt(index);
      return GestureDetector(
        child: ListTile(
          //contentPadding: const EdgeInsets.all(8.0),
          title: Text(appItem.name.isEmpty ? ""
              : appItem.name.length > AppConstants.maxAppItemNameLength ? "${appItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": appItem.name),
          subtitle: Row(children: [Text(appItem.artist.isEmpty ? ""
              : appItem.artist.length > AppConstants.maxArtistNameLength ? "${appItem.artist.substring(0,AppConstants.maxArtistNameLength)}...": appItem.artist), const SizedBox(width:5,),RatingBar(
            initialRating: appItem.state.toDouble(),
            minRating: 1,
            ignoreGestures: true,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            ratingWidget: RatingWidget(
              full: CoreUtilities.ratingImage(AppAssets.heart),
              half: CoreUtilities.ratingImage(AppAssets.heartHalf),
              empty: CoreUtilities.ratingImage(AppAssets.heartBorder),
            ),
            itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
            itemSize: 12,
            onRatingUpdate: (rating) {
              _.logger.d("New Rating set to $rating");
            },
          ),]),
          onTap: () => Get.toNamed(AppRouteConstants.itemDetails, arguments: [appItem]),
          leading: Hero(
            tag: CoreUtilities.getAppItemHeroTag(index),
            child: FadeInImage.memoryNetwork(
                width: 40.0,
                placeholder: kTransparentImage,
                image: appItem.albumImgUrl.isNotEmpty ? appItem.albumImgUrl
                    : AppFlavour.getNoImageUrl(),
                fadeInDuration: const Duration(milliseconds: 300)
            ),
          ),
        ),
      );
    },
  );
}


Widget buildFestivalBand(BuildContext context, BandFulfillment bandFulfillment) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding10),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 20.0,
          )
        ]
    ),
    child: Column(
      children: [
        GestureDetector(
          child: CircleAvatar(
              radius: 40,
              backgroundImage: bandFulfillment.bandImgUrl.isNotEmpty
                  ? Image.network(bandFulfillment.bandImgUrl).image
                  : Image.asset(AppAssets.unknownItemmate).image),
          onTap: () {
            if(bandFulfillment.bandId.isNotEmpty) {
              Get.delete<BandDetailsController>();
              Get.toNamed(AppRouteConstants.bandDetails, arguments: [bandFulfillment.bandId]);
            }
          }
        ),
        Text(
          bandFulfillment.bandName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
          ),
          textAlign: TextAlign.center,
        ),
        bandFulfillment.hasAccepted ? Container()
        : Text(AppTranslationConstants.tbc.tr,
          style: const TextStyle(
            color: AppColor.yellow,
            fontSize: 12.0,
          ),
        ),
      ],
    ),
  );
}


Widget buildPlayingBand(BuildContext context, Band band) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding10),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 20.0,
          )
        ]
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          child: CircleAvatar(
              radius: 40,
              backgroundImage: band.photoUrl.isNotEmpty
                  ? Image.network(band.photoUrl).image
                  : Image.asset(AppAssets.unknownItemmate).image),
          onTap: () => {
            if(band.id.isNotEmpty) {
              Get.toNamed(AppRouteConstants.bandDetails, arguments: [band])
            }
          },
        ),
        AppTheme.heightSpace10,
        Text(
          band.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
          ),
        ),
      ],
    ),
  );
}
