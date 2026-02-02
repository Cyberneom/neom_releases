import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
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
    return SintBuilder<ReleaseUploadController>(
        id: AppPageIdConstants.releaseUpload,
        init: ReleaseUploadController(),
        builder: (controller) => Obx(()=> Scaffold(
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
                        controllerFunction: controller.setReleaseType,
                          isSelected: controller.appReleaseItem.value.type == ReleaseType.single && controller.releaseItemsQty.value == 1
                      ),
                      AppTheme.heightSpace10,
                       buildActionChip(
                         appEnum: ReleaseType.album,
                         controllerFunction: controller.setReleaseType,
                         isSelected: controller.appReleaseItem.value.type == ReleaseType.album
                       ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.ep,
                        controllerFunction: controller.setReleaseType,
                        isSelected: controller.appReleaseItem.value.type == ReleaseType.ep
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.demo,
                        controllerFunction: controller.setReleaseType,
                        isSelected: controller.appReleaseItem.value.type == ReleaseType.demo
                      ),
                    ]
                  ),
                  AppTheme.heightSpace20,
                  controller.showItemsQtyDropDown.value ? SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${ReleaseTranslationConstants.appReleaseItemsQty.tr}:", style: const TextStyle(fontSize: 15),),
                        AppTheme.widthSpace10,
                        DropdownButton<int>(
                          borderRadius: BorderRadius.circular(10.0),
                          items: ReleasesConstants.appReleaseItemsQty
                            .where((itemsQty) => itemsQty >= (controller.appReleaseItem.value.type == ReleaseType.demo ? 1
                              : controller.appReleaseItem.value.type == ReleaseType.ep ? 2 : 4)
                              && itemsQty <= (controller.appReleaseItem.value.type == ReleaseType.demo ? 4 :
                              controller.appReleaseItem.value.type == ReleaseType.ep ? 6 : 15)
                          ).map((int itemsQty) {
                            return DropdownMenuItem<int>(
                              value: itemsQty,
                              child: Text(itemsQty.toString()),
                            );
                          }).toList(),
                          onChanged: (int? itemsQty) {
                            controller.setAppReleaseItemsQty(itemsQty ?? 1);
                          },
                          value: controller.releaseItemsQty.value,
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
        floatingActionButton: controller.releaseItemsQty.value > 0 ? FloatingActionButton(
            tooltip: AppTranslationConstants.next.tr,
            elevation: AppTheme.elevationFAB,
            child: const Icon(Icons.navigate_next),
            onPressed: () {
              if(AppConfig.instance.appInUse == AppInUse.g) {
                if(controller.bandServiceImpl.bands.isNotEmpty) {
                  Sint.toNamed(AppRouteConstants.releaseUploadBandOrSolo);
                } else {
                  controller.setAsSolo();
                }
              } else {
                controller.setAsSolo();
              }
            },
          ) : const SizedBox.shrink(),
      ),),
    );
  }
}
