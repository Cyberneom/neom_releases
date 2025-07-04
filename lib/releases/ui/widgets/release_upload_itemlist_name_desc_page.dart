
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/commons/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';

import '../release_upload_controller.dart';

class ReleaseUploadItemlistNameDescPage extends StatelessWidget {
  const ReleaseUploadItemlistNameDescPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(color: Colors.transparent),
           backgroundColor: AppColor.main50,
           body: Container(
             height: AppTheme.fullHeight(context),
             decoration: AppTheme.appBoxDecoration,
             child: SingleChildScrollView(
               child: Column(
                children: <Widget>[
                  AppFlavour.appInUse == AppInUse.g ? AppTheme.heightSpace100 : const SizedBox.shrink(),
                  HeaderIntro(
                    subtitle: '${AppTranslationConstants.releaseUploadItemlistNameDesc1.tr} ${_.appReleaseItem.value.type.value.tr.toUpperCase()}? '
                        '${AppTranslationConstants.releaseUploadItemlistNameDesc2.tr}',
                    showLogo: AppFlavour.appInUse == AppInUse.g,
                  ),
                  AppTheme.heightSpace10,
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: _.itemlistNameController,
                      onChanged:(text) => _.setItemlistName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: '${AppTranslationConstants.releaseItemlistTitle.tr} ${_.appReleaseItem.value.type.value.tr.toLowerCase()}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      minLines: 3, maxLines: 6,
                      controller: _.itemlistDescController,
                      onChanged:(text) => _.setItemlistDesc() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: '${AppTranslationConstants.releaseItemlistDesc.tr} ${_.appReleaseItem.value.type.value.tr.toLowerCase()}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  TitleSubtitleRow("", showDivider: false, vPadding: 10, hPadding: 20,
                      subtitle: AppTranslationConstants.releasePriceMsg.tr,
                      url: AppProperties.getDigitalPositioningUrl()
                  ),
                  AppTheme.heightSpace10,
                ],
              ),
             ),
          ),
           floatingActionButton: _.validateItemlistNameDesc() ? FloatingActionButton(
             heroTag: AppHeroTagConstants.clearImg,
             tooltip: AppTranslationConstants.next,
             child: const Icon(Icons.navigate_next),
             onPressed: ()=>{
               _.addItemlistNameDesc()
             },
           ) : const SizedBox.shrink(),
         );
      }
    );
  }

}
