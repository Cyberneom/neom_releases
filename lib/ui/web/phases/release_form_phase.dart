import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase 2: Form fields (left) + drag & drop file zone (right).
class ReleaseFormPhase extends StatefulWidget {
  final ReleaseUploadWebController controller;

  const ReleaseFormPhase({super.key, required this.controller});

  @override
  State<ReleaseFormPhase> createState() => _ReleaseFormPhaseState();
}

class _ReleaseFormPhaseState extends State<ReleaseFormPhase> {
  bool _isFileDragOver = false;
  bool _isCoverDragOver = false;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _setupHtmlDrop();
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  // ── HTML5 native drag & drop ──

  void _setupHtmlDrop() {
    final body = html.document.body!;
    _subs.add(body.onDragOver.listen((e) {
      e.preventDefault();
    }));
    _subs.add(body.onDrop.listen((e) {
      e.preventDefault();
      if (!mounted) return;
      setState(() {
        _isFileDragOver = false;
        _isCoverDragOver = false;
      });
    }));
  }

  /// Set up drop events for the file zone (MP3/PDF).
  void _setupFileDropZone(html.Element element) {
    element.onDragOver.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      if (mounted) setState(() => _isFileDragOver = true);
    });
    element.onDragLeave.listen((e) {
      e.stopPropagation();
      if (mounted) setState(() => _isFileDragOver = false);
    });
    element.onDrop.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      if (mounted) setState(() => _isFileDragOver = false);
      final files = e.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        _handleDroppedFiles(files);
      }
    });
  }

  /// Set up drop events for the cover zone (images).
  void _setupCoverDropZone(html.Element element) {
    element.onDragOver.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      if (mounted) setState(() => _isCoverDragOver = true);
    });
    element.onDragLeave.listen((e) {
      e.stopPropagation();
      if (mounted) setState(() => _isCoverDragOver = false);
    });
    element.onDrop.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      if (mounted) setState(() => _isCoverDragOver = false);
      final files = e.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        _handleDroppedCover(files.first);
      }
    });
  }

  void _handleDroppedFiles(List<html.File> htmlFiles) {
    final ctrl = widget.controller;
    final allowed = ctrl.acceptedExtensions;

    for (final file in htmlFiles) {
      final ext = file.name.split('.').last.toLowerCase();
      if (!allowed.contains(ext)) continue;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        if (reader.result == null || !mounted) return;
        final bytes = Uint8List.fromList(reader.result as List<int>);
        ctrl.addFileFromRawBytes(file.name, bytes);
      });
    }
  }

  void _handleDroppedCover(html.File file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      if (reader.result == null || !mounted) return;
      final bytes = Uint8List.fromList(reader.result as List<int>);
      widget.controller.coverBytes.value = bytes;
      widget.controller.coverFileName.value = file.name;
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Form fields + file drop zone (for single/book) ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _requiredLabel(ReleaseTranslationConstants.releaseTitle.tr),
                const SizedBox(height: 6),
                _textField(ctrl.titleController, ReleaseTranslationConstants.releaseTitle.tr),
                const SizedBox(height: 16),

                // Author / Artist
                _requiredLabel(ReleaseTranslationConstants.releaseAuthor.tr),
                const SizedBox(height: 6),
                _textField(ctrl.authorController, ReleaseTranslationConstants.releaseAuthor.tr),
                const SizedBox(height: 16),

                if (ctrl.isArtwork) ...[
                  // Art Category
                  _label(ReleaseTranslationConstants.artCategory.tr),
                  const SizedBox(height: 6),
                  _textField(ctrl.artCategoryController, 'Pintura, Escultura, Fotografía, Grabado, Arte Digital...'),
                  const SizedBox(height: 16),

                  // Technique & Medium in a Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(ReleaseTranslationConstants.artTechnique.tr),
                            const SizedBox(height: 6),
                            _textField(ctrl.artTechniqueController, 'Óleo, Acrílico, Temple, Acuarela...'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(ReleaseTranslationConstants.artMedium.tr),
                            const SizedBox(height: 6),
                            _textField(ctrl.artMediumController, 'Lienzo, Madera, Papel, Bronce...'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dimensions
                  _label(ReleaseTranslationConstants.artDimensions.tr),
                  const SizedBox(height: 6),
                  _textField(ctrl.artDimensionsController, '120 × 90 cm'),
                  const SizedBox(height: 16),
                ] else ...[
                  // Instrument / Category (single select) — required
                  _requiredLabel(ReleaseTranslationConstants.genre.tr),
                  const SizedBox(height: 6),
                  Obx(() => _instrumentSelector(ctrl)),
                  const SizedBox(height: 20),

                  // Subgenres (multi-select, up to 10) — optional
                  _label(ReleaseTranslationConstants.subgenres.tr),
                  const SizedBox(height: 6),
                  Obx(() => _subgenreSelector(ctrl)),
                  const SizedBox(height: 20),
                ],

                // Description — required
                _requiredLabel(ReleaseTranslationConstants.releaseDesc.tr),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl.descController,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(ReleaseTranslationConstants.releaseDesc.tr),
                ),
                const SizedBox(height: 16),

                // Artwork authenticity attributes
                if (ctrl.isArtwork) ...[
                  Obx(() => _artworkAuthenticityToggles(ctrl)),
                  const SizedBox(height: 16),
                ],

                // Physical Sale / Dropshipping
                Obx(() => _buildPhysicalSaleSection(ctrl)),
                const SizedBox(height: 16),

                // File drop zone inline (for single/book)
                if (ctrl.isSingle) ...[
                  _label(ReleaseTranslationConstants.file.tr),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: _buildFileDropZone(ctrl),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider
        VerticalDivider(width: 1, color: Colors.white.withAlpha(15)),

        // ── Right: Publisher info + Cover (for single/book/artwork) or Tracks drop zone (for album) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: (ctrl.isSingle || ctrl.isArtwork)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Self-published checkbox + Year dropdown
                      Obx(() => _publisherSection(ctrl)),
                      const SizedBox(height: 16),
                      // Cover / Artwork Image
                      _label(ctrl.isArtwork
                          ? ReleaseTranslationConstants.uploadArtworkImage.tr
                          : ReleaseTranslationConstants.releaseCover.tr),
                      const SizedBox(height: 8),
                      Expanded(child: Obx(() => _coverPickerExpanded(ctrl))),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ReleaseTranslationConstants.tracks.tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildFileDropZone(ctrl)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _artworkAuthenticityToggles(ReleaseUploadWebController ctrl) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        FilterChip(
          label: Text(ReleaseTranslationConstants.artIsOriginal.tr, style: const TextStyle(fontSize: 12)),
          selected: ctrl.artIsOriginal.value,
          onSelected: (v) => ctrl.artIsOriginal.value = v,
          selectedColor: AppColor.bondiBlue.withAlpha(50),
          checkmarkColor: AppColor.bondiBlue,
          side: BorderSide(color: ctrl.artIsOriginal.value ? AppColor.bondiBlue : Colors.white24),
        ),
        FilterChip(
          label: Text(ReleaseTranslationConstants.artIsSigned.tr, style: const TextStyle(fontSize: 12)),
          selected: ctrl.artIsSigned.value,
          onSelected: (v) => ctrl.artIsSigned.value = v,
          selectedColor: AppColor.bondiBlue.withAlpha(50),
          checkmarkColor: AppColor.bondiBlue,
          side: BorderSide(color: ctrl.artIsSigned.value ? AppColor.bondiBlue : Colors.white24),
        ),
        FilterChip(
          label: Text(ReleaseTranslationConstants.artIsFramed.tr, style: const TextStyle(fontSize: 12)),
          selected: ctrl.artIsFramed.value,
          onSelected: (v) => ctrl.artIsFramed.value = v,
          selectedColor: AppColor.bondiBlue.withAlpha(50),
          checkmarkColor: AppColor.bondiBlue,
          side: BorderSide(color: ctrl.artIsFramed.value ? AppColor.bondiBlue : Colors.white24),
        ),
      ],
    );
  }

  Widget _buildPhysicalSaleSection(ReleaseUploadWebController ctrl) {
    final title = ctrl.isArtwork
        ? ReleaseTranslationConstants.artworkSaleTitle.tr
        : AppFlavour.getPhysicalSaleTitleKey().tr;
    final desc = ctrl.isArtwork
        ? ReleaseTranslationConstants.artworkSaleDescMsg.tr
        : AppFlavour.getPhysicalSaleDescKey().tr;
    final priceLabel = ctrl.isArtwork
        ? ReleaseTranslationConstants.artworkSalePrice.tr
        : ReleaseTranslationConstants.physicalReleasePrice.tr;
    final hint = ctrl.isArtwork ? 'ej. 15000.00' : 'ej. 350.00';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ctrl.isPhysical.value
              ? AppColor.bondiBlue.withAlpha(120)
              : Colors.white.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ctrl.isArtwork
                    ? Icons.palette_outlined
                    : (AppFlavour.singleAcceptsPdf()
                        ? Icons.menu_book_outlined
                        : Icons.album_outlined),
                color: ctrl.isPhysical.value ? AppColor.bondiBlue : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Switch(
                value: ctrl.isPhysical.value,
                onChanged: (val) => ctrl.isPhysical.value = val,
                activeThumbColor: AppColor.bondiBlue,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.35),
          ),
          if (ctrl.isPhysical.value) ...[
            const SizedBox(height: 12),
            TextField(
              controller: ctrl.physicalPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: priceLabel,
                hintText: hint,
                prefixText: '\$ ',
                suffixText: 'MXN',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                suffixStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.bondiBlue.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.bondiBlue),
                ),
              ),
            ),
            if (ctrl.isArtwork) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: ctrl.artIncludesShipping.value ? AppColor.bondiBlue : Colors.white60,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ReleaseTranslationConstants.includesShipping.tr,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            ReleaseTranslationConstants.includesShippingDesc.tr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ctrl.artIncludesShipping.value,
                      onChanged: (val) => ctrl.artIncludesShipping.value = val,
                      activeThumbColor: AppColor.bondiBlue,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── File drop zone (PDF / MP3) with real HTML5 drag & drop ──

  Widget _buildFileDropZone(ReleaseUploadWebController ctrl) {
    return Obx(() {
      final files = ctrl.releaseFiles;

      if (files.isNotEmpty) {
        return Column(
          children: [
            // File list
            Expanded(
              child: ListView.separated(
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final f = files[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ctrl.singleAcceptsPdf ? Icons.picture_as_pdf : Icons.music_note,
                          color: AppColor.bondiBlue, size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                              if (f.size > 0)
                                Text('${(f.size / 1024 / 1024).toStringAsFixed(1)} MB',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => ctrl.removeFile(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (ctrl.isAlbum) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(ReleaseTranslationConstants.addMore.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: ctrl.pickReleaseFiles,
              ),
            ],
          ],
        );
      }

      // Empty drop zone — with real HTML5 drag & drop
      return _HtmlDropTarget(
        onSetup: _setupFileDropZone,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: ctrl.pickReleaseFiles,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isFileDragOver ? AppColor.bondiBlue.withAlpha(15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isFileDragOver ? AppColor.bondiBlue : Colors.white24,
                  width: _isFileDragOver ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                      size: 48, color: _isFileDragOver ? AppColor.bondiBlue : Colors.white38),
                    const SizedBox(height: 16),
                    Text(
                      _isFileDragOver ? ReleaseTranslationConstants.dropHere.tr : ReleaseTranslationConstants.dragAndDropHere.tr,
                      style: TextStyle(
                        color: _isFileDragOver ? Colors.white : Colors.white70,
                        fontSize: 16, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ReleaseTranslationConstants.orClickToBrowse.tr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ctrl.acceptedFileType,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Cover drop zone with real HTML5 drag & drop ──

  Widget _coverPickerExpanded(ReleaseUploadWebController ctrl) {
    if (ctrl.coverBytes.value != null) {
      // Cover selected — show preview with change/remove
      return Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.bondiBlue.withAlpha(60)),
              image: DecorationImage(
                image: MemoryImage(ctrl.coverBytes.value!),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Row(
              children: [
                _actionChip(Icons.delete_outline, Colors.redAccent, () {
                  ctrl.coverBytes.value = null;
                  ctrl.coverFileName.value = '';
                }),
                const SizedBox(width: 8),
                _actionChip(Icons.swap_horiz, Colors.white70, ctrl.pickCoverImage),
              ],
            ),
          ),
        ],
      );
    }

    // Empty cover zone — with real HTML5 drag & drop
    return _HtmlDropTarget(
      onSetup: _setupCoverDropZone,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: ctrl.pickCoverImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isCoverDragOver ? AppColor.bondiBlue.withAlpha(15) : Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCoverDragOver ? AppColor.bondiBlue : AppColor.bondiBlue.withAlpha(60),
                width: _isCoverDragOver ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                  color: _isCoverDragOver ? AppColor.bondiBlue : Colors.grey[500], size: 48),
                const SizedBox(height: 8),
                Text(
                  _isCoverDragOver ? ReleaseTranslationConstants.dropImage.tr : ReleaseTranslationConstants.dragImageOrClick.tr,
                  style: TextStyle(color: _isCoverDragOver ? Colors.white : Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(ReleaseTranslationConstants.supportedFormats.tr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ── Publisher section ──

  Widget _publisherSection(ReleaseUploadWebController ctrl) {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 1960 + 1, (i) => currentYear - i);

    final isArtwork = ctrl.isArtwork;
    final checkboxLabel = isArtwork
        ? ReleaseTranslationConstants.artIsOriginal.tr
        : ReleaseTranslationConstants.selfPublished.tr;
    final yearLabel = isArtwork
        ? ReleaseTranslationConstants.artCreationYear.tr
        : ReleaseTranslationConstants.publishedYear.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: checkbox + year dropdown
        Row(
          children: [
            // Checkbox: Obra Original (Artwork) or Autopublicación (Single/Album)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (isArtwork) {
                    ctrl.artIsOriginal.value = !ctrl.artIsOriginal.value;
                  } else {
                    ctrl.isSelfPublished.value = !ctrl.isSelfPublished.value;
                    if (ctrl.isSelfPublished.value) {
                      ctrl.publisherController.clear();
                    }
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: Checkbox(
                        value: isArtwork ? ctrl.artIsOriginal.value : ctrl.isSelfPublished.value,
                        onChanged: (v) {
                          if (isArtwork) {
                            ctrl.artIsOriginal.value = v ?? true;
                          } else {
                            ctrl.isSelfPublished.value = v ?? true;
                            if (ctrl.isSelfPublished.value) {
                              ctrl.publisherController.clear();
                            }
                          }
                        },
                        activeColor: AppColor.bondiBlue,
                        side: BorderSide(color: Colors.grey[600]!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        checkboxLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Year dropdown
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<int>(
                value: ctrl.publishedYear.value,
                dropdownColor: AppColor.surfaceElevated,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: yearLabel,
                  labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                ),
                menuMaxHeight: 200,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => ctrl.publishedYear.value = v ?? currentYear,
              ),
            ),
          ],
        ),
        // Publisher name field (hidden when self-published or when isArtwork)
        if (!isArtwork && !ctrl.isSelfPublished.value) ...[
          const SizedBox(height: 12),
          TextField(
            controller: ctrl.publisherController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: ReleaseTranslationConstants.searchPublisher.tr,
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              filled: true,
              fillColor: Colors.white.withAlpha(8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColor.bondiBlue.withAlpha(100)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ──
  Widget _label(String text) => Text(text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14));

  Widget _requiredLabel(String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      const Text(' *', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
    ],
  );

  Widget _textField(TextEditingController controller, String hint) => TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: _inputDecoration(hint),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    filled: true,
    fillColor: Colors.white.withAlpha(8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withAlpha(15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withAlpha(15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColor.bondiBlue.withAlpha(100)),
    ),
  );

  /// Multi-select chip selector for genres/instruments (up to 3).
  Widget _instrumentSelector(ReleaseUploadWebController ctrl) {
    final allItems = ctrl.instrumentNames;
    final selected = ctrl.selectedInstruments;

    if (allItems.isEmpty) {
      return const SizedBox(height: 48, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    final available = allItems.where((g) => !selected.contains(g)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((g) => Chip(
              label: Text(g, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppColor.bondiBlue.withAlpha(40),
              side: BorderSide(color: AppColor.bondiBlue.withAlpha(80)),
              deleteIconColor: Colors.white54,
              onDeleted: () => ctrl.toggleInstrument(g),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        if (selected.isNotEmpty) const SizedBox(height: 8),
        if (selected.length < 3)
          DropdownButtonFormField<String>(
            key: ValueKey('instrument_${selected.length}'),
            value: null,
            dropdownColor: AppColor.surfaceElevated,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              selected.isEmpty
                  ? ReleaseTranslationConstants.selectGenre.tr
                  : '${ReleaseTranslationConstants.selectGenre.tr} (${selected.length}/3)',
            ),
            menuMaxHeight: 300,
            items: available.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) {
              if (v != null) ctrl.toggleInstrument(v);
            },
          ),
      ],
    );
  }

  /// Multi-select chip selector for subgenres (up to 5).
  Widget _subgenreSelector(ReleaseUploadWebController ctrl) {
    final allGenres = ctrl.genreNames;
    final selected = ctrl.selectedGenres;

    if (allGenres.isEmpty) {
      return const SizedBox(height: 48, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    final available = allGenres.where((g) => !selected.contains(g)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((g) => Chip(
              label: Text(g, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppColor.bondiBlue.withAlpha(40),
              side: BorderSide(color: AppColor.bondiBlue.withAlpha(80)),
              deleteIconColor: Colors.white54,
              onDeleted: () => ctrl.toggleGenre(g),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        if (selected.isNotEmpty) const SizedBox(height: 8),
        if (selected.length < 5)
          DropdownButtonFormField<String>(
            key: ValueKey('subgenre_${selected.length}'),
            value: null,
            dropdownColor: AppColor.surfaceElevated,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              selected.isEmpty
                  ? ReleaseTranslationConstants.selectSubgenres.tr
                  : '${ReleaseTranslationConstants.addSubgenre.tr} (${selected.length}/5)',
            ),
            menuMaxHeight: 250,
            items: available.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) {
              if (v != null) ctrl.toggleGenre(v);
            },
          ),
      ],
    );
  }
}

/// Helper widget that exposes the underlying HTML element for native drop setup.
///
/// After the first frame, it finds the HTML element via a [GlobalKey] overlay
/// and calls [onSetup] so the parent can attach `onDragOver`/`onDrop` listeners.
///
/// This approach avoids directly depending on Flutter internals — we register
/// a transparent overlay `<div>` on top of the Flutter widget's bounding box.
class _HtmlDropTarget extends StatefulWidget {
  final Widget child;
  final void Function(html.Element element) onSetup;

  const _HtmlDropTarget({required this.child, required this.onSetup});

  @override
  State<_HtmlDropTarget> createState() => _HtmlDropTargetState();
}

class _HtmlDropTargetState extends State<_HtmlDropTarget> {
  html.DivElement? _overlay;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createOverlay());
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  void _createOverlay() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.left = '${offset.dx}px'
      ..style.top = '${offset.dy}px'
      ..style.width = '${size.width}px'
      ..style.height = '${size.height}px'
      ..style.zIndex = '999'
      ..style.opacity = '0';

    html.document.body!.append(_overlay!);
    widget.onSetup(_overlay!);
  }

  @override
  void didUpdateWidget(_HtmlDropTarget old) {
    super.didUpdateWidget(old);
    // Reposition overlay when widget rebuilds (e.g. layout changes)
    WidgetsBinding.instance.addPostFrameCallback((_) => _repositionOverlay());
  }

  void _repositionOverlay() {
    if (_overlay == null) return;
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlay!
      ..style.left = '${offset.dx}px'
      ..style.top = '${offset.dy}px'
      ..style.width = '${size.width}px'
      ..style.height = '${size.height}px';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
}
