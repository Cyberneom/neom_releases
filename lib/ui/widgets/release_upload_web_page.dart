import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_commons/ui/widgets/buttons/submit_button.dart';
import 'package:neom_commons/ui/widgets/images/media_preview_image.dart';
import 'package:neom_commons/ui/widgets/number_limit_input_formatter.dart';
import 'package:neom_commons/ui/widgets/right_side_company_logo.dart';
import 'package:neom_commons/ui/widgets/web_content_wrapper.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/release_translation_constants.dart';
import '../release_upload_controller.dart';
import 'publisher_search_field.dart';

/// Single-page release upload form optimized for web.
/// Combines all creation steps (type, name/desc, instruments, genres, info)
/// into one scrollable page — similar to CreateEventWebPage.
class ReleaseUploadWebPage extends StatelessWidget {
  const ReleaseUploadWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      init: ReleaseUploadController(),
      builder: (controller) => WebKeyboardManager(
        pageId: 'releaseUpload',
        child: Scaffold(
        appBar: AppBar(
          title: Text(ReleaseTranslationConstants.releaseUpload.tr),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [RightSideCompanyLogo()],
        ),
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: AppTheme.appBoxDecoration,
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : WebContentWrapper(
                    maxWidth: 750,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Tipo de publicación ───
                          _sectionHeader(ReleaseTranslationConstants.releaseUploadType.tr),
                          const SizedBox(height: 12),
                          _buildReleaseTypeChips(controller),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),

                          // ─── Autor, título y descripción ───
                          _sectionHeader(ReleaseTranslationConstants.releaseUploadNameDesc.tr),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.authorController,
                            onChanged: (_) => controller.setReleaseAuthor(),
                            decoration: _inputDecoration(
                              ReleaseTranslationConstants.releaseAuthor.tr,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.titleController,
                            onChanged: (_) => controller.setReleaseTitle(),
                            decoration: _inputDecoration(
                              ReleaseTranslationConstants.releaseTitle.tr,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.descController,
                            onChanged: (_) => controller.setReleaseDesc(),
                            minLines: 2,
                            maxLines: 6,
                            decoration: _inputDecoration(
                              ReleaseTranslationConstants.releaseDesc.tr,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Duration / Physical price row (for Emxi)
                          if (AppConfig.instance.appInUse == AppInUse.e) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.durationController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      NumberLimitInputFormatter(1000),
                                    ],
                                    decoration: _inputDecoration(
                                      ReleaseTranslationConstants.appItemDurationShort.tr,
                                    ),
                                    onChanged: (_) => controller.setReleaseDuration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller.physicalPriceController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      NumberLimitInputFormatter(500),
                                    ],
                                    decoration: _inputDecoration(
                                      ReleaseTranslationConstants.physicalReleasePrice.tr,
                                      hint: '(${AppTranslationConstants.optional.tr})',
                                      suffix: AppCurrency.mxn.value.tr.toUpperCase(),
                                    ),
                                    onChanged: (_) => controller.setPhysicalReleasePrice(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ─── Archivos / Track List ───
                          _buildTrackListSection(controller),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),

                          // ─── Instrumentos ───
                          if (AppConfig.instance.appInUse == AppInUse.g) ...[
                            _sectionHeader(ReleaseTranslationConstants.releaseUploadInstr.tr),
                            const SizedBox(height: 12),
                            _buildInstrumentChips(controller),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 16),
                          ],

                          // ─── Géneros / Categorías ───
                          Obx(() => controller.genres.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader(ReleaseTranslationConstants.releaseUploadGenres.tr),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: controller.genreChips.toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              : const SizedBox.shrink()),

                          // ─── Publicación / Lugar / Año ───
                          _sectionHeader(ReleaseTranslationConstants.releaseUploadPLaceDate.tr),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _autoPublishCheckbox(controller),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _yearDropdown(controller),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(() => !controller.isAutoPublished.value
                              ? AppConfig.instance.appInUse == AppInUse.e
                                  ? PublisherSearchField(
                                      controller: controller.placeController,
                                      onPublisherSelected: controller.onPublisherSelected,
                                    )
                                  : TextFormField(
                                      controller: controller.placeController,
                                      onTap: () => controller.getPublisherPlace(context),
                                      decoration: _inputDecoration(
                                        ReleaseTranslationConstants.specifyPublishingPlace.tr,
                                      ),
                                    )
                              : const SizedBox.shrink()),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),

                          // ─── Portada ───
                          _sectionHeader(ReleaseTranslationConstants.addReleaseCoverImg.tr),
                          const SizedBox(height: 12),
                          _buildCoverImageSection(context, controller),
                          const SizedBox(height: 24),

                          // ─── Upload progress ───
                          Obx(() => controller.uploadStatusMessage.value.isNotEmpty
                              ? _buildUploadProgress(controller)
                              : const SizedBox.shrink()),

                          // ─── Botón publicar ───
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: Obx(() => SubmitButton(
                                context,
                                text: AppConfig.instance.appInfo.releaseRevisionEnabled
                                    ? ReleaseTranslationConstants.submitRelease.tr
                                    : ReleaseTranslationConstants.publishOnPlatform.tr,
                                isLoading: controller.isLoading.value && controller.uploadStatusMessage.value.isNotEmpty,
                                isEnabled: !controller.isButtonDisabled.value
                                    && controller.titleController.text.isNotEmpty
                                    && (controller.appReleaseItems.isNotEmpty
                                        || controller.releaseFilePreviewURL.isNotEmpty),
                                onPressed: () => AuthGuard.protect(context, () => controller.createReleaseDirect(context)),
                              )),
                            ),
                          ),
                          Obx(() => !controller.isLoading.value
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    AppConfig.instance.appInfo.releaseRevisionEnabled
                                        ? ReleaseTranslationConstants.submitReleaseMsg.tr
                                        : ReleaseTranslationConstants.publishOnPlatformMsg.tr,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox.shrink()),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
      ),
    );
  }

  // ─── Shared helpers ───

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? suffix}) {
    return InputDecoration(
      filled: true,
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ─── Release type ───

  Widget _buildReleaseTypeChips(ReleaseUploadController controller) {
    final types = AppConfig.instance.appInUse == AppInUse.e
        ? [ReleaseType.single, ReleaseType.chapter]
        : [ReleaseType.single, ReleaseType.album, ReleaseType.ep, ReleaseType.demo];

    return Obx(() => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = controller.appReleaseItem.value.type == type
            && controller.releaseItemsQty.value > 0;
        return ChoiceChip(
          label: Text(type.value.tr.capitalizeFirst),
          selected: isSelected,
          selectedColor: AppColor.bondiBlue,
          backgroundColor: AppColor.surfaceElevated,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: AppTheme.chipsFontSize,
          ),
          shape: AppTheme.outlinedBorderChip,
          onSelected: (_) => controller.setReleaseTypeWeb(type),
        );
      }).toList(),
    ));
  }

  // ─── Track list section (DistroKid-style) ───

  Widget _buildTrackListSection(ReleaseUploadController controller) {
    final isSingle = controller.releaseItemsQty.value <= 1;

    // For singles, show simple file picker
    if (isSingle) {
      return Obx(() => Column(
        children: [
          _buildAddTracksButton(controller),
          if (controller.releaseFilePreviewURL.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                controller.releaseFilePreviewURL.value,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ));
    }

    // For albums/EPs, show full track list
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(FontAwesomeIcons.listOl, size: 14, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              ReleaseTranslationConstants.trackList.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (controller.appReleaseItems.isNotEmpty)
              Text(
                '${controller.appReleaseItems.length} ${ReleaseTranslationConstants.tracksSelected.tr}',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Track list or empty state
        if (controller.appReleaseItems.isEmpty)
          _buildEmptyTrackState(controller)
        else
          _buildReorderableTrackList(controller),

        const SizedBox(height: 12),

        // Add/Change tracks button
        _buildAddTracksButton(controller),
      ],
    ));
  }

  Widget _buildEmptyTrackState(ReleaseUploadController controller) {
    return GestureDetector(
      onTap: () => controller.addReleaseFilesWeb(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.cloudArrowUp, size: 36, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              ReleaseTranslationConstants.noTracksAdded.tr,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ReleaseTranslationConstants.selectAudioFiles.tr,
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableTrackList(ReleaseUploadController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: controller.appReleaseItems.length,
        onReorder: controller.reorderTrack,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            elevation: 4,
            shadowColor: AppColor.bondiBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final track = controller.appReleaseItems[index];
          return _TrackRow(
            key: ValueKey('track_$index'),
            index: index,
            trackName: track.name,
            fileName: track.previewUrl,
            onNameChanged: (name) => controller.updateTrackName(index, name),
            onRemove: () => controller.removeTrackAt(index),
          );
        },
      ),
    );
  }

  Widget _buildAddTracksButton(ReleaseUploadController controller) {
    final hasFiles = controller.appReleaseItems.isNotEmpty
        || controller.releaseFilePreviewURL.isNotEmpty;

    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          if (controller.releaseItemsQty.value <= 1) {
            controller.addReleaseFile();
          } else {
            controller.addReleaseFilesWeb();
          }
        },
        icon: Icon(hasFiles ? Icons.swap_horiz : FontAwesomeIcons.music, size: 16),
        label: Text(
          hasFiles
              ? ReleaseTranslationConstants.changeReleaseFile.tr
              : ReleaseTranslationConstants.addTracks.tr,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  // ─── Instruments ───

  Widget _buildInstrumentChips(ReleaseUploadController controller) {
    return Obx(() {
      final instruments = controller.instrumentServiceImpl.instruments.values.toList();
      if (instruments.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: instruments.where((i) => i.name.isNotEmpty).map((instrument) {
          final isSelected = controller.instrumentsUsed.contains(instrument.name);
          return FilterChip(
            label: Text(
              instrument.name.tr.capitalizeFirst,
              style: TextStyle(
                fontSize: AppTheme.chipsFontSize,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColor.surfaceCard,
            backgroundColor: AppColor.surfaceElevated,
            checkmarkColor: Colors.white,
            onSelected: (selected) {
              final index = instruments.indexOf(instrument);
              if (selected) {
                controller.addInstrument(index);
              } else {
                controller.removeInstrument(index);
              }
            },
          );
        }).toList(),
      );
    });
  }

  // ─── Auto-publish checkbox ───

  Widget _autoPublishCheckbox(ReleaseUploadController controller) {
    return Obx(() => GestureDetector(
      onTap: () => controller.setIsAutoPublished(),
      child: Row(
        children: [
          Checkbox(
            value: controller.isAutoPublished.value,
            onChanged: (_) => controller.setIsAutoPublished(),
          ),
          Flexible(
            child: Text(
              ReleaseTranslationConstants.autoPublishingEditingMsg.tr,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    ));
  }

  // ─── Year dropdown ───

  Widget _yearDropdown(ReleaseUploadController controller) {
    return Obx(() => DropdownButton<int>(
      hint: Text(
        ReleaseTranslationConstants.publishedYear.tr,
        style: const TextStyle(fontSize: 13),
      ),
      isExpanded: true,
      value: controller.publishedYear.value != 0
          ? controller.publishedYear.value
          : null,
      onChanged: (year) {
        if (year != null) controller.setPublishedYear(year);
      },
      items: controller.getYearsList().reversed.map((int year) {
        return DropdownMenuItem<int>(
          alignment: Alignment.center,
          value: year,
          child: Text(year.toString()),
        );
      }).toList(),
      iconSize: 18,
      elevation: 16,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppColor.getMain(),
      underline: Container(height: 1, color: Colors.grey),
    ));
  }

  // ─── Cover image ───

  Widget _buildCoverImageSection(
      BuildContext context, ReleaseUploadController controller) {
    return Obx(() {
      final hasImage = controller.mediaUploadServiceImpl?.mediaFileExists() ?? false;
      final isBookApp = AppConfig.instance.appInUse == AppInUse.e;

      return Column(
        children: [
          if (hasImage)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildMediaPreview(
                    controller.mediaUploadServiceImpl,
                    height: isBookApp ? 280 : 200,
                    width: isBookApp ? 186 : 200,
                    fit: BoxFit.cover,
                  ) ?? const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      padding: EdgeInsets.zero,
                      onPressed: () => controller.clearReleaseCoverImg(),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => controller.addReleaseCoverImg(),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: Text(
              hasImage
                  ? AppTranslationConstants.changeImage.tr
                  : ReleaseTranslationConstants.addReleaseCoverImg.tr,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      );
    });
  }

  // ─── Upload progress indicator ───

  Widget _buildUploadProgress(ReleaseUploadController controller) {
    return Obx(() {
      final total = controller.appReleaseItems.length;
      final current = controller.releaseItemIndex.value;
      final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // Per-track progress bar
            if (total > 1) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(AppColor.bondiBlue),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  controller.uploadStatusMessage.value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Individual track row widget with inline editing, reorder handle, and remove button.
class _TrackRow extends StatefulWidget {
  final int index;
  final String trackName;
  final String fileName;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onRemove;

  const _TrackRow({
    super.key,
    required this.index,
    required this.trackName,
    required this.fileName,
    required this.onNameChanged,
    required this.onRemove,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trackName);
  }

  @override
  void didUpdateWidget(_TrackRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackName != widget.trackName && !_isEditing) {
      _nameController.text = widget.trackName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        color: widget.index.isEven
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: widget.index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
                ),
              ),
            ),

            // Track number
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.bondiBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: AppColor.bondiBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Track name (editable)
            Expanded(
              child: _isEditing
                  ? TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppColor.bondiBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppColor.bondiBlue),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        widget.onNameChanged(value.trim());
                        setState(() => _isEditing = false);
                      },
                      onTapOutside: (_) {
                        widget.onNameChanged(_nameController.text.trim());
                        setState(() => _isEditing = false);
                      },
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.trackName.isNotEmpty
                                ? widget.trackName
                                : ReleaseTranslationConstants.trackName.tr,
                            style: TextStyle(
                              color: widget.trackName.isNotEmpty
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.fileName,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),

            // MP3 badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.bondiBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.fileName.split('.').last.toUpperCase(),
                style: TextStyle(
                  color: AppColor.bondiBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Edit button
            IconButton(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit_outlined,
                size: 16,
                color: Colors.white38,
              ),
              onPressed: () {
                if (_isEditing) {
                  widget.onNameChanged(_nameController.text.trim());
                }
                setState(() => _isEditing = !_isEditing);
              },
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              splashRadius: 16,
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white24),
              onPressed: widget.onRemove,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              tooltip: ReleaseTranslationConstants.removeTrack.tr,
            ),
          ],
        ),
      ),
    );
  }
}
