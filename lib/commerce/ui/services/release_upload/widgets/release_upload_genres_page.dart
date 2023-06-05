import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
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
           appBar: AppBarChild(color: Colors.transparent),
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    HeaderIntro(subtitle: AppTranslationConstants.releaseUploadGenres.tr, showLogo: false,),
                    SizedBox(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: _.genreChips.toList()
                        ),
                       ),
                     ),
                ],
              ),
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
