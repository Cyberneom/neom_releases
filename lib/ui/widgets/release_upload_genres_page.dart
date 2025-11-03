import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadGenresPage extends StatelessWidget {
  const ReleaseUploadGenresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(
             color: controller.releaseItemsQty.value > 1 ? null : Colors.transparent,
             title: controller.releaseItemsQty.value > 1  && controller.appReleaseItems.length < controller.releaseItemsQty.value  ? '${AppTranslationConstants.releaseItem.tr} ${controller.appReleaseItems.length+1} '
                 '${AppTranslationConstants.of.tr} ${controller.releaseItemsQty.value}' : '',
           ),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
              child: Column(
                children: [
                  AppTheme.heightSpace100,
                  HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUploadGenres.tr, showPreLogo: false,),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: controller.genreChips.toList()
                      ),
                    ),
                  ),
                ],
              ),
           ),
           floatingActionButton: controller.selectedGenres.isNotEmpty ? FloatingActionButton(
             tooltip: AppTranslationConstants.next.tr,
             elevation: AppTheme.elevationFAB,
             child: const Icon(Icons.navigate_next),
             onPressed: () {
               if(controller.instrumentsUsed.isNotEmpty) {
                 controller.addGenresToReleaseItem();
               } else {
                 Get.snackbar(
                     MessageTranslationConstants.introInstrumentSelection.tr,
                     MessageTranslationConstants.introInstrumentMsg.tr,
                     snackPosition: SnackPosition.bottom);
               }
             },
           ) : const SizedBox.shrink(),
         );
      }
    );
  }

}
