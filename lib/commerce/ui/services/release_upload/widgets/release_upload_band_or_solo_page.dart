
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/band_member.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/band_member_role.dart';
import '../release_upload_controller.dart';

class ReleaseUploadBandOrSoloPage extends StatelessWidget {
  const ReleaseUploadBandOrSoloPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
        body: Container(
            decoration: AppTheme.boxDecoration,
            height: AppTheme.fullHeight(context),
            child: Column(
              children: [
              AppTheme.heightSpace30,
              HeaderIntro(subtitle: AppTranslationConstants.releaseUploadBandSelection.tr),
              AppTheme.heightSpace20,
              _.isLoading.value ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                height: AppTheme.fullHeight(context)*0.60,
                child: Obx(()=> ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  itemCount: _.bandController.bands.length,
                  itemBuilder: (context, index) {
                    Band band = _.bandController.bands.values.elementAt(index);
                    BandMember profileMember = band.members!.values.firstWhere((element) => element.profileId == _.profile.id);
                    bool canUploadItems = profileMember.role != BandMemberRole.member; ///VERIFY IF IS MORE THAN JUST A MEMBER

                    return canUploadItems ? GestureDetector(
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: CachedNetworkImage(imageUrl: band.photoUrl)
                        ),
                        title: Text(band.name.length > AppConstants.maxItemlistNameLength
                          ? "${band.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                          : band.name
                        ),
                        subtitle: Text(band.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            (CoreUtilities.getTotalItemsQty(band.itemlists ?? {}) > 0)
                              ? ActionChip(
                                backgroundColor: AppColor.main50,
                                avatar: CircleAvatar(
                                  backgroundColor: AppColor.white80,
                                  child: Text(CoreUtilities.getTotalItemsQty(band.itemlists ?? {}).toString()),
                                ),
                                label: Icon(
                                    AppFlavour.getAppItemIcon(),
                                    color: AppColor.white80),
                                onPressed: () {
                                },
                              ) : const SizedBox.shrink()
                          ]
                        ),
                      ),
                      onTap: () async {
                        _.setSelectedBand(band);
                      },
                    ) : const SizedBox.shrink();
                  },
                ),),
              ),],
            ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.35, 1],
              colors: [
                theme.scaffoldBackgroundColor.withOpacity(0),
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Container(
            color: AppColor.main50,
            padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
            child: ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(AppColor.bondiBlue75),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(vertical: 15.0)), // Adjust the padding as needed

          ),
              icon: const Icon(CupertinoIcons.music_mic),
              label: Text(AppTranslationConstants.publishAsSoloist.tr, style: const TextStyle(fontSize: 18),),
              onPressed: () => _.setAsSolo(),
            ),
          ),
        ),
      ),
    );
  }
}
