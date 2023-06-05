import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_bands/bands/ui/details/band_details_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
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
import 'package:transparent_image/transparent_image.dart';
import '../release_upload_controller.dart';

Widget buildFulfillmentInstrument(BuildContext context, ReleaseUploadController _, InstrumentFulfillment instrumentFulfillment, {bool isNotSelf = true}) {
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

Widget buildEventItems(BuildContext context, ReleaseUploadController _) {
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
    itemCount: _.itemsToRelease.length,
    itemBuilder: (context, index) {
      AppItem appItem = _.itemsToRelease.values.elementAt(index);
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

class NumberLimitInputFormatter extends TextInputFormatter {
  final int maxValue;

  NumberLimitInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isNotEmpty) {
      final parsedValue = int.tryParse(newValue.text);
      if (parsedValue != null && parsedValue > maxValue) {
        // Truncate the value to the maximum allowed
        final truncatedValue = TextEditingValue(
          text: maxValue.toString(),
          selection: newValue.selection,
        );
        return truncatedValue;
      }
    }
    return newValue;
  }
}
