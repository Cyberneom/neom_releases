import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/core_widgets.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/release_type.dart';

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
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: Center(
              child: _.isLoading ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                HeaderIntro(subtitle: AppTranslationConstants.releaseUploadType.tr,showLogo: false),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AppTheme.heightSpace10,
                       buildActionChip(
                         appEnum: ReleaseType.album,
                         controllerFunction: _.setReleaseType,
                       ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                          appEnum: ReleaseType.single,
                          controllerFunction: _.setReleaseType,
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.ep,
                        controllerFunction: _.setReleaseType,
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                        appEnum: ReleaseType.demo,
                        controllerFunction: _.setReleaseType,
                      ),
                    ]
                ),
                  AppTheme.heightSpace20,
                  TitleSubtitleRow("", hPadding: 20,subtitle: AppTranslationConstants.salesModelMsg.tr,showDivider: false,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
