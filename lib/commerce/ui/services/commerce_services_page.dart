import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'commerce_services_controller.dart';

class CommerceServicesPage extends StatelessWidget {

  const CommerceServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CommerceServicesController>(
      id: AppPageIdConstants.settingsPrivacy,
      init: CommerceServicesController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.offeredServices.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
          children: <Widget>[
            HeaderWidget(AppTranslationConstants.digitalLibrary.tr),
            TitleSubtitleRow(AppTranslationConstants.digitalPositioning.tr, url: AppFlavour.getDigitalPositioningUrl()),
            HeaderWidget(AppTranslationConstants.promotion.tr),
            TitleSubtitleRow(AppTranslationConstants.presskit.tr, url: AppFlavour.getPresskitUrl()),
            TitleSubtitleRow(AppTranslationConstants.mediatour.tr, url: AppFlavour.getMediatourUrl()),
            HeaderWidget(AppTranslationConstants.education.tr, secondHeader: true,),
            TitleSubtitleRow(AppTranslationConstants.consultancy.tr, url: AppFlavour.getConsultancyUrl()),
            TitleSubtitleRow(AppTranslationConstants.onlineClinics.tr, url: AppFlavour.getOnlineClinicUrl()),
            HeaderWidget(AppTranslationConstants.publishingHouse.tr, secondHeader: true,),
            TitleSubtitleRow(AppTranslationConstants.copyright.tr, url: AppFlavour.getCopyrightUrl()),
            TitleSubtitleRow(AppTranslationConstants.coverDesign.tr, url: AppFlavour.getCoverDesignUrl()),
            TitleSubtitleRow(AppTranslationConstants.startCampaignUrl.tr, url: AppFlavour.getStartCampaignUrl()),
            TitleSubtitleRow("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.offeredServicesMsg.tr),
          ],
        ),
        ),
      ),
    );
  }
}
