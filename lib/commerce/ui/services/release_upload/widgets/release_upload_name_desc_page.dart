import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/number_limit_input_formatter.dart';
import 'package:neom_commons/core/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';

import '../release_upload_controller.dart';

class ReleaseUploadNameDescPage extends StatelessWidget {
  const ReleaseUploadNameDescPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
         return WillPopScope(
           onWillPop: () async {
             if(_.releaseItemsQty.value > 1 && _.appReleaseItems.isNotEmpty) {
               _.removeLastReleaseItem();
             }

           return _.appReleaseItems.isEmpty; ///If not empty keeps on loop removing previous added songs
         },
        child: Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(
             color: _.releaseItemsQty.value > 1 ? null : Colors.transparent,
             title: _.releaseItemsQty.value > 1  && _.appReleaseItems.length < _.releaseItemsQty.value  ? '${AppTranslationConstants.releaseItem.tr} ${_.appReleaseItems.length+1} '
                 '${AppTranslationConstants.of.tr} ${_.releaseItemsQty.value}' : '',
           ),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
             child: SingleChildScrollView(
               child: Column(
                children: <Widget>[
                  AppFlavour.appInUse == AppInUse.g ? AppTheme.heightSpace100 : Container(),
                  HeaderIntro(
                    subtitle: AppTranslationConstants.releaseUploadNameDesc.tr,
                    showLogo: AppFlavour.appInUse == AppInUse.g,
                  ),
                  AppTheme.heightSpace10,
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.nameController,
                      onChanged:(text) => _.setReleaseName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.releaseTitle.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      minLines: 2,
                      maxLines: 8,
                      controller: _.descController,
                      onChanged:(text) => _.setReleaseDesc(),
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.releaseDesc.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  AppFlavour.appInUse == AppInUse.e ?
                  Container(
                   padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       SizedBox(
                         width: AppTheme.fullWidth(context) / 2.75,
                         child: TextFormField(
                           controller: _.durationController,
                           keyboardType: TextInputType.number,
                           decoration: InputDecoration(
                               filled: true,
                               labelText: AppTranslationConstants.releaseDuration.tr,
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                               )
                           ),
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             NumberLimitInputFormatter(1000),
                           ],
                           onChanged: (text) {
                             _.setReleaseDuration();
                           },
                         ),
                       ),
                       Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.keyboard_arrow_up),
                             onPressed: () {
                               _.increase();
                             },
                           ),
                           IconButton(
                             icon: const Icon(Icons.keyboard_arrow_down),
                             onPressed: () {
                               _.decrease();
                             },
                           ),
                         ],
                       ),
                      AppFlavour.appInUse != AppInUse.e ? Container(
                           width: AppTheme.fullWidth(context) / 2.75,
                           alignment: Alignment.centerRight,
                           child:
                           Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               Text(AppUtilities.secondsToMinutes(
                                 int.parse(_.durationController.text.isNotEmpty ? _.durationController.text : "0"),),
                                 style: const TextStyle(fontSize: 40),
                               ),
                               Text('${AppTranslationConstants.minutes.tr} - ${AppTranslationConstants.seconds.tr}',
                                   style: const TextStyle(fontSize: 10, letterSpacing: 1.2 )
                               ),
                             ],
                           )
                      ) : SizedBox(
                        width: AppTheme.fullWidth(context) / 2.75,
                        child: TextFormField(
                           controller: _.digitalPriceController,
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             NumberLimitInputFormatter(500),
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
                    ],),
                  ) : Container(),
                  if(_.releaseItemsQty.value == 1) TitleSubtitleRow("", showDivider: false, vPadding: 10, hPadding: 20, subtitle: AppTranslationConstants.releasePriceMsg.tr,
                  url: AppFlavour.getDigitalPositioningUrl()),
                  AppTheme.heightSpace10,
                  GestureDetector(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.file, size: 20),
                        AppTheme.widthSpace5,
                        Text(_.releaseFilePreviewURL.isEmpty
                            ? AppTranslationConstants.addReleaseFile.tr
                            : AppTranslationConstants.changeReleaseFile.tr,
                          style: const TextStyle(color: Colors.white70,),
                        ),
                      ],
                    ),
                    onTap: () async {_.addReleaseFile();}
                  ),
                  Obx(() => _.releaseFilePreviewURL.isNotEmpty
                      ? Container(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                      child: Text(_.releaseFilePreviewURL.value,
                        style: const TextStyle(color: Colors.white70,),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ) : Container(),
                  ),
                  AppTheme.heightSpace30
                ],
              ),
             ),
          ),
           floatingActionButton: _.validateNameDesc() ? FloatingActionButton(
             heroTag: AppHeroTagConstants.clearImg,
             tooltip: AppTranslationConstants.next,
             child: const Icon(Icons.navigate_next),
             onPressed: ()=>{
               _.addNameDescToReleaseItem()
             },
           ) : Container(),
         ),
         );
      }
    );
  }

}
