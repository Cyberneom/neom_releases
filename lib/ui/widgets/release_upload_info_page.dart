import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/buttons/summary_button.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadInfoPage extends StatelessWidget {
  const ReleaseUploadInfoPage({super.key});

  @override
  Widget build(BuildContext context) {

    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async {
            if(controller.releaseItemsQty.value > 1 && controller.appReleaseItems.isNotEmpty) {
              controller.removeLastReleaseItem();
            }
            return true; // Return true to allow the back button press to pop the screen
        },
        child: Obx(()=> Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          backgroundColor: AppColor.main50,
          body: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
            decoration: AppTheme.appBoxDecoration,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AppTheme.heightSpace100,
                  HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUploadPLaceDate.tr, showPreLogo: false,),
                  AppTheme.heightSpace10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: AppTheme.fullWidth(context)/2,
                        child: GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: controller.isAutoPublished.value,
                                onChanged: (bool? newValue) {
                                  controller.setIsAutoPublished();
                                },
                              ),
                              Text(ReleaseTranslationConstants.autoPublishingEditingMsg.tr),
                            ],
                          ),
                          onTap: ()=>controller.setIsAutoPublished(),
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.fullWidth(context)/2.8,
                        child: DropdownButton<int>(
                          hint: Text(ReleaseTranslationConstants.publishedYear.tr),
                          value: controller.publishedYear.value != 0 ? controller.publishedYear.value : null,
                          onChanged: (selectedYear) {
                            if(selectedYear != null) {
                              controller.setPublishedYear(selectedYear);
                            }
                          },
                          items: controller.getYearsList().reversed.map((int year) {
                            return DropdownMenuItem<int>(
                              alignment: Alignment.center,
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                          alignment: Alignment.center,
                          iconSize: 18,
                          elevation: 16,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppColor.getMain(),
                          underline: Container(
                            height: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppTheme.heightSpace20,
                  controller.isAutoPublished.value ? const SizedBox.shrink() : TextFormField(
                    controller: controller.placeController,
                    onTap:() => controller.getPublisherPlace(context) ,
                    enabled: !controller.isAutoPublished.value,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: ReleaseTranslationConstants.specifyPublishingPlace.tr,
                      labelStyle: const TextStyle(fontSize: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AppTheme.heightSpace20,
                  controller.releaseCoverImgPath.isNotEmpty && AppConfig.instance.appInUse == AppInUse.e
                      ? Text(ReleaseTranslationConstants.tapCoverToPreviewRelease.tr,
                    style: const TextStyle(decoration: TextDecoration.underline),)
                      : const SizedBox.shrink(),
                  controller.releaseCoverImgPath.isNotEmpty ? AppTheme.heightSpace5 : const SizedBox.shrink(),
                  controller.releaseCoverImgPath.isEmpty ?
                  GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 20),
                          AppTheme.widthSpace5,
                          Text(ReleaseTranslationConstants.addReleaseCoverImg.tr,
                            style: const TextStyle(color: Colors.white70,),
                          ),
                        ],
                      ),
                      onTap: () => controller.addReleaseCoverImg()
                  ) :
                  Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: GestureDetector(
                            child: Image.file(
                              File(controller.releaseCoverImgPath.value),
                              height: 180,
                              width: 180
                            ),
                            onTap: () => AppConfig.instance.appInUse == AppInUse.e ? controller.gotoPdfPreview() : {}
                          ),
                        ),
                        FloatingActionButton(
                          mini: true,
                          heroTag: AppHeroTagConstants.clearImg,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          onPressed: () => controller.clearReleaseCoverImg(),
                          elevation: 10,
                          child: Icon(Icons.close,
                              color: AppColor.white80,
                              size: 25
                          ),
                        ),
                      ]
                  ),
                  AppTheme.heightSpace20,
                  controller.validateInfo() ? SummaryButton(AppTranslationConstants.viewSummary.tr,
                    onPressed: controller.gotoReleaseSummary,
                  ) : const SizedBox.shrink(),
                  AppTheme.heightSpace20
                ],
              ),
            ),
          ),
        )),
        );
      }
    );
  }

}
