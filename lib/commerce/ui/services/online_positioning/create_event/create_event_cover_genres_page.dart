import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import '../event_controller.dart';
import 'widgets/create_event_widgets.dart';

class CreateEventCoverGenresPage extends StatelessWidget {
  const CreateEventCoverGenresPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(color: Colors.transparent),
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppTheme.heightSpace50,
                    HeaderIntro(subtitle: (_.event.imgUrl.isEmpty && _.requiredItems.isEmpty && _.bandImgUrls.isEmpty) ?
                    AppTranslationConstants.createEventGenres.tr : AppTranslationConstants.createEventCoverGenres.tr),
                    AppTheme.heightSpace20,
                    (_.event.imgUrl.isEmpty && _.requiredItems.isEmpty && _.bandImgUrls.isEmpty) ? Container() :
                    ((_.event.imgUrl.isNotEmpty && _.requiredItems.isEmpty && _.bandImgUrls.isEmpty)
                     ? CachedNetworkImage(
                        imageUrl: _.event.imgUrl,
                        height: AppTheme.fullHeight(context) * 0.35,
                    ) : Container(
                      decoration: BoxDecoration(
                          color: AppColor.main50,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(50.0),
                          bottomLeft: Radius.circular(50.0),
                          )
                      ),
                      child: _.event.type == EventType.festival ? festivalImageCarouselSlider(context, _)
                          : eventImageCarouselSlider(context, _),
                     )),
                     AppTheme.heightSpace10,
                     SizedBox(
                       height: (_.event.imgUrl.isEmpty && _.requiredItems.isEmpty && _.bandImgUrls.isEmpty)
                           ? AppTheme.fullHeight(context) /2 : 170,
                       child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: _.genreChips.toList()
                        ),
                       ),
                     ),
                     AppTheme.heightSpace10,
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding20 * 1.5),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           Container(
                             height: AppTheme.fullHeight(context) * 0.08,
                             width: AppTheme.fullWidth(context) * 0.58,
                             decoration: BoxDecoration(
                               color: AppColor.main50,
                               borderRadius: BorderRadius.circular(20.0),
                                 boxShadow: const [
                                   BoxShadow(
                                     color: Colors.black26,
                                     offset: Offset(0, 2),
                                     blurRadius: 20.0,
                                   )
                                 ]
                             ),
                             child: TextButton(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding20),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                                   children: [
                                     Text(
                                      AppTranslationConstants.checkSummary.tr,
                                       style: const TextStyle(
                                        fontSize: 20,
                                        color: AppColor.white
                                       ),
                                     ),
                                     const Icon(Icons.arrow_forward, color: Colors.white)
                                   ],
                                 ),
                               ),
                               onPressed: () => _.gotoEventSummary()
                             ),
                           ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
           ),
         );
      }
    );
  }

}
