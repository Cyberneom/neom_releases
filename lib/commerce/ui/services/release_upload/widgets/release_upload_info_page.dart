import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/number_limit_input_formatter.dart';
import 'package:neom_commons/core/ui/widgets/summary_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';

import '../release_upload_controller.dart';

class ReleaseUploadInfoPage extends StatelessWidget {
  const ReleaseUploadInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
        return Obx(()=> Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          body:  Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
            decoration: AppTheme.appBoxDecoration,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  HeaderIntro(subtitle: AppTranslationConstants.releaseUploadPLaceDate.tr, showLogo: false,),
                  AppTheme.heightSpace10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: AppTheme.fullWidth(context) / 2.3,
                        child: GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: _.isPhysical,
                                onChanged: (bool? newValue) {
                                  _.setIsPhysical();
                                  },
                              ),
                              Text(AppTranslationConstants.includesPhysical.tr),
                            ],
                          ),
                          onTap: ()=>_.setIsPhysical(),
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.fullWidth(context) / 2.5,
                        child: TextFormField(
                          controller: _.physicalPriceController,
                          enabled: _.isPhysical,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            NumberLimitInputFormatter(1000),
                          ],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              suffixText: AppCurrency.mxn.value.tr.toUpperCase(),
                              filled: true,
                              hintText: "(${AppTranslationConstants.optional.tr})",
                              labelText: AppTranslationConstants.releasePrice.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )
                          ),
                          onChanged: (text) {
                            _.setDigitalReleasePrice();
                            },
                        ),
                      ),
                    ],
                  ),
                  AppTheme.heightSpace10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: AppTheme.fullWidth(context) / 2.2,
                        child: GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: _.isAutoPublished,
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
                        width: AppTheme.fullWidth(context) / 2.5,
                        child: DropdownButton<int>(
                          hint: Text(AppTranslationConstants.publishedYear.tr),
                          value: _.publishedYear != 0 ? _.publishedYear : null,
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
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 20,
                          elevation: 16,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppColor.main75,
                          underline: Container(
                            height: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppTheme.heightSpace20,
                  _.isAutoPublished ? Container() : TextFormField(
                    controller: _.placeController,
                    onTap:() => _.getPublisherPlace(context) ,
                    enabled: !_.isAutoPublished,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: AppTranslationConstants.specifyPublishingPlace.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AppTheme.heightSpace20,
                  _.postUploadController.croppedImageFile.path.isNotEmpty ?
                  Text(AppTranslationConstants.tapCoverToPreviewRelease.tr, style: const TextStyle(decoration: TextDecoration.underline),) :
                  Container(),
                  _.postUploadController.croppedImageFile.path.isNotEmpty ?
                  AppTheme.heightSpace5 : Container(),
                  _.postUploadController.croppedImageFile.path.isEmpty ?
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
                              File(_.postUploadController.croppedImageFile.path),
                              height: 270,
                              width: 180
                            ),
                            onTap: () => Get.toNamed(AppRouteConstants.PDFViewer,
                                arguments: [_.releaseFile?.paths.first, false]),
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
                  ) : Container(),
                  AppTheme.heightSpace20
                ],
              ),
            ),
          ),
        ));
      }
    );
  }
}
