import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/settings_row_widget.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
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
            SettingRowWidget(AppTranslationConstants.digitalPositioning.tr, url: AppFlavour.getDigitalPositioningUrl()),
            HeaderWidget(AppTranslationConstants.promotion.tr),
            SettingRowWidget(AppTranslationConstants.presskit.tr, url: AppFlavour.getPresskitUrl()),
            SettingRowWidget(AppTranslationConstants.mediatour.tr, url: AppFlavour.getMediatourUrl()),
            HeaderWidget(AppTranslationConstants.education.tr, secondHeader: true,),
            SettingRowWidget(AppTranslationConstants.consultancy.tr, url: AppFlavour.getConsultancyUrl()),
            SettingRowWidget(AppTranslationConstants.onlineClinics.tr, url: AppFlavour.getOnlineClinicUrl()),
            HeaderWidget(AppTranslationConstants.publishingHouse.tr, secondHeader: true,),
            SettingRowWidget(AppTranslationConstants.copyright.tr, url: AppFlavour.getCopyrightUrl()),
            SettingRowWidget(AppTranslationConstants.coverDesign.tr, url: AppFlavour.getCoverDesignUrl()),
            SettingRowWidget(AppTranslationConstants.startCampaignUrl.tr, url: AppFlavour.getStartCampaignUrl()),
            //TODO
            _.userController.user!.userRole == UserRole.subscriber
                ? Container() :
                Column(children: [
                  const HeaderWidget("Admin Center", secondHeader: true,),
                  SettingRowWidget(AppTranslationConstants.createCoupon.tr, navigateTo: AppRouteConstants.createCoupon),
                  const SettingRowWidget("Crear Patrocinador", navigateTo: AppRouteConstants.createSponsor),
                ],),

            SettingRowWidget("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.settingPrivacyMsg.tr),
          ],
        ),
        ),
    ),);
  }
}
