import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import '../release_upload_controller.dart';

class ReleaseUploadGenresPage extends StatelessWidget {
  const ReleaseUploadGenresPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(
             color: _.releaseItemsQty > 1 ? null : Colors.transparent,
             title: _.releaseItemsQty > 1 ? '${AppTranslationConstants.releaseItem.tr} ${_.appReleaseItems.length+1} '
                 '${AppTranslationConstants.of.tr} ${_.releaseItemsQty}' : '',
           ),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
              child: Column(
                children: [
                  AppFlavour.appInUse == AppInUse.gigmeout ? AppTheme.heightSpace100 : Container(),
                  HeaderIntro(subtitle: AppTranslationConstants.releaseUploadGenres.tr, showLogo: AppFlavour.appInUse == AppInUse.gigmeout,),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: _.genreChips.toList()
                      ),
                    ),
                  ),
                ],
              ),
           ),
           floatingActionButton: _.selectedGenres.isNotEmpty ? FloatingActionButton(
             tooltip: AppTranslationConstants.next.tr,
             elevation: AppTheme.elevationFAB,
             child: const Icon(Icons.navigate_next),
             onPressed: () {
               if(_.requiredInstruments.isNotEmpty) {
                 _.addGenresToReleaseItem();
               } else {
                 Get.snackbar(
                     MessageTranslationConstants.introInstrumentSelection.tr,
                     MessageTranslationConstants.introInstrumentMsg.tr,
                     snackPosition: SnackPosition.bottom);
               }
             },
           ) : Container(),
         );
      }
    );
  }

}
