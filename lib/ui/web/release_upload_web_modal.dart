import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';

import 'phases/release_form_phase.dart';
import 'phases/release_summary_phase.dart';
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

            // Next / empty
            if (phase == 1)
              TextButton(
                onPressed: ctrl.canProceedToSummary ? ctrl.goNext : null,
                child: Text(AppTranslationConstants.next.tr,
                  style: TextStyle(
                    color: ctrl.canProceedToSummary ? AppColor.getReleaseShelfColor() : Colors.grey[700],
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
        return ReleaseSummaryPhase(
          key: const ValueKey(2),
          controller: ctrl,
          onUpload: () => _handleUpload(context, ctrl),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _phaseTitle(int phase) {
    switch (phase) {
      case 0: return ReleaseTranslationConstants.newRelease.tr;
      case 1: return ReleaseTranslationConstants.information.tr;
      case 2: return ReleaseTranslationConstants.confirm.tr;
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
      uploadCtrl.buildItemsFromWebForm();

      // Execute the full upload pipeline (cover → itemlist → files → post → notifications)
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.creatingPost.tr;
      await uploadCtrl.uploadReleaseItem();
      webCtrl.uploadStatus.value = ReleaseTranslationConstants.finalizingUpload.tr;

      webCtrl.isUploading.value = false;

      if (context.mounted) {
        Navigator.of(context).pop();
        AppUtilities.showSnackBar(
          title: 'Obra subida',
          message: '${webCtrl.titleController.text.trim()} se ha subido correctamente.',
        );
      }
    } catch (e, st) {
      webCtrl.isUploading.value = false;
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'webUpload');
      AppUtilities.showSnackBar(title: 'Error', message: 'No se pudo subir la obra. Intenta de nuevo.');
    }
  }

  void _close(BuildContext context, ReleaseUploadWebController ctrl) {
    if (ctrl.isUploading.value) return; // Don't close during upload
    Navigator.of(context).pop();
    Sint.delete<ReleaseUploadWebController>();
  }
}
