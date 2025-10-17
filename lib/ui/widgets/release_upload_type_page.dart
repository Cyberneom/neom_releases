import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/core_widgets.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/release_type.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../../utils/constants/releases_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadType extends StatelessWidget {
  const ReleaseUploadType({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
        id: AppPageIdConstants.releaseUpload,
        init: ReleaseUploadController(),
        builder: (_) => Obx(()=> Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          backgroundColor: AppColor.main50,
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: AppTheme.appBoxDecoration,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUploadType.tr, showLogo: AppConfig.instance.appInUse == AppInUse.g),
                AppTheme.heightSpace10,
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.single,
                        controllerFunction: _.setReleaseType,
                          isSelected: _.appReleaseItem.value.type == ReleaseType.single && _.releaseItemsQty.value == 1
                      ),
                      AppTheme.heightSpace10,
                       buildActionChip(
                         appEnum: ReleaseType.album,
                         controllerFunction: _.setReleaseType,
                         isSelected: _.appReleaseItem.value.type == ReleaseType.album
                       ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.ep,
                        controllerFunction: _.setReleaseType,
                        isSelected: _.appReleaseItem.value.type == ReleaseType.ep
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.demo,
                        controllerFunction: _.setReleaseType,
                        isSelected: _.appReleaseItem.value.type == ReleaseType.demo
                      ),
                    ]
                  ),
                  AppTheme.heightSpace20,
                  _.showItemsQtyDropDown.value ? SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${ReleaseTranslationConstants.appReleaseItemsQty.tr}:", style: const TextStyle(fontSize: 15),),
                        AppTheme.widthSpace10,
                        DropdownButton<int>(
                          borderRadius: BorderRadius.circular(10.0),
                          items: ReleasesConstants.appReleaseItemsQty
                            .where((itemsQty) => itemsQty >= (_.appReleaseItem.value.type == ReleaseType.demo ? 1
                              : _.appReleaseItem.value.type == ReleaseType.ep ? 2 : 4)
                              && itemsQty <= (_.appReleaseItem.value.type == ReleaseType.demo ? 4 :
                              _.appReleaseItem.value.type == ReleaseType.ep ? 6 : 15)
                          ).map((int itemsQty) {
                            return DropdownMenuItem<int>(
                              value: itemsQty,
                              child: Text(itemsQty.toString()),
                            );
                          }).toList(),
                          onChanged: (int? itemsQty) {
                            _.setAppReleaseItemsQty(itemsQty ?? 1);
                          },
                          value: _.releaseItemsQty.value,
                          elevation: 20,
                          dropdownColor: AppColor.getMain(),
                        ),
                      ],
                    ),
                  ) : const SizedBox.shrink(),
                  if(AppConfig.instance.appInUse == AppInUse.e) TitleSubtitleRow("", hPadding: 20,subtitle: ReleaseTranslationConstants.salesModelMsg.tr,showDivider: false,),
              ],
            ),
          ),
        ),
        floatingActionButton: _.releaseItemsQty.value > 0 ? FloatingActionButton(
            tooltip: AppTranslationConstants.next.tr,
            elevation: AppTheme.elevationFAB,
            child: const Icon(Icons.navigate_next),
            onPressed: () {
              if(AppConfig.instance.appInUse == AppInUse.g) {
                if(_.bandServiceImpl.bands.isNotEmpty) {
                  Get.toNamed(AppRouteConstants.releaseUploadBandOrSolo);
                } else {
                  _.setAsSolo();
                }
              } else {
                _.setAsSolo();
              }
            },
          ) : const SizedBox.shrink(),
      ),),
    );
  }
}
