import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/ui/widgets/settings_row_widget.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'app_settings_controller.dart';

class PrivacyAndTermsPage extends StatelessWidget {

  const PrivacyAndTermsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: AppTranslationConstants.privacyAndPolicy.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              HeaderWidget(AppTranslationConstants.legal.tr),
              SettingRowWidget(
                AppTranslationConstants.termsOfService.tr,
                showDivider: true,
                onPressed: (){
                  CoreUtilities.launchURL(AppFlavour.getTermsOfServiceUrl());
                },
              ),
              SettingRowWidget(
                AppTranslationConstants.privacyPolicy.tr,
                showDivider: true,
                onPressed: (){
                  CoreUtilities.launchURL(AppFlavour.getPrivacyPolicyUrl());
                },
              ),
              SettingRowWidget(
                AppTranslationConstants.legalNotices.tr,
                showDivider: true,
                onPressed: () =>
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Theme(
                          data: ThemeData(
                            brightness: Brightness.dark,
                            fontFamily: AppTheme.fontFamily,
                            cardColor: AppColor.main50,
                            backgroundColor: AppColor.main50,
                          ),
                          child: LicensePage(
                            applicationVersion: AppFlavour.appVersion,
                            applicationName: AppFlavour.appInUse.value,
                          ),
                        ),
                      ),
                    )

              ),
            ],
          ),
        ),
      ),
    );
  }
}
