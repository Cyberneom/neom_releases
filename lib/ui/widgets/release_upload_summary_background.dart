import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import '../release_upload_controller.dart';

class OnlinePositioningSummaryBackground extends StatelessWidget {

  const OnlinePositioningSummaryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) => Positioned(
        top: -50,
        bottom: 0,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 700),
          tween: Tween<double>(begin: 0.25,end: 1),
          builder: (_, double value, child){
            return Transform.scale(scale: value, child: child,);
          },
          child: Container(
            width: AppTheme.fullWidth(context),
            height: AppTheme.fullHeight(context),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.black.withOpacity(0.4),
            child: controller.appReleaseItem.value.imgUrl.isNotEmpty ? CachedNetworkImage(imageUrl: controller.appReleaseItem.value.imgUrl,
              width: AppTheme.fullWidth(context), height: AppTheme.fullHeight(context),
              fit: BoxFit.fitWidth,
            ) : Image.asset(AppConfig.instance.appInUse == AppInUse.g ? AppFlavour.getAppLogoPath() : AppFlavour.getAppPreLogoPath(),
              width: AppTheme.fullWidth(context), height: AppTheme.fullHeight(context),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      )
    );
  }
}
