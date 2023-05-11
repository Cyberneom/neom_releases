import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import 'package:neom_commons/core/utils/enums/usage_reason.dart';
import '../event_controller.dart';

class CreateEventNameDescPage extends StatelessWidget {
  const CreateEventNameDescPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(color: Colors.transparent),
           body: SingleChildScrollView(
           child: Container(
              height: AppTheme.fullHeight(context),
              decoration: AppTheme.appBoxDecoration,
              child: Column(
                children: <Widget>[
                  AppTheme.heightSpace50,
                  HeaderIntro(subtitle: AppTranslationConstants.createEventNameDesc.tr),
                  AppTheme.heightSpace10,
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.nameController,
                      onChanged:(text) => _.setEventName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.eventTitle.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      minLines: 1,
                      maxLines: 2,
                      controller: _.descController,
                      onChanged:(text) => _.setEventDesc() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.eventDesc.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  (_.event.type != EventType.festival && _.event.bandFulfillments.isEmpty && !_.isOnlineEvent)
                  ? Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.maxDistanceKmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          filled: true,
                          hintText: "(${AppTranslationConstants.optional.tr})",
                          labelText: AppTranslationConstants.selectMaxDistanceKm.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    ),
                  ) : Container(),
                  (_.event.type != EventType.jamming && _.event.type != EventType.festival && _.event.bandFulfillments.isEmpty)
                  ? Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.coverageController,
                      keyboardType: TextInputType.number,
                      //inputFormatters: [FilteringTextInputFormatter.deny(new RegExp('[/^(10{2}(?:,0{2})?|[1-9]?\d(?:,\d{2})?)/]'))],
                      decoration: InputDecoration(
                          filled: true,
                          hintText: "(${AppTranslationConstants.optional.tr})",
                          labelText: AppTranslationConstants.selectPercentageCoverage.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    ),
                  ) : Container(),
                  (_.event.type != EventType.rehearsal && _.event.reason == UsageReason.professional) ?
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                        width: AppTheme.fullWidth(context)*0.6,
                        child: TextFormField(
                          controller: _.coverAmountController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              filled: true,
                              hintText: "${AppTranslationConstants.specifyCoverPrice.tr} (${AppTranslationConstants.optional.tr})",
                              labelText: AppTranslationConstants.coverPrice.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          onChanged: (text) {
                            _.setCoverAmount() ;
                          },
                        ),
                      ),
                      Column(
                        children: [
                          Container(height: 20),
                          DropdownButton<String>(
                            items: AppCurrency.values.map((AppCurrency currency) {
                              return DropdownMenuItem<String>(
                                value: currency.value,
                                child: Text(currency.value.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (String? chosenCurrency) {
                              _.setCurrency(chosenCurrency!);
                            },
                            value: _.event.coverPrice?.currency.value ?? AppCurrency.appCoin.value,
                            elevation: 20,
                            dropdownColor: AppColor.getMain(),
                          ),
                        ],
                      ),
                    ],)
                  ) : Container(),
                  (_.event.type != EventType.rehearsal && _.event.reason == UsageReason.professional)
                  ? Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.paymentAmountController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          filled: true,
                          hintText: AppTranslationConstants.specifyAmountContribute.tr,
                          labelText: _.event.type == EventType.festival
                            ? AppTranslationConstants.contributionAmountBands.tr
                            : AppTranslationConstants.contributionAmountMusicians.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                      onChanged: (text) {
                        _.setPaymentAmount();
                      },
                    ),
                  ) : Container(),
                  AppTheme.heightSpace10,
                  GestureDetector(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 20),
                        AppTheme.widthSpace5,
                        Text(_.postUploadController.imageFile.path.isEmpty
                            ? AppTranslationConstants.addEventImg.tr
                            : AppTranslationConstants.changeImage.tr,
                          style: const TextStyle(color: Colors.white70,),
                        ),
                      ],
                    ),
                    onTap: () => _.addEventImage()
                  ),
                  AppTheme.heightSpace10,
                  Obx(() =>_.postUploadController.croppedImageFile.path.isEmpty ? Container():
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.file(File(_.postUploadController.croppedImageFile.path),height: 150, width: 150),
                      FloatingActionButton(
                        mini: true,
                        heroTag: AppHeroTagConstants.clearImg,
                        backgroundColor: Theme.of(context).primaryColorLight,
                        onPressed: () => _.clearEventImage(),
                        elevation: 10,
                        child: Icon(Icons.close,
                            color: AppColor.white80,
                            size: 15),
                      ),
                  ]),),
                  AppTheme.heightSpace20
                ],
              ),
             ),
          ),
           floatingActionButton: _.validateNameDesc() ? FloatingActionButton(
             heroTag: AppHeroTagConstants.clearImg,
             tooltip: AppTranslationConstants.next,
             child: const Icon(Icons.navigate_next),
             onPressed: ()=>{
               _.addCoverGenresToEvent()
             },
           ) : Container(),
         );
      }
    );
  }

}
