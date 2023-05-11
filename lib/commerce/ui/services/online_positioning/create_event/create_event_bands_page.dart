import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import '../event_controller.dart';

class CreateEventBandsPage extends StatelessWidget {
  const CreateEventBandsPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      init: EventController(),
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
        body: Container(
            decoration: AppTheme.boxDecoration,
            height: AppTheme.fullHeight(context),
            child: Column(
              children: [
              AppTheme.heightSpace50,
              HeaderIntro(subtitle: AppTranslationConstants.createEventBands.tr),
              AppTheme.heightSpace20,
              _.isLoading ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                height: AppTheme.fullHeight(context)*0.60,
                child: Obx(()=> ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  itemCount: _.allBands.length,
                  itemBuilder: (context, index) {
                    Band band = _.allBands.values.elementAt(index);
                    return GestureDetector(
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: CachedNetworkImage(imageUrl: band.photoUrl)
                        ),
                        title: Text(band.name.length > AppConstants.maxItemlistNameLength
                          ? "${band.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                          : band.name
                        ),
                        subtitle: Text(band.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            (_.profile.bands?.contains(band.id) ?? false) ? Container()
                              : ActionChip(
                                backgroundColor: AppColor.main50,
                                label: Text("${AppUtilities.distanceBetweenPositionsRounded(_.profile.position!, band.position!).toString()} KM"),
                                onPressed: () => _.gotoBandDetails(band)
                              ),
                          ]
                        ),
                        tileColor: _.festivalBands.containsKey(band.id) ? AppColor.getMain() : Colors.transparent,
                      ),
                      onTap: () => _.festivalBands.containsKey(band.id) ? _.removeBandFromFestival(band)
                          : _.addBandToFestival(band),
                      onLongPress: () => _.gotoBandDetails(band)
                    );
                  },
                ),),
              ),],
            ),
        ),
        floatingActionButton: _.festivalBands.isNotEmpty ? FloatingActionButton(
          elevation: AppTheme.elevationFAB,
          tooltip: AppTranslationConstants.next.tr,
          onPressed: ()=>{
            _.addBandsToFestival()
          },
          child: const Icon(Icons.navigate_next),
        ) : Container(),
      ),
    );
  }
}
