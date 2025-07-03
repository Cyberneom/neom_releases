import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/custom_back_button.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';

import '../release_upload_controller.dart';
import 'release_upload_summary_background.dart';
import 'release_upload_summary_rubber_page.dart';


class ReleaseUploadSummaryPage extends StatelessWidget {
  const ReleaseUploadSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => Scaffold(
      body: Container(
        height: AppTheme.fullHeight(context),
        decoration: AppTheme.appBoxDecoration,
        child: const Stack(
        alignment: Alignment.center,
        children: [
          OnlinePositioningSummaryBackground(),
          ReleaseUploadSummaryRubberPage(),
          CustomBackButton(),
        ],
      ),),
    ),
    );
  }

}
