import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import '../release_upload_controller.dart';
import 'release_upload_instr_list.dart';

class ReleaseUploadInstrPage extends StatelessWidget {
  const ReleaseUploadInstrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Column(
              children: <Widget>[
                HeaderIntro(subtitle: AppTranslationConstants.releaseUploadInstr.tr, showLogo: false,),
                const Expanded(child: ReleaseUploadInstrList(),),
              ]
          ),
        ),
      floatingActionButton: _.requiredInstruments.isNotEmpty ? FloatingActionButton(
          tooltip: AppTranslationConstants.next.tr,
          elevation: AppTheme.elevationFAB,
          child: const Icon(Icons.navigate_next),
          onPressed: () {
            if(_.requiredInstruments.isNotEmpty) {
              _.addInstrumentsToReleaseItem();
            } else {
              Get.snackbar(
                  MessageTranslationConstants.introInstrumentSelection.tr,
                  MessageTranslationConstants.introInstrumentMsg.tr,
                  snackPosition: SnackPosition.bottom);
            }
          },
        ) : Container(),
      ),
    );
  }
}
