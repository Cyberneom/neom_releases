import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/buttons/custom_back_button.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:sint/sint.dart';

import '../release_upload_controller.dart';
import 'release_upload_summary_background.dart';
import 'release_upload_summary_rubber_page.dart';


class ReleaseUploadSummaryPage extends StatelessWidget {
  const ReleaseUploadSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) => Scaffold(
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
