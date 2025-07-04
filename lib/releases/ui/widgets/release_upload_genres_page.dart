import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/commons/utils/constants/message_translation_constants.dart';

import '../release_upload_controller.dart';

class ReleaseUploadGenresPage extends StatelessWidget {
  const ReleaseUploadGenresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(
             color: _.releaseItemsQty.value > 1 ? null : Colors.transparent,
             title: _.releaseItemsQty.value > 1  && _.appReleaseItems.length < _.releaseItemsQty.value  ? '${AppTranslationConstants.releaseItem.tr} ${_.appReleaseItems.length+1} '
                 '${AppTranslationConstants.of.tr} ${_.releaseItemsQty.value}' : '',
           ),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
              child: Column(
                children: [
                  AppTheme.heightSpace100,
                  HeaderIntro(subtitle: AppTranslationConstants.releaseUploadGenres.tr, showPreLogo: false,),
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
               if(_.instrumentsUsed.isNotEmpty) {
                 _.addGenresToReleaseItem();
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
