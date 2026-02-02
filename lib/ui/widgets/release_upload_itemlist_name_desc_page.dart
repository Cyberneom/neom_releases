import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadItemlistNameDescPage extends StatelessWidget {

  const ReleaseUploadItemlistNameDescPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) {
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
                  AppConfig.instance.appInUse == AppInUse.g ? AppTheme.heightSpace100 : const SizedBox.shrink(),
                  HeaderIntro(
                    subtitle: '${ReleaseTranslationConstants.releaseUploadItemlistNameDesc1.tr} ${controller.appReleaseItem.value.type.value.tr.toUpperCase()}? '
                        '${ReleaseTranslationConstants.releaseUploadItemlistNameDesc2.tr}',
                    showLogo: AppConfig.instance.appInUse == AppInUse.g,
                  ),
                  AppTheme.heightSpace10,
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: TextFormField(
                      controller: controller.itemlistNameController,
                      onChanged:(text) => controller.setItemlistName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: '${ReleaseTranslationConstants.releaseItemlistTitle.tr} ${controller.appReleaseItem.value.type.value.tr.toLowerCase()}',
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
                      controller: controller.itemlistDescController,
                      onChanged:(text) => controller.setItemlistDesc() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: '${ReleaseTranslationConstants.releaseItemlistDesc.tr} ${controller.appReleaseItem.value.type.value.tr.toLowerCase()}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  TitleSubtitleRow("", showDivider: false, vPadding: 10, hPadding: 20,
                      subtitle: ReleaseTranslationConstants.releasePriceMsg.tr,
                      url: AppProperties.getDigitalPositioningUrl()
                  ),
                  AppTheme.heightSpace10,
                ],
              ),
             ),
          ),
           floatingActionButton: controller.validateItemlistNameDesc() ? FloatingActionButton(
             heroTag: AppHeroTagConstants.clearImg,
             tooltip: AppTranslationConstants.next,
             child: const Icon(Icons.navigate_next),
             onPressed: ()=>{
               controller.addItemlistNameDesc()
             },
           ) : const SizedBox.shrink(),
         );
      }
    );
  }

}
