// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neom_books/ui/pdf_viewer/pdf_web_viewer_stub.dart'
    if (dart.library.html) 'package:neom_books/ui/pdf_viewer/pdf_web_viewer_impl.dart';
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
    final isPdf = ctrl.isEmxi && ctrl.isSingle;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Cover preview — tappable for PDF, with animated glow
              GestureDetector(
                onTap: isPdf ? () => _openPdfPreview(ctrl) : null,
                child: MouseRegion(
                  cursor: isPdf ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final glowOpacity = 0.15 + (_pulseController.value * 0.15);
                      return Obx(() => Container(
                        width: ctrl.isEmxi ? 260 : 280,
                        height: ctrl.isEmxi ? 380 : 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withAlpha(8),
                          border: Border.all(
                            color: AppColor.bondiBlue.withAlpha((glowOpacity * 255).toInt()),
                            width: 1.5,
                          ),
                          image: ctrl.coverBytes.value != null
                              ? DecorationImage(
                                  image: MemoryImage(ctrl.coverBytes.value!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withAlpha((10 + (_pulseController.value * 15)).toInt()),
                                    BlendMode.lighten,
                                  ),
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.bondiBlue.withAlpha((glowOpacity * 255).toInt()),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.white.withAlpha((glowOpacity * 40).toInt()),
                              blurRadius: 60,
                              spreadRadius: -5,
                            ),
                            BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ctrl.coverBytes.value == null
                            ? Icon(ctrl.isEmxi ? Icons.menu_book : Icons.album, color: Colors.white24, size: 48)
                            : null,
                      ));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Animated "Tap cover to preview" text for PDFs
              if (isPdf)
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, color: AppColor.bondiBlue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        ReleaseTranslationConstants.tapCoverToPreviewRelease.tr,
                        style: TextStyle(color: AppColor.bondiBlue, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              if (isPdf) const SizedBox(height: 14),

              // Title
              Text(
                ctrl.titleController.text.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                ctrl.authorController.text.trim(),
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),

              // Genre chips
              Obx(() {
                final categories = <String>[];
                categories.addAll(ctrl.selectedInstruments);
                categories.addAll(ctrl.selectedGenres);
                if (categories.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
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
                );
              }),
              const SizedBox(height: 36),

              // Upload button / progress
              Obx(() => ctrl.isUploading.value
                  ? _buildUploadProgress(ctrl, shelfColor)
                  : SizedBox(
                      width: 280,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: shelfColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: widget.onUpload,
                        child: Text(
                          ReleaseTranslationConstants.publishOnPlatform.tr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
              ),
            ],
          ),
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
