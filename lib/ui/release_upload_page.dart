import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/buttons/summary_button.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../utils/constants/release_translation_constants.dart';
import 'release_upload_controller.dart';

class ReleaseUploadPage extends StatelessWidget {
  const ReleaseUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      init: ReleaseUploadController(),
      builder: (_) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          backgroundColor: AppColor.main50,
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: AppTheme.appBoxDecoration,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTheme.heightSpace30,
                    HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUpload.tr, showPreLogo: AppConfig.instance.appInUse != AppInUse.e),
                    AppTheme.heightSpace10,
                    TitleSubtitleRow(ReleaseTranslationConstants.digitalPositioning.tr,
                      subtitle: ReleaseTranslationConstants.releaseUploadIntro.tr,
                      showDivider: false,
                    ),
                    AppTheme.heightSpace10,
                    if(AppConfig.instance.appInUse == AppInUse.e)
                      Column(
                        children: [
                          TitleSubtitleRow(ReleaseTranslationConstants.digitalSalesModel.tr,
                            titleFontSize: 14, subTitleFontSize: 12,
                            subtitle: ReleaseTranslationConstants.digitalSalesModelMsg.tr,
                            showDivider: false,
                          ),
                          AppTheme.heightSpace10,
                          SizedBox(
                            width: AppTheme.fullWidth(context)*0.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.asset(AppAssets.releaseUploadIntro,
                                fit: BoxFit.cover,),
                            ),
                          ),
                          AppTheme.heightSpace10,
                          TitleSubtitleRow(ReleaseTranslationConstants.physicalSalesModel.tr,
                              subtitle: ReleaseTranslationConstants.physicalSalesModelMsg.tr,
                              titleFontSize: 14, subTitleFontSize: 12,
                              showDivider: false
                          ),
                          AppTheme.heightSpace10,
                        ],
                      ),
                    SummaryButton(AppTranslationConstants.toStart.tr, onPressed: ()=>Get.toNamed(AppRouteConstants.releaseUploadType)),
                    AppTheme.heightSpace30,
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );

  }
}
