import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

import 'phases/release_form_phase.dart';
import 'phases/release_summary_phase.dart';
import 'phases/release_tracks_phase.dart';
import 'phases/release_type_phase.dart';
import 'release_upload_web_controller.dart';

/// eMastered-style modal for uploading releases on web.
class ReleaseUploadWebModal extends StatelessWidget {
  const ReleaseUploadWebModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (_) => const ReleaseUploadWebModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Sint.put(ReleaseUploadWebController());
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _close(context, ctrl);
        }
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.65,
            height: MediaQuery.of(context).size.height * 0.82,
            constraints: const BoxConstraints(minWidth: 800, maxWidth: 1100, minHeight: 550, maxHeight: 850),
            decoration: BoxDecoration(
              color: AppColor.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(10)),
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius: 40, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(context, ctrl),
                const Divider(height: 1, color: Colors.white10),
                // Body
                Expanded(
                  child: Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildPhase(context, ctrl),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReleaseUploadWebController ctrl) {
    return Obx(() {
      final phase = ctrl.phase.value;
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Back / Close
            if (phase > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                onPressed: ctrl.goBack,
              )
            else
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => _close(context, ctrl),
              ),

            const Spacer(),

            // Title
            Text(
              _phaseTitle(phase),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const Spacer(),

            // Next button — visible in form (1) and tracks (2) phases
            if (phase == 1 || (phase == 2 && ctrl.isAlbum))
              TextButton(
                onPressed: (phase == 1 && ctrl.canProceedToSummary) || (phase == 2 && ctrl.isAlbum)
                    ? ctrl.goNext
                    : null,
                child: Text(AppTranslationConstants.next.tr,
                  style: TextStyle(
                    color: (phase == 1 && ctrl.canProceedToSummary) || (phase == 2 && ctrl.isAlbum)
                        ? AppColor.white80
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      );
    });
  }

  Widget _buildPhase(BuildContext context, ReleaseUploadWebController ctrl) {
    switch (ctrl.phase.value) {
      case 0:
        return ReleaseTypePhase(key: const ValueKey(0), controller: ctrl);
      case 1:
        return ReleaseFormPhase(key: const ValueKey(1), controller: ctrl);
      case 2:
        // For albums: track naming + cover. For singles: skip to summary.
        if (ctrl.isAlbum) {
          return ReleaseTracksPhase(key: const ValueKey(2), controller: ctrl);
        }
        return ReleaseSummaryPhase(
          key: const ValueKey(2),
          controller: ctrl,
          onUpload: () => _handleUpload(context, ctrl),
        );
      case 3:
        // For albums: summary. For singles: success.
        if (ctrl.isAlbum) {
          return ReleaseSummaryPhase(
            key: const ValueKey(3),
            controller: ctrl,
            onUpload: () => _handleUpload(context, ctrl),
          );
        }
        return _buildSuccessPhase(context, ctrl);
      case 4:
        // Album success
        return _buildSuccessPhase(context, ctrl);
      default:
        return const SizedBox.shrink();
    }
  }

  String _phaseTitle(int phase) {
    final ctrl = Sint.find<ReleaseUploadWebController>();
    switch (phase) {
      case 0: return ReleaseTranslationConstants.newRelease.tr;
      case 1: return ReleaseTranslationConstants.information.tr;
      case 2: return ctrl.isAlbum
          ? ReleaseTranslationConstants.tracks.tr
          : ReleaseTranslationConstants.confirm.tr;
      case 3: return ctrl.isAlbum
          ? ReleaseTranslationConstants.confirm.tr
          : '';
      case 4: return '';
      default: return '';
    }
  }

  /// Delegates to ReleaseUploadController which handles all:
  /// cover upload, itemlist creation, file uploads, WooCommerce products,
  /// post creation, push notifications, activity feed, and approval requests.
  Future<void> _handleUpload(BuildContext context, ReleaseUploadWebController webCtrl) async {
    if (webCtrl.isUploading.value) return;
    webCtrl.isUploading.value = true;

    try {
      // Get or create the real ReleaseUploadController
      final uploadCtrl = Sint.isRegistered<ReleaseUploadController>()
          ? Sint.find<ReleaseUploadController>()
          : Sint.put(ReleaseUploadController());

      // Set release type
      uploadCtrl.setReleaseType(webCtrl.releaseType.value);

      // Set form fields
      uploadCtrl.titleController.text = webCtrl.titleController.text.trim();
      uploadCtrl.authorController.text = webCtrl.authorController.text.trim();
      uploadCtrl.descController.text = webCtrl.descController.text.trim();

      // Set genres (instruments + subgenres)
      final categories = <String>[];
      categories.addAll(webCtrl.selectedInstruments);
      categories.addAll(webCtrl.selectedGenres);
      if (categories.isNotEmpty) {
        uploadCtrl.selectedGenres.assignAll(categories);
      }

      // Set cover image bytes
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.uploadingCover.tr;
      if (webCtrl.coverBytes.value != null) {
        uploadCtrl.releaseCoverImgBytes = webCtrl.coverBytes.value;
      }

      // Set release files (web bytes)
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.uploadingFile.tr;
      for (final file in webCtrl.releaseFiles) {
        if (file.bytes != null) {
          uploadCtrl.addWebFileBytes(file.name, file.bytes!);
        }
      }

      // Build items from form data
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.creatingCatalog.tr;
      uploadCtrl.isWebMode = true; // Prevent internal navigation
      uploadCtrl.buildItemsFromWebForm();

      // Execute the full upload pipeline (cover → itemlist → files → post → notifications)
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.creatingPost.tr;
      await uploadCtrl.uploadReleaseItem();
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.finalizingUpload.tr;

      webCtrl.isUploading.value = false;

      if (context.mounted) {
        // Show success phase in the same modal
        webCtrl.phase.value = webCtrl.isAlbum ? 4 : 3; // Success phase
      }
    } catch (e, st) {
      webCtrl.isUploading.value = false;
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'webUpload');
      AppUtilities.showSnackBar(title: AppTranslationConstants.error.tr, message: ReleaseTranslationConstants.uploadFailedRetry.tr);
    }
  }

  Widget _buildSuccessPhase(BuildContext context, ReleaseUploadWebController ctrl) {
    final shelfColor = AppColor.getReleaseShelfColor();
    final title = ctrl.titleController.text.trim();
    // Build slug from title for sharing
    final slug = title.toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    final shareUrl = '${AppProperties.getAppName().toLowerCase()}.xyz/$slug';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: shelfColor, size: 80),
            const SizedBox(height: 24),
            Text(
              ReleaseTranslationConstants.publishSuccess.tr,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$title ${ReleaseTranslationConstants.publishedSuccessfully.tr}',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // ── Copy URL to share ──
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: shelfColor.withAlpha(100)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.link, size: 18),
                label: Text(ReleaseTranslationConstants.copyUrlToShare.tr),
                onPressed: () {
                  // Copy URL to clipboard
                  Clipboard.setData(ClipboardData(text: shareUrl));
                  AppUtilities.showSnackBar(
                    title: ReleaseTranslationConstants.urlCopied.tr,
                    message: shareUrl,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── Share release post (cover image + link + push notification) ──
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Obx(() {
                final isSharing = ctrl.isUploading.value;
                final alreadyShared = ctrl.hasSharedPost.value;
                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: alreadyShared ? Colors.white38 : Colors.white70,
                    side: BorderSide(color: alreadyShared ? Colors.white12 : shelfColor.withAlpha(100)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSharing
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: shelfColor))
                      : Icon(alreadyShared ? Icons.check : Icons.share, size: 18),
                  label: Text(isSharing
                      ? ReleaseTranslationConstants.creatingPost.tr
                      : alreadyShared
                          ? '✓ ${ReleaseTranslationConstants.publishSuccess.tr}'
                          : ReleaseTranslationConstants.shareOnTimeline.tr),
                  onPressed: (isSharing || alreadyShared) ? null : () async {
                    final uploadCtrl = Sint.isRegistered<ReleaseUploadController>()
                        ? Sint.find<ReleaseUploadController>()
                        : null;
                    if (uploadCtrl != null) {
                      ctrl.isUploading.value = true;
                      try {
                        await uploadCtrl.createReleasePost();
                        ctrl.isUploading.value = false;
                        ctrl.hasSharedPost.value = true;
                        if (context.mounted) {
                          AppUtilities.showSnackBar(
                            title: ReleaseTranslationConstants.publishSuccess.tr,
                            message: ReleaseTranslationConstants.shareOnTimeline.tr,
                          );
                        }
                      } catch (_) {
                        ctrl.isUploading.value = false;
                      }
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 10),

            // ── Continue to home ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: shelfColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: Text(AppTranslationConstants.continueExploring.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Go home to see new release
                  Sint.offAllNamed(AppRouteConstants.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close(BuildContext context, ReleaseUploadWebController ctrl) {
    if (ctrl.isUploading.value) return; // Don't close during upload
    Navigator.of(context).pop();
    Sint.delete<ReleaseUploadWebController>();
  }
}
