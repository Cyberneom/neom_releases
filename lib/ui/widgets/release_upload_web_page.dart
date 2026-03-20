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

/// Two-column release upload form optimized for web.
/// Left: form sections in glass cards. Right: sticky cover + preview + submit.
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
          appBar: SintAppBar(
            title: ReleaseTranslationConstants.releaseUpload.tr,
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
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ═══ Left column: scrollable form ═══
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(right: 24, bottom: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTypeCard(controller),
                                      const SizedBox(height: 16),
                                      _buildInfoCard(context, controller),
                                      const SizedBox(height: 16),
                                      _buildTracksCard(controller),
                                      const SizedBox(height: 16),
                                      if (AppConfig.instance.appInUse == AppInUse.g)
                                        _buildInstrumentsCard(controller),
                                      if (AppConfig.instance.appInUse == AppInUse.g)
                                        const SizedBox(height: 16),
                                      _buildGenresCard(controller),
                                      const SizedBox(height: 16),
                                      _buildPublicationCard(context, controller),
                                    ],
                                  ),
                                ),
                              ),
                              // ═══ Right column: sticky sidebar ═══
                              SizedBox(
                                width: 300,
                                child: _buildSidebar(context, controller),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  Glass card wrapper
  // ═══════════════════════════════════════════

  Widget _glassCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColor.bondiBlue),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppColor.bondiBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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

  // ═══════════════════════════════════════════
  //  1. Release Type Card
  // ═══════════════════════════════════════════

  Widget _buildTypeCard(ReleaseUploadController controller) {
    final types = AppConfig.instance.appInUse == AppInUse.e
        ? [ReleaseType.single, ReleaseType.chapter]
        : [ReleaseType.single, ReleaseType.album, ReleaseType.ep, ReleaseType.demo];

    return _glassCard(
      title: ReleaseTranslationConstants.releaseUploadType.tr.toUpperCase(),
      icon: FontAwesomeIcons.compactDisc,
      child: Obx(() => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: types.map((type) {
          final isSelected = controller.appReleaseItem.value.type == type
              && controller.releaseItemsQty.value > 0;
          return ChoiceChip(
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(type.value.tr.capitalizeFirst),
            ),
            selected: isSelected,
            selectedColor: AppColor.bondiBlue,
            backgroundColor: AppColor.surfaceElevated,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: AppTheme.chipsFontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: AppTheme.outlinedBorderChip,
            onSelected: (_) => controller.setReleaseTypeWeb(type),
          );
        }).toList(),
      )),
    );
  }

  // ═══════════════════════════════════════════
  //  2. Info Card (Author, Title, Desc)
  // ═══════════════════════════════════════════

  Widget _buildInfoCard(BuildContext context, ReleaseUploadController controller) {
    return _glassCard(
      title: ReleaseTranslationConstants.releaseUploadNameDesc.tr.toUpperCase(),
      icon: FontAwesomeIcons.penFancy,
      child: Column(
        children: [
          TextFormField(
            controller: controller.authorController,
            onChanged: (_) => controller.setReleaseAuthor(),
            decoration: _inputDecoration(ReleaseTranslationConstants.releaseAuthor.tr),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.titleController,
            onChanged: (_) => controller.setReleaseTitle(),
            decoration: _inputDecoration(ReleaseTranslationConstants.releaseTitle.tr),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.descController,
            onChanged: (_) => controller.setReleaseDesc(),
            minLines: 2,
            maxLines: 6,
            decoration: _inputDecoration(ReleaseTranslationConstants.releaseDesc.tr),
          ),
          // Duration / Physical price (EMXI only)
          if (AppConfig.instance.appInUse == AppInUse.e) ...[
            const SizedBox(height: 12),
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
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  3. Tracks Card
  // ═══════════════════════════════════════════

  Widget _buildTracksCard(ReleaseUploadController controller) {
    return _glassCard(
      title: ReleaseTranslationConstants.trackList.tr.toUpperCase(),
      icon: FontAwesomeIcons.music,
      child: _buildTrackListSection(controller),
    );
  }

  Widget _buildTrackListSection(ReleaseUploadController controller) {
    final isSingle = controller.releaseItemsQty.value <= 1;

    if (isSingle) {
      return Obx(() => Column(
        children: [
          _buildDropZone(controller),
          if (controller.releaseFilePreviewURL.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.fileAudio, size: 14, color: AppColor.bondiBlue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      controller.releaseFilePreviewURL.value,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ));
    }

    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.appReleaseItems.isNotEmpty) ...[
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.bondiBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.appReleaseItems.length} ${ReleaseTranslationConstants.tracksSelected.tr}',
                  style: TextStyle(color: AppColor.bondiBlue, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReorderableTrackList(controller),
          const SizedBox(height: 16),
        ],
        _buildDropZone(controller),
      ],
    ));
  }

  Widget _buildDropZone(ReleaseUploadController controller) {
    final hasFiles = controller.appReleaseItems.isNotEmpty
        || controller.releaseFilePreviewURL.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (controller.releaseItemsQty.value <= 1) {
            controller.addReleaseFile();
          } else {
            controller.addReleaseFilesWeb();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: hasFiles ? 16 : 36,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                hasFiles ? Icons.swap_horiz : FontAwesomeIcons.cloudArrowUp,
                size: hasFiles ? 20 : 32,
                color: Colors.white24,
              ),
              SizedBox(height: hasFiles ? 6 : 12),
              Text(
                hasFiles
                    ? ReleaseTranslationConstants.changeReleaseFile.tr
                    : ReleaseTranslationConstants.noTracksAdded.tr,
                style: TextStyle(
                  color: hasFiles ? Colors.white54 : Colors.white38,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              if (!hasFiles) ...[
                const SizedBox(height: 6),
                Text(
                  ReleaseTranslationConstants.selectAudioFiles.tr,
                  style: TextStyle(
                    color: AppColor.bondiBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableTrackList(ReleaseUploadController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
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

  // ═══════════════════════════════════════════
  //  4. Instruments Card (Gigmeout only)
  // ═══════════════════════════════════════════

  Widget _buildInstrumentsCard(ReleaseUploadController controller) {
    return _glassCard(
      title: ReleaseTranslationConstants.releaseUploadInstr.tr.toUpperCase(),
      icon: FontAwesomeIcons.guitar,
      child: Obx(() {
        final instruments = controller.instrumentServiceImpl.instruments.values.toList();
        if (instruments.isEmpty) return const SizedBox.shrink();

        return Wrap(
          spacing: 6,
          runSpacing: 6,
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
      }),
    );
  }

  // ═══════════════════════════════════════════
  //  5. Genres Card
  // ═══════════════════════════════════════════

  Widget _buildGenresCard(ReleaseUploadController controller) {
    return Obx(() => controller.genres.isNotEmpty
        ? _glassCard(
            title: ReleaseTranslationConstants.releaseUploadGenres.tr.toUpperCase(),
            icon: FontAwesomeIcons.tags,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: controller.genreChips.toList(),
            ),
          )
        : const SizedBox.shrink());
  }

  // ═══════════════════════════════════════════
  //  6. Publication Card
  // ═══════════════════════════════════════════

  Widget _buildPublicationCard(BuildContext context, ReleaseUploadController controller) {
    return _glassCard(
      title: ReleaseTranslationConstants.releaseUploadPLaceDate.tr.toUpperCase(),
      icon: FontAwesomeIcons.calendarCheck,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: _autoPublishCheckbox(controller)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _yearDropdown(controller)),
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
        ],
      ),
    );
  }

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

  // ═══════════════════════════════════════════
  //  Right Sidebar (sticky)
  // ═══════════════════════════════════════════

  Widget _buildSidebar(BuildContext context, ReleaseUploadController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ─── Cover image ───
          _buildCoverCard(context, controller),
          const SizedBox(height: 16),
          // ─── Preview card ───
          _buildPreviewCard(controller),
          const SizedBox(height: 16),
          // ─── Upload progress ───
          Obx(() => controller.uploadStatusMessage.value.isNotEmpty
              ? _buildUploadProgress(controller)
              : const SizedBox.shrink()),
          // ─── Submit button ───
          SizedBox(
            width: double.infinity,
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
          const SizedBox(height: 8),
          Obx(() => !controller.isLoading.value
              ? Text(
                  AppConfig.instance.appInfo.releaseRevisionEnabled
                      ? ReleaseTranslationConstants.submitReleaseMsg.tr
                      : ReleaseTranslationConstants.publishOnPlatformMsg.tr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildCoverCard(BuildContext context, ReleaseUploadController controller) {
    return Obx(() {
      final hasImage = controller.mediaUploadServiceImpl?.mediaFileExists() ?? false;
      final isBookApp = AppConfig.instance.appInUse == AppInUse.e;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderSubtle),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 16, color: AppColor.bondiBlue),
                const SizedBox(width: 10),
                Text(
                  ReleaseTranslationConstants.addReleaseCoverImg.tr.toUpperCase(),
                  style: TextStyle(
                    color: AppColor.bondiBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasImage)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: buildMediaPreview(
                      controller.mediaUploadServiceImpl,
                      height: isBookApp ? 320 : 240,
                      width: isBookApp ? 213 : 240,
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
              )
            else
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => controller.addReleaseCoverImg(),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          ReleaseTranslationConstants.addReleaseCoverImg.tr,
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (hasImage) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => controller.addReleaseCoverImg(),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: Text(AppTranslationConstants.changeImage.tr),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ─── Album preview card ───

  Widget _buildPreviewCard(ReleaseUploadController controller) {
    return Obx(() {
      final title = controller.titleController.text;
      final author = controller.authorController.text;
      final trackCount = controller.appReleaseItems.length;
      final hasImage = controller.mediaUploadServiceImpl?.mediaFileExists() ?? false;
      final type = controller.appReleaseItem.value.type;

      if (title.isEmpty && !hasImage && trackCount == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColor.bondiBlue.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.bondiBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview_outlined, size: 16, color: AppColor.bondiBlue),
                const SizedBox(width: 10),
                Text(
                  'PREVIEW',
                  style: TextStyle(
                    color: AppColor.bondiBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                author,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (type.value.isNotEmpty)
                  _previewChip(type.value.tr.capitalizeFirst, FontAwesomeIcons.compactDisc),
                if (trackCount > 0) ...[
                  const SizedBox(width: 8),
                  _previewChip('$trackCount tracks', FontAwesomeIcons.music),
                ],
              ],
            ),
            // Track names preview
            if (trackCount > 0) ...[
              const SizedBox(height: 12),
              ...controller.appReleaseItems.take(5).toList().asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.name.isNotEmpty ? e.value.name : '...',
                          style: TextStyle(
                            color: e.value.name.isNotEmpty ? Colors.white70 : Colors.white24,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trackCount > 5)
                Text(
                  '+${trackCount - 5} more',
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _previewChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white38),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Upload progress ───

  Widget _buildUploadProgress(ReleaseUploadController controller) {
    return Obx(() {
      final total = controller.appReleaseItems.length;
      final current = controller.releaseItemIndex.value;
      final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.bondiBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.bondiBlue.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
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
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      controller.uploadStatusMessage.value,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),

            // File format badge
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
