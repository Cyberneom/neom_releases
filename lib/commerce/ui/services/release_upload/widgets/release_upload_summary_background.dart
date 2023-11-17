import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import '../release_upload_controller.dart';

class OnlinePositioningSummaryBackground extends StatelessWidget {
  const OnlinePositioningSummaryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => Positioned(
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
            child: _.appReleaseItem.value.imgUrl.isNotEmpty ? CachedNetworkImage(imageUrl: _.appReleaseItem.value.imgUrl,
              width: AppTheme.fullWidth(context), height: AppTheme.fullHeight(context),
              fit: BoxFit.fitWidth,
            ) : Image.asset(AppFlavour.getAppLogoPath(),
              width: AppTheme.fullWidth(context), height: AppTheme.fullHeight(context),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      )
    );
  }
}
