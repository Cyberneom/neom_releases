import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/summary_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import '../release_upload_controller.dart';

class ReleaseUploadInfoPage extends StatelessWidget {
  const ReleaseUploadInfoPage({super.key});

  @override
  Widget build(BuildContext context) {

    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async {
            ///DPRECATED
            if(_.releaseItemsQty.value > 1 && _.appReleaseItems.isNotEmpty) {
              _.removeLastReleaseItem();
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
                  HeaderIntro(subtitle: AppTranslationConstants.releaseUploadPLaceDate.tr, showPreLogo: false,),
                  AppTheme.heightSpace10,
                  // AppFlavour.appInUse == AppInUse.e ? Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     SizedBox(
                  //       width: AppTheme.fullWidth(context)/2,
                  //       child: GestureDetector(
                  //         child: Row(
                  //           children: <Widget>[
                  //             Checkbox(
                  //               value: _.isPhysical.value,
                  //               onChanged: (bool? newValue) {
                  //                 _.setIsPhysical();
                  //                 },
                  //             ),
                  //             Text(AppTranslationConstants.includesPhysical.tr),
                  //           ],
                  //         ),
                  //         onTap: ()=>_.setIsPhysical(),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: AppTheme.fullWidth(context)/3,
                  //       child: TextFormField(
                  //         controller: _.physicalPriceController,
                  //         enabled: _.isPhysical.value,
                  //         inputFormatters: [
                  //           FilteringTextInputFormatter.digitsOnly,
                  //           NumberLimitInputFormatter(1000),
                  //         ],
                  //         keyboardType: TextInputType.number,
                  //         decoration: InputDecoration(
                  //             suffixText: AppCurrency.mxn.value.tr.toUpperCase(),
                  //             filled: true,
                  //             hintText: "(${AppTranslationConstants.optional.tr})",
                  //             labelText: AppTranslationConstants.releasePrice.tr,
                  //             border: OutlineInputBorder(
                  //               borderRadius: BorderRadius.circular(10),
                  //             )
                  //         ),
                  //         onChanged: (text) {
                  //           _.setDigitalReleasePrice();
                  //           },
                  //       ),
                  //     ),
                  //   ],
                  // ) : const SizedBox.shrink(),
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
                                value: _.isAutoPublished.value,
                                onChanged: (bool? newValue) {
                                  _.setIsAutoPublished();
                                },
                              ),
                              Text(AppTranslationConstants.autoPublishingEditingMsg.tr),
                            ],
                          ),
                          onTap: ()=>_.setIsAutoPublished(),
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.fullWidth(context)/2.8,
                        child: DropdownButton<int>(
                          hint: Text(AppTranslationConstants.publishedYear.tr),
                          value: _.publishedYear.value != 0 ? _.publishedYear.value : null,
                          onChanged: (selectedYear) {
                            if(selectedYear != null) {
                              _.setPublishedYear(selectedYear);
                            }
                          },
                          items: _.getYearsList().reversed.map((int year) {
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
                  _.isAutoPublished.value ? const SizedBox.shrink() : TextFormField(
                    controller: _.placeController,
                    onTap:() => _.getPublisherPlace(context) ,
                    enabled: !_.isAutoPublished.value,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: AppTranslationConstants.specifyPublishingPlace.tr,
                      labelStyle: const TextStyle(fontSize: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AppTheme.heightSpace20,
                  _.releaseCoverImgPath.isNotEmpty && AppFlavour.appInUse == AppInUse.e
                      ? Text(AppTranslationConstants.tapCoverToPreviewRelease.tr,
                    style: const TextStyle(decoration: TextDecoration.underline),)
                      : const SizedBox.shrink(),
                  _.releaseCoverImgPath.isNotEmpty ? AppTheme.heightSpace5 : const SizedBox.shrink(),
                  _.releaseCoverImgPath.isEmpty ?
                  GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 20),
                          AppTheme.widthSpace5,
                          Text(AppTranslationConstants.addReleaseCoverImg.tr,
                            style: const TextStyle(color: Colors.white70,),
                          ),
                        ],
                      ),
                      onTap: () => _.addReleaseCoverImg()
                  ) :
                  Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: GestureDetector(
                            child: Image.file(
                              File(_.releaseCoverImgPath.value),
                              height: 180,
                              width: 180
                            ),
                            onTap: () => AppFlavour.appInUse == AppInUse.e ? _.gotoPdfPreview() : {}
                          ),
                        ),
                        FloatingActionButton(
                          mini: true,
                          heroTag: AppHeroTagConstants.clearImg,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          onPressed: () => _.clearReleaseCoverImg(),
                          elevation: 10,
                          child: Icon(Icons.close,
                              color: AppColor.white80,
                              size: 25
                          ),
                        ),
                      ]
                  ),
                  AppTheme.heightSpace20,
                  _.validateInfo() ? SummaryButton(AppTranslationConstants.checkSummary.tr,
                    onPressed: _.gotoReleaseSummary,
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
