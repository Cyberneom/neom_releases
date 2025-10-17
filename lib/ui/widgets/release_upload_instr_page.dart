import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';
import 'release_upload_instr_list.dart';

class ReleaseUploadInstrPage extends StatelessWidget {
  const ReleaseUploadInstrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => SafeArea(
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(
            color: _.releaseItemsQty.value > 1 ? null : Colors.transparent,
            title: _.releaseItemsQty.value > 1  && _.appReleaseItems.length < _.releaseItemsQty.value  ? '${AppTranslationConstants.releaseItem.tr} ${_.appReleaseItems.length+1} '
                '${AppTranslationConstants.of.tr} ${_.releaseItemsQty.value}' : '',
          ),
          backgroundColor: AppColor.main50,
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: Column(
                children: <Widget>[
                  AppTheme.heightSpace100,
                  HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUploadInstr.tr, showPreLogo: false,),
                  const Expanded(child: ReleaseUploadInstrList(),),
                ]
            ),
          ),
        floatingActionButton: _.instrumentsUsed.value.isNotEmpty ? FloatingActionButton(
            tooltip: AppTranslationConstants.next.tr,
            elevation: AppTheme.elevationFAB,
            child: const Icon(Icons.navigate_next),
            onPressed: () {
              if(_.instrumentsUsed.isNotEmpty) {
                _.addInstrumentsToReleaseItem();
              } else {
                AppUtilities.showSnackBar(
                  title: MessageTranslationConstants.introInstrumentSelection.tr,
                  message: MessageTranslationConstants.introInstrumentMsg.tr,
                );
              }
            },
          ) : const SizedBox.shrink(),
        ),
      ),
    );
  }

}
