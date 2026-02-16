import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/buttons/summary_button.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/ui/widgets/title_subtitle_row.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import '../utils/constants/release_translation_constants.dart';
import 'release_upload_controller.dart';

class ReleaseUploadPage extends StatelessWidget {
  const ReleaseUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      init: ReleaseUploadController(),
      builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          backgroundColor: AppColor.main50,
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: AppTheme.appBoxDecoration,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTheme.heightSpace30,
                    HeaderIntro(subtitle: ReleaseTranslationConstants.releaseUpload.tr, showPreLogo: true),
                    AppTheme.heightSpace10,
                    // Show different content based on pending draft
                    Obx(() {
                      if (controller.hasPendingDraft.value) {
                        // Show only draft card and start new button when there's a pending draft
                        return Column(
                          children: [
                            _buildPendingDraftCard(context, controller),
                            _buildStartNewButton(controller),
                          ],
                        );
                      } else {
                        // Show full intro content when no pending draft
                        return Column(
                          children: [
                            if(AppConfig.instance.appInUse != AppInUse.e)
                              Column(
                                children: [
                                  TitleSubtitleRow(ReleaseTranslationConstants.digitalPositioning.tr,
                                    subtitle: ReleaseTranslationConstants.releaseUploadIntro.tr,
                                    showDivider: false,
                                  ),
                                  AppTheme.heightSpace10,
                                ],
                              ),
                            AppFlavour.getSalesModelInfoWidget(context),
                            SummaryButton(
                              AppTranslationConstants.toStart.tr,
                              onPressed: () => controller.startNewRelease(),
                            ),
                          ],
                        );
                      }
                    }),
                    AppTheme.heightSpace30,
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  /// Build the card showing pending draft info with resume option
  Widget _buildPendingDraftCard(BuildContext context, ReleaseUploadController controller) {
    final draft = controller.cacheController.currentDraft.value;
    if (draft == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ReleaseTranslationConstants.pendingDraftFound.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Draft details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.itemlist?.name != null && draft.itemlist!.name.isNotEmpty)
                  _buildDraftInfoRow(
                    Icons.menu_book_rounded,
                    AppTranslationConstants.title.tr,
                    draft.itemlist!.name,
                  ),
                if (draft.releaseType != null)
                  _buildDraftInfoRow(
                    Icons.category_rounded,
                    AppTranslationConstants.type.tr,
                    draft.releaseType!.name.tr.toUpperCase(),
                  ),
                _buildDraftInfoRow(
                  Icons.timelapse_rounded,
                  ReleaseTranslationConstants.draftProgress.tr,
                  draft.progressDescription,
                ),
                _buildDraftInfoRow(
                  Icons.schedule_rounded,
                  AppTranslationConstants.date.tr,
                  _formatDate(draft.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resume button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.resumeFromDraft(),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              label: Text(
                ReleaseTranslationConstants.continueWithPrevious.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.bondiBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row for draft details
  Widget _buildDraftInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the "Start New" button when there's a pending draft
  Widget _buildStartNewButton(ReleaseUploadController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          // Confirm before discarding draft
          await controller.discardDraft();
          controller.startNewRelease();
        },
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 20),
        label: Text(
          ReleaseTranslationConstants.startNewPositioning.tr,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.white.withAlpha(60), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return 'Hace ${diff.inDays} días';
    }
  }

}
