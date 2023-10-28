import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/core_widgets.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/release_type.dart';

import '../../../../utils/constants/app_commerce_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadType extends StatelessWidget {
  const ReleaseUploadType({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
        id: AppPageIdConstants.releaseUpload,
        init: ReleaseUploadController(),
        builder: (_) => Scaffold(
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
                HeaderIntro(subtitle: AppTranslationConstants.releaseUploadType.tr,showLogo: AppFlavour.appInUse == AppInUse.gigmeout),
                AppTheme.heightSpace10,
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.single,
                        controllerFunction: _.setReleaseType,
                          isSelected: _.releaseItemsQty == 1
                      ),
                      AppTheme.heightSpace10,
                       buildActionChip(
                         appEnum: ReleaseType.album,
                         controllerFunction: _.setReleaseType,
                         isSelected: _.appReleaseItem.type == ReleaseType.album
                       ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.ep,
                        controllerFunction: _.setReleaseType,
                        isSelected: _.appReleaseItem.type == ReleaseType.ep
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.demo,
                        controllerFunction: _.setReleaseType,
                        isSelected: _.appReleaseItem.type == ReleaseType.demo
                      ),
                    ]
                  ),
                  AppTheme.heightSpace20,
                  _.showSongsDropDown ? SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${AppTranslationConstants.appReleaseItemsQty.tr}:", style: TextStyle(fontSize: 15),),
                        AppTheme.widthSpace10,
                        DropdownButton<int>(
                          borderRadius: BorderRadius.circular(10.0),
                          items: AppCommerceConstants.appReleaseItemsQty
                            .where((itemsQty) => itemsQty >= (_.appReleaseItem.type == ReleaseType.demo ? 1 : 2)
                              && itemsQty <= (_.appReleaseItem.type == ReleaseType.album ? 15 :
                              _.appReleaseItem.type == ReleaseType.ep ? 6 : 4)
                          ).map((int itemsQty) {
                            return DropdownMenuItem<int>(
                              value: itemsQty,
                              child: Text(itemsQty.toString()),
                            );
                          }).toList(),
                          onChanged: (int? itemsQty) {
                            _.setAppReleaseItemsQty(itemsQty ?? 1);
                          },
                          value: _.releaseItemsQty,
                          elevation: 20,
                          dropdownColor: AppColor.getMain(),
                        ),
                      ],
                    ),
                  ) : Container(),
                  if(AppFlavour.appInUse == AppInUse.emxi) TitleSubtitleRow("", hPadding: 20,subtitle: AppTranslationConstants.salesModelMsg.tr,showDivider: false,),
              ],
            ),
          ),
        ),
        floatingActionButton: _.releaseItemsQty > 0 ? FloatingActionButton(
            tooltip: AppTranslationConstants.next.tr,
            elevation: AppTheme.elevationFAB,
            child: const Icon(Icons.navigate_next),
            onPressed: () {
              Get.toNamed(AppRouteConstants.releaseUploadItemlistNameDesc);
            },
          ) : Container(),
      ),
    );
  }
}
