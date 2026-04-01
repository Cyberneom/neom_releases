// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase 1.5 (Album only): Name each track + set cover + publisher info.
///
/// Left side: list of uploaded tracks with editable title fields.
/// Right side: cover image picker + self-publish checkbox + year.
class ReleaseTracksPhase extends StatefulWidget {
  final ReleaseUploadWebController controller;

  const ReleaseTracksPhase({super.key, required this.controller});

  @override
  State<ReleaseTracksPhase> createState() => _ReleaseTracksPhaseState();
}

class _ReleaseTracksPhaseState extends State<ReleaseTracksPhase> {
  late List<TextEditingController> _trackNameControllers;
  bool _isCoverDragOver = false;

  @override
  void initState() {
    super.initState();
    _initTrackControllers();
    _registerGlobalDropListener();
  }

  void _registerGlobalDropListener() {
    // Prevent browser default drop behavior
    final body = html.document.body;
    if (body == null) return;
    body.onDragOver.listen((e) => e.preventDefault());
    body.onDrop.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      // Any drop on the page while this phase is active → treat as cover
      final files = e.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final ext = file.name.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
          _handleDroppedCover(file);
        }
      }
      if (mounted) setState(() => _isCoverDragOver = false);
    });
  }

  void _initTrackControllers() {
    _trackNameControllers = <TextEditingController>[];
    for (final f in widget.controller.releaseFiles) {
      final name = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      _trackNameControllers.add(TextEditingController(text: name));
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

  @override
  void dispose() {
    for (final c in _trackNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Save track names back to controller before proceeding.
  void saveTrackNames() {
    final names = _trackNameControllers.map((c) => c.text.trim()).toList();
    widget.controller.trackNames.assignAll(names);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: Track list with editable names ──
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReleaseTranslationConstants.trackNames.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ReleaseTranslationConstants.trackNamesDesc.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    // Rebuild if files change
                    final files = ctrl.releaseFiles.toList();
                    // Sync controllers if file count changed
                    while (_trackNameControllers.length < files.length) {
                      final name = files[_trackNameControllers.length]
                          .name.replaceAll(RegExp(r'\.[^.]+$'), '');
                      _trackNameControllers.add(TextEditingController(text: name));
                    }
                    while (_trackNameControllers.length > files.length) {
                      _trackNameControllers.removeLast().dispose();
                    }

                    return ReorderableListView.builder(
                      itemCount: files.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIdx, newIdx) {
                        if (newIdx > oldIdx) newIdx--;
                        // Reorder files
                        final file = ctrl.releaseFiles.removeAt(oldIdx);
                        ctrl.releaseFiles.insert(newIdx, file);
                        // Reorder controllers
                        final tc = _trackNameControllers.removeAt(oldIdx);
                        _trackNameControllers.insert(newIdx, tc);
                        saveTrackNames();
                      },
                      itemBuilder: (_, i) {
                        final file = files[i];
                        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);

                        return Container(
                          key: ValueKey('track_${file.name}_$i'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withAlpha(15)),
                          ),
                          child: Row(
                            children: [
                              // Drag handle
                              ReorderableDragStartListener(
                                index: i,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(Icons.drag_indicator, color: Colors.grey[700], size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Track number
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColor.bondiBlue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: AppColor.bondiBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Editable name
                              Expanded(
                                child: TextField(
                                  controller: _trackNameControllers[i],
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '${ReleaseTranslationConstants.trackNumber.tr} ${i + 1}',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => saveTrackNames(),
                                ),
                              ),
                              // File size
                              Text(
                                '$sizeMb MB',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              // Remove button
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ctrl.releaseFiles.removeAt(i);
                                  _trackNameControllers[i].dispose();
                                  _trackNameControllers.removeAt(i);
                                  saveTrackNames();
                                },
                                child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // Divider
        VerticalDivider(width: 1, color: Colors.white.withAlpha(15)),

        // ── Right: Cover + publisher info ──
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Self-published + year
                _publisherSection(ctrl),
                const SizedBox(height: 16),
                // Cover
                Text(
                  ReleaseTranslationConstants.releaseCover.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: Obx(() => _coverPicker(ctrl))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _publisherSection(ReleaseUploadWebController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Obx(() => Checkbox(
              value: ctrl.isSelfPublished.value,
              onChanged: (v) => ctrl.isSelfPublished.value = v ?? true,
              activeColor: AppColor.bondiBlue,
              side: BorderSide(color: Colors.grey[600]!),
            )),
            Text(
              ReleaseTranslationConstants.selfPublished.tr,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            // Year dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ReleaseTranslationConstants.publishedYear.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                Obx(() => DropdownButton<int>(
                  value: ctrl.publicationYear.value,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  underline: const SizedBox.shrink(),
                  items: List.generate(10, (i) => DateTime.now().year - i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => ctrl.publicationYear.value = v ?? DateTime.now().year,
                )),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _coverPicker(ReleaseUploadWebController ctrl) {
    if (ctrl.coverBytes.value != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              ctrl.coverBytes.value!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: InkWell(
              onTap: () {
                ctrl.coverBytes.value = null;
                ctrl.coverFileName.value = '';
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () async {
        try {
          final input = html.FileUploadInputElement()..accept = 'image/*';
          input.click();
          await input.onChange.first;
          if (input.files != null && input.files!.isNotEmpty) {
            _handleDroppedCover(input.files!.first);
          }
        } catch (_) {}
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isCoverDragOver ? AppColor.bondiBlue.withAlpha(20) : Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCoverDragOver ? AppColor.bondiBlue.withAlpha(120) : Colors.white.withAlpha(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[600], size: 40),
            const SizedBox(height: 8),
            Text(
              ReleaseTranslationConstants.dragImageOrClick.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              ReleaseTranslationConstants.supportedFormats.tr,
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
