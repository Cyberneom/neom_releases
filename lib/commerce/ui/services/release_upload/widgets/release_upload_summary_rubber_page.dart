import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/core/ui/widgets/submit_button.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:rubber/rubber.dart';
import 'package:readmore/readmore.dart';
import '../release_upload_controller.dart';


class ReleaseUploadSummaryRubberPage extends StatelessWidget {
  const ReleaseUploadSummaryRubberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
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
            scrollController: _.scrollController,
            animationController: _.releaseUploadDetailsAnimationController,
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
                      controller: _.scrollController,
                      children: [
                        Text(_.appReleaseItem.name.capitalize!,
                          style: TextStyle(
                            fontSize: _.appReleaseItem.bandsFulfillment.length == 1 ? 20 : 25.0,
                            fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,
                        ),
                        GenresGridView(_.appReleaseItem.genres, AppColor.yellow),
                        AppTheme.heightSpace10,
                        _.appReleaseItem.description.isNotEmpty ?
                        Container(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Align(alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                child: ReadMoreText(_.appReleaseItem.description,
                                  trimLines: 6,
                                  colorClickableText: Colors.grey.shade500,
                                  trimMode: TrimMode.Line,
                                  trimCollapsedText: '... ${AppTranslationConstants.readMore.tr}',
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                  trimExpandedText: ' ${AppTranslationConstants.less.tr.capitalize!}',
                                ),
                                // HashTagText(
                                //   text: _.appReleaseItem.description,
                                //   softWrap: true,
                                //   maxLines: 10,
                                //   overflow: TextOverflow.ellipsis,
                                //   textAlign: TextAlign.justify,
                                //   basicStyle: const TextStyle(fontSize: 16),
                                //   decoratedStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
                                //   onTap: (text) {
                                //     AppUtilities.logger.i(text);
                                //   },
                                // ),
                              )
                          ),
                        ) : Container(),
                        AppTheme.heightSpace10,
                        CircleAvatar(
                          radius: 80.0,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _.profile.photoUrl.isNotEmpty
                                  ? _.profile.photoUrl
                                  : AppFlavour.getNoImageUrl(),
                              width: 160.0, // Set the width to twice the radius
                              height: 160.0, // Set the height to twice the radius
                              fit: BoxFit.cover, // You can adjust the fit mode as needed
                            ),
                          ),
                        ),
                        AppTheme.heightSpace5,
                        Text(
                          "${AppTranslationConstants.by.tr.capitalizeFirst}: ${_.profile.name}",
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 15),
                        ),
                        AppTheme.heightSpace10,
                        Text(!_.isAutoPublished || (_.appReleaseItem.place?.name.isNotEmpty ?? false)
                            ? (_.appReleaseItem.place?.name ?? "")
                            : AppTranslationConstants.autoPublishing.tr,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        AppTheme.heightSpace10,
                        Column(
                            children: [
                              (_.isPhysical && _.appReleaseItem.physicalPrice!.amount != 0) ?
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${AppTranslationConstants.physicalReleasePrice.tr}: \$${_.appReleaseItem.physicalPrice!.amount.truncate().toString()} MXN ",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ) : Container(),
                              (_.appReleaseItem.digitalPrice!.amount != 0) ?
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("${AppTranslationConstants.digitalReleasePrice.tr}: \$${_.appReleaseItem.digitalPrice!.amount.truncate().toString()} MXN ",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ) : Container(),
                              (_.appReleaseItem.digitalPrice!.amount != 0 &&
                                  _.appReleaseItem.digitalPrice!.amount != double.parse(AppFlavour.getInitialPrice())
                              ) ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("(${AppTranslationConstants.initialPrice.tr}: \$${AppFlavour.getInitialPrice()} MXN)",
                                    style: const TextStyle(fontSize: 15, decoration: TextDecoration.underline),
                                  ),
                                ],
                              ) : Container()
                            ]
                        ),
                        AppTheme.heightSpace10,
                        SubmitButton(context, text: AppTranslationConstants.submitRelease.tr,
                          isLoading: _.isLoading, isEnabled: !_.isButtonDisabled,
                          onPressed: _.uploadReleaseItem,
                        ),
                        TitleSubtitleRow("", showDivider: false, subtitle: AppTranslationConstants.submitReleaseMsg.tr),
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
