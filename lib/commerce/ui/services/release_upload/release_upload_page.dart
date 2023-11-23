import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/summary_button.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_color.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
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
                    HeaderIntro(subtitle: AppTranslationConstants.releaseUpload.tr, showLogo: AppFlavour.appInUse == AppInUse.g),
                    AppTheme.heightSpace10,
                    TitleSubtitleRow(AppTranslationConstants.digitalPositioning.tr,
                      subtitle: AppTranslationConstants.releaseUploadIntro.tr,
                      showDivider: false,
                    ),
                    AppTheme.heightSpace10,
                    if(AppFlavour.appInUse == AppInUse.e)
                      Column(
                        children: [
                          TitleSubtitleRow(AppTranslationConstants.digitalSalesModel.tr,
                            titleFontSize: 14, subTitleFontSize: 12,
                            subtitle: AppTranslationConstants.digitalSalesModelMsg.tr,
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
                          TitleSubtitleRow(AppTranslationConstants.physicalSalesModel.tr,
                              subtitle: AppTranslationConstants.physicalSalesModelMsg.tr,
                              titleFontSize: 14, subTitleFontSize: 12,
                              showDivider: false
                          ),
                          AppTheme.heightSpace10,
                        ],
                      ),
                    SummaryButton(AppTranslationConstants.toStart.tr, onPressed: ()=>Get.toNamed(AppRouteConstants.releaseUploadType)),
                    AppTheme.heightSpace10,
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
