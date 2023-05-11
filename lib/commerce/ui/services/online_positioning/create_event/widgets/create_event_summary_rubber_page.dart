import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hashtagable/hashtagable.dart';
import 'package:intl/intl.dart';
import 'package:neom_commons/core/domain/model/band_fulfillment.dart';
import 'package:neom_commons/core/domain/model/instrument_fulfillment.dart';
import 'package:neom_commons/core/ui/static/genres_format.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import 'package:neom_commons/core/utils/enums/usage_reason.dart';
import 'package:rubber/rubber.dart';

import '../../event_controller.dart';
import 'create_event_widgets.dart';


class CreateEventSummaryRubberPage extends StatelessWidget {
  const CreateEventSummaryRubberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.events,
      builder: (_) =>
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: AppTheme.fullHeight(context) / 2, end: 0),
          builder: (_, double value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: RubberBottomSheet(
            scrollController: _.eventDetailsScrollController,
            animationController: _.eventDetailsAnimationController,
            lowerLayer: Container(
              color: Colors.transparent,
            ),
            upperLayer: Column(
              children: [
                Center(
                    child: _.getCoverImageWidget(context)
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.main50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(50.0),
                      ),
                    ),
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.padding10),
                      controller: _.eventDetailsScrollController,
                      children: [
                        _.event.bandFulfillments.length == 1 ? Text(_.selectedBand.name.capitalize!,
                          style: const TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,
                        ) : Container(),
                        Text(_.event.name.capitalize!,
                          style: TextStyle(
                            fontSize: _.event.bandFulfillments.length == 1 ? 20 : 25.0,
                            fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,
                        ),
                        GenresFormat(_.event.genres!, AppColor.yellow),
                        AppTheme.heightSpace10,
                        Center(
                          child: SizedBox(
                            height: (_.event.bandFulfillments.length > 3
                                || _.event.instrumentFulfillments.length > 4)
                                ? 240 : 130,
                            child: GridView.builder(
                                padding: const EdgeInsets.only(top:10),
                                itemCount: _.event.type == EventType.festival
                                    ? _.event.bandFulfillments.length : _.event.instrumentFulfillments.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _.event.type == EventType.festival
                                        ? (_.event.bandFulfillments.length <= 3
                                          ? _.event.bandFulfillments.length
                                          : 3)
                                        : (_.event.instrumentFulfillments.length <= 3
                                          ? _.event.instrumentFulfillments.length
                                          : _.event.instrumentFulfillments.length <= 6
                                            ? 3
                                            : 4
                                    ),
                                    mainAxisSpacing: 10,
                                    mainAxisExtent: 135
                                ),
                                itemBuilder: (context, index) {
                                  if(_.event.type == EventType.festival) {
                                    BandFulfillment festivalBand = _.event.bandFulfillments.elementAt(index);
                                    return buildFestivalBand(context, festivalBand);
                                  } else {
                                    InstrumentFulfillment instrumentFulfillment = _.event.instrumentFulfillments.elementAt(index);
                                    return buildFulfillmentInstrument(context, _, instrumentFulfillment,
                                        isNotSelf: _.profile.id != instrumentFulfillment.profileId
                                    );
                                  }
                                }
                              )
                          ),
                        ),
                        AppTheme.heightSpace10,
                        Text(_.event.place?.name.isNotEmpty ?? false
                            ? _.event.place?.name ?? ""
                            : _.isOnlineEvent ? AppTranslationConstants.onlineEvent.tr
                            : AppTranslationConstants.placeTBD.tr,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        // _.event.place!.name.isNotEmpty ? Column(
                        //   children: [
                        //     StarRating(_.event.place!.reviewStars == 0 ? 10 : _.event.place!.reviewStars), //TODO Rating to PLACES
                        //     Text('(${(_.event.place?.bookings.length.toString() ?? "0") == "0"
                        //         ? "10"
                        //         : _.event.place?.bookings.length.toString()})',
                        //       textAlign: TextAlign.center,
                        //     ),
                        //   ],) : Container(),
                        AppTheme.heightSpace5,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Text(_.event.eventDate == 0 ? AppTranslationConstants.dateTBD.tr
                                : DateFormat.yMMMd(AppTranslationConstants.esMx)
                                .format(DateTime.fromMillisecondsSinceEpoch(_.event.eventDate)),
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          const Text(" - "),
                          Text(_.event.eventDate == 0 ? AppTranslationConstants.timeTBD.tr : '${DateTime.fromMillisecondsSinceEpoch(_.event.eventDate).hour.toString()}'
                              ':${DateTime.fromMillisecondsSinceEpoch(_.event.eventDate).minute.toString().length == 1 ?
                          "0${DateTime.fromMillisecondsSinceEpoch(_.event.eventDate).minute}" : DateTime.fromMillisecondsSinceEpoch(_.event.eventDate).minute.toString()}',
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                        AppTheme.heightSpace5,
                        (_.event.reason == UsageReason.professional
                            && (_.event.type == EventType.gig || _.event.type == EventType.festival)
                        ) ?
                          Column(
                            children: [
                              (_.event.paymentPrice!.amount == 0) ? Container() :
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${AppConstants.contribution.tr}: \$${_.event.paymentPrice!.amount.truncate().toString()} ",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  _.event.paymentPrice!.currency == AppCurrency.appCoin
                                      ? Image.asset(AppAssets.appCoin, height: 17)
                                      : Text(_.event.paymentPrice!.currency.name.toUpperCase(),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                ],
                              ),
                              AppTheme.heightSpace5,
                              (_.event.coverPrice!.amount == 0) ? Container() :
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${AppConstants.cover.tr}: \$${_.event.coverPrice!.amount.truncate().toString()} ",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  _.event.coverPrice!.currency == AppCurrency.appCoin
                                      ? Image.asset(AppAssets.appCoin, height: 17)
                                      : Text(_.event.coverPrice!.currency.name.toUpperCase(),
                                          style: const TextStyle(fontSize: 15),
                                      ),
                                ],
                              )
                            ]
                          ) : Text("${_.event.type.name.toLowerCase().tr.capitalize}",
                            //" - ${_.event.reason.name.toLowerCase().tr})",
                          style: const TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        AppTheme.heightSpace5,
                        Text(
                          "${AppTranslationConstants.by.tr.capitalizeFirst}: ${_.event.owner?.name ?? ""}",
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 15),
                        ),
                        AppTheme.heightSpace10,
                        _.event.description.isNotEmpty ?
                        Container(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Align(alignment: Alignment.centerLeft,
                            child: HashTagText(
                              text: _.event.description,
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              basicStyle: const TextStyle(fontSize: 16),
                              decoratedStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                              onTap: (text) {
                                AppUtilities.logger.i(text);
                              },
                            )
                          ),
                        ) : Container(),
                        AppTheme.heightSpace10,
                        (_.event.type == EventType.jamming || _.event.appItems.isEmpty) ? Container() : Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FontAwesomeIcons.music, size: 12),
                                AppTheme.widthSpace5,
                                Text('${AppConstants.eventTabs[0].tr} (${_.event.appItems.length})')
                              ]
                            ),
                            SizedBox.fromSize(
                              size: const Size.fromHeight(200.0),
                              child: buildEventItems(context, _)
                            ),
                          ],
                        ),
                        buildCreateEventButton(context, _)
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
    );
  }
}
