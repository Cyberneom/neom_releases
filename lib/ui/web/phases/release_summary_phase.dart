// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neom_books/ui/pdf_viewer/pdf_web_viewer_stub.dart'
    if (dart.library.html) 'package:neom_books/ui/pdf_viewer/pdf_web_viewer_impl.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase 3: Summary with preview + upload button.
class ReleaseSummaryPhase extends StatefulWidget {
  final ReleaseUploadWebController controller;
  final VoidCallback onUpload;

  const ReleaseSummaryPhase({
    super.key,
    required this.controller,
    required this.onUpload,
  });

  @override
  State<ReleaseSummaryPhase> createState() => _ReleaseSummaryPhaseState();
}

class _ReleaseSummaryPhaseState extends State<ReleaseSummaryPhase>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final shelfColor = AppColor.getReleaseShelfColor();
    final isPdf = ctrl.singleAcceptsPdf;

    final categories = <String>[...ctrl.selectedInstruments, ...ctrl.selectedGenres];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Cover (tappable for preview) ──
            GestureDetector(
              onTap: isPdf ? () => _openPdfPreview(ctrl) : null,
              child: MouseRegion(
                cursor: isPdf ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Obx(() {
                  final hasImage = ctrl.coverBytes.value != null;
                  return SizedBox(
                    width: AppFlavour.useVerticalCover() ? 240 : 260,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black38, blurRadius: 20, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: hasImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(ctrl.coverBytes.value!, fit: BoxFit.contain),
                                  )
                              : Container(
                                  width: 220, height: 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(AppFlavour.getSingleIcon(), color: Colors.white24, size: 48),
                                ),
                          ),
                        ),
                        if (isPdf) ...[
                          const SizedBox(height: 10),
                          FadeTransition(
                            opacity: _pulseAnimation,
                            child: Text(
                              '👆 ${ReleaseTranslationConstants.tapCoverToPreviewRelease.tr}',
                              style: TextStyle(color: AppColor.bondiBlue, fontSize: 10, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 28),

            // ── Right: Info + actions ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    ctrl.titleController.text.trim(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ctrl.authorController.text.trim(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                  const SizedBox(height: 14),

                  // Genre chips
                  if (categories.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: categories.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Text(g, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      )).toList(),
                    ),

                  // Description
                  if (ctrl.descController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      ctrl.descController.text.trim(),
                      style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // File info
                  if (ctrl.releaseFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final f in ctrl.releaseFiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(isPdf ? Icons.picture_as_pdf : Icons.audiotrack,
                                color: Colors.white30, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f.name,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('${(f.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 28),

                  // Publish button / progress
                  Obx(() => ctrl.isUploading.value
                      ? _buildUploadProgress(ctrl, shelfColor)
                      : SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shelfColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            icon: const Icon(Icons.publish, size: 16),
                            label: Text(
                              ReleaseTranslationConstants.publishOnPlatform.tr,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            onPressed: widget.onUpload,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(ReleaseUploadWebController ctrl, Color shelfColor) {
    return Column(
      children: [
        SizedBox(
          width: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: Colors.white.withAlpha(10),
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.bondiBlue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Text(
          ctrl.uploadStatus.value.isNotEmpty
              ? ctrl.uploadStatus.value
              : ReleaseTranslationConstants.uploadingFile.tr,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        )),
      ],
    );
  }

  /// Opens the PDF in a dialog using the custom pdf_reader.html viewer.
  void _openPdfPreview(ReleaseUploadWebController ctrl) {
    if (ctrl.releaseFiles.isEmpty) return;
    final file = ctrl.releaseFiles.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    // Create blob URL from raw bytes
    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _PdfPreviewDialog(url: blobUrl, fileName: file.name),
    );
  }
}

/// Full-screen PDF preview dialog using the custom pdf_reader.html viewer.
class _PdfPreviewDialog extends StatelessWidget {
  final String url;
  final String fileName;

  const _PdfPreviewDialog({required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColor.surfaceElevated,
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // PDF viewer
              Expanded(
                child: buildPdfWebViewer(
                  url,
                  viewType: 'pdf-preview-${url.hashCode}',
                  bookId: 'preview',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
