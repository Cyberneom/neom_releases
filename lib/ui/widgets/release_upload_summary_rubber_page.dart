import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/buttons/submit_button.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:rubber/rubber.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadSummaryRubberPage extends StatelessWidget {
  const ReleaseUploadSummaryRubberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) =>
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: AppTheme.fullHeight(context)/2, end: 0),
          builder: (_, double value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: RubberBottomSheet(
            scrollController: _.scrollController,
            animationController: _.releaseUploadDetailsAnimationController,
            lowerLayer: Container(color: Colors.transparent,),
            upperLayer: Column(
              children: [
                Center(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20), /// Adjust the radius here for desired roundness
                        topRight: Radius.circular(20),
                      ),
                      child: _.getCoverImageWidget(context)
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.main95,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(50.0),
                      ),
                    ),
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.padding10),
                      controller: _.scrollController,
                      children: [
                        Text(_.releaseItemlist.name.capitalize,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,
                        ),
                        AppTheme.heightSpace10,
                        ReadMoreContainer(text: _.releaseItemlist.type != ItemlistType.single ? _.releaseItemlist.description : _.appReleaseItem.value.description),
                        AppTheme.heightSpace10,
                        CircleAvatar(
                          radius: AppTheme.fullWidth(context)/7,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _.profile.photoUrl.isNotEmpty
                                  ? _.profile.photoUrl
                                  : AppProperties.getNoImageUrl(),
                              width: (AppTheme.fullWidth(context)/7)*2, /// Set the width to twice the radius
                              height: (AppTheme.fullWidth(context)/7)*2, /// Set the height to twice the radius
                              fit: BoxFit.cover, /// You can adjust the fit mode as needed
                            ),
                          ),
                        ),
                        AppTheme.heightSpace5,
                        Text(
                          "${AppTranslationConstants.by.tr.capitalizeFirst}: ${_.profile.name}",
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 15),
                        ),
                        AppTheme.heightSpace10,
                        Text(!_.isAutoPublished.value || (_.appReleaseItem.value.place?.name.isNotEmpty ?? false)
                            ? (_.appReleaseItem.value.place?.name ?? "")
                            : ReleaseTranslationConstants.autoPublishing.tr,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        AppTheme.heightSpace10,
                        Column(
                            children: [
                              (_.isPhysical.value && _.appReleaseItem.value.physicalPrice?.amount != 0) ?
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${ReleaseTranslationConstants.physicalReleasePrice.tr}: \$${_.appReleaseItem.value.physicalPrice?.amount.truncate().toString()} MXN ",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ) : const SizedBox.shrink(),
                            ]
                        ),
                        GenresGridView(_.appReleaseItem.value.categories, AppColor.yellow),
                        AppTheme.heightSpace10,
                        if(AppConfig.instance.appInUse == AppInUse.g && _.appReleaseItems.isNotEmpty)
                          Column(
                            children: <Widget>[
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(FontAwesomeIcons.music, size: 12),
                                    AppTheme.widthSpace5,
                                    Text('${_.appReleaseItem.value.type.value.tr.toUpperCase()} (${_.appReleaseItems.length})')
                                  ]
                              ),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: _.appReleaseItems.length == 1 ? 90 : _.appReleaseItems.length == 2 ? 160 : 250,
                                ),
                                child: buildReleaseItems(context, _),
                              ),
                            ],
                          ),
                        _.releaseItemIndex > 0 ? Obx(()=> LinearPercentIndicator(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          lineHeight: AppTheme.fullHeight(context) /15,
                          percent: _.releaseItemIndex/_.releaseItemsQty.value,
                          center: Text("${AppTranslationConstants.adding.tr} "
                              "${_.releaseItemIndex} ${ReleaseTranslationConstants.outOf.tr} ${_.releaseItemsQty.value}"
                          ),
                          progressColor: AppColor.bondiBlue,
                        ),) : SubmitButton(context, text: ReleaseTranslationConstants.submitRelease.tr,
                          isLoading: _.isLoading.value, isEnabled: !_.isButtonDisabled.value,
                          onPressed: () => _.submitRelease(context),
                        ),
                        if(_.releaseItemIndex.value == 0) TitleSubtitleRow("", showDivider: false, subtitle: ReleaseTranslationConstants.submitReleaseMsg.tr, titleFontSize: 14, subTitleFontSize: 12,),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  ///ONLY OF USE FOR APPINUSE.G
  Widget buildReleaseItems(BuildContext context, ReleaseUploadController _) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _.appReleaseItems.length,
      itemBuilder: (context, index) {
        AppReleaseItem releaseItem = _.appReleaseItems.elementAt(index);
        String ownerName = releaseItem.ownerName;

        return ListTile(
          leading: Image.file(
              File(_.releaseCoverImgPath.value),
              height: 40, width: 40
          ),
          title: Text(releaseItem.name.isEmpty ? ""
              : releaseItem.name.length > AppConstants.maxAppItemNameLength ? "${releaseItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": releaseItem.name),
          subtitle: Row(children: [Text(ownerName.isEmpty ? ""
              : ownerName.length > AppConstants.maxArtistNameLength ? "${ownerName.substring(0,AppConstants.maxArtistNameLength)}...": ownerName), const SizedBox(width:5,),
              ]),
          trailing: Text(DateTimeUtilities.secondsToMinutes(releaseItem.duration,)),
          ///FEATURE
          onTap: () async {
            await _.playPreview(releaseItem);
          }

        );
      },
    );
  }

}
