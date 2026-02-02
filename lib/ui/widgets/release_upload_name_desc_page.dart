import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/ui/widgets/number_limit_input_formatter.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadNameDescPage extends StatelessWidget {

  const ReleaseUploadNameDescPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) {
         return WillPopScope(
           onWillPop: () async {
             if(AppConfig.instance.appInUse != AppInUse.g) return true;

             if(controller.releaseItemsQty.value > 1 && controller.appReleaseItems.isNotEmpty) {
               controller.removeLastReleaseItem();
             }

           return controller.appReleaseItems.isEmpty; ///If not empty keeps on loop removing previous added songs
         },
        child: Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(
             color: controller.releaseItemsQty.value > 1 ? null : Colors.transparent,
             title: controller.releaseItemsQty.value > 1  && controller.appReleaseItems.length < controller.releaseItemsQty.value  ? '${AppTranslationConstants.releaseItem.tr} ${controller.appReleaseItems.length+1} '
                 '${AppTranslationConstants.of.tr} ${controller.releaseItemsQty.value}' : '',
           ),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
             child: SingleChildScrollView(
               child: Column(
                children: <Widget>[
                  AppTheme.heightSpace100,
                  HeaderIntro(
                    subtitle: ReleaseTranslationConstants.releaseUploadNameDesc.tr,
                    showPreLogo: false,
                  ),
                  AppTheme.heightSpace10,
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: controller.nameController,
                      onChanged:(text) => controller.setReleaseName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: ReleaseTranslationConstants.releaseTitle.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      minLines: 2,
                      maxLines: 8,
                      controller: controller.descController,
                      onChanged:(text) => controller.setReleaseDesc(),
                      decoration: InputDecoration(
                        filled: true,
                        labelText: ReleaseTranslationConstants.releaseDesc.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  AppConfig.instance.appInUse == AppInUse.e ?
                  Padding(
                   padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       SizedBox(
                         width: AppTheme.fullWidth(context) / 2.75,
                         child: TextFormField(
                           controller: controller.durationController,
                           keyboardType: TextInputType.number,
                           decoration: InputDecoration(
                               filled: true,
                               labelText: ReleaseTranslationConstants.appItemDurationShort.tr,
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                               )
                           ),
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             NumberLimitInputFormatter(1000),
                           ],
                           onChanged: (text) {
                             controller.setReleaseDuration();
                           },
                         ),
                       ),
                       Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.keyboard_arrow_up),
                             onPressed: () => controller.increase(),
                           ),
                           IconButton(
                             icon: const Icon(Icons.keyboard_arrow_down),
                             onPressed: () => controller.decrease(),
                           ),
                         ],
                       ),
                      AppConfig.instance.appInUse != AppInUse.e ? Container(
                           width: AppTheme.fullWidth(context) / 2.75,
                           alignment: Alignment.centerRight,
                           child:
                           Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               Text(DateTimeUtilities.secondsToMinutes(
                                 int.parse(controller.durationController.text.isNotEmpty ? controller.durationController.text : "0"),),
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
                           controller: controller.physicalPriceController,
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             NumberLimitInputFormatter(500),
                           ],
                           keyboardType: TextInputType.number,
                           decoration: InputDecoration(
                               suffixText: AppCurrency.mxn.value.tr.toUpperCase(),
                               filled: true,
                               hintText: "(${AppTranslationConstants.optional.tr})",
                               labelText: ReleaseTranslationConstants.physicalReleasePrice.tr,
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                               )
                           ),
                           onChanged: (text) {
                             controller.setPhysicalReleasePrice();
                             },
                         ),
                        ),
                    ],),
                  ) : const SizedBox.shrink(),
                  if(controller.releaseItemsQty.value == 1) TitleSubtitleRow("", showDivider: false, vPadding: 10, hPadding: 20, subtitle: ReleaseTranslationConstants.releasePriceMsg.tr, titleFontSize: 14, subTitleFontSize: 12,
                  url: AppProperties.getDigitalPositioningUrl()),
                  AppTheme.heightSpace10,
                  GestureDetector(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.file, size: 20),
                        AppTheme.widthSpace5,
                        Text(controller.releaseFilePreviewURL.isEmpty
                            ? ReleaseTranslationConstants.addReleaseFile.tr
                            : ReleaseTranslationConstants.changeReleaseFile.tr,
                          style: const TextStyle(color: Colors.white70,),
                        ),
                      ],
                    ),
                    onTap: () async {controller.addReleaseFile();}
                  ),
                  Obx(() => controller.releaseFilePreviewURL.isNotEmpty
                      ? Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                      child: Text(controller.releaseFilePreviewURL.value,
                        style: const TextStyle(color: Colors.white70,),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ) : const SizedBox.shrink(),
                  ),
                  AppTheme.heightSpace30
                ],
              ),
             ),
          ),
           floatingActionButton: controller.validateNameDesc() ? FloatingActionButton(
             heroTag: AppHeroTagConstants.clearImg,
             tooltip: AppTranslationConstants.next,
             child: const Icon(Icons.navigate_next),
             onPressed: ()=>{
               controller.addNameDescToReleaseItem()
             },
           ) : const SizedBox.shrink(),
         ),
         );
      }
    );
  }

}
