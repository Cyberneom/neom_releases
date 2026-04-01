import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/data_assets.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

/// Lightweight controller for the web release upload modal.
/// Delegates actual upload to ReleaseUploadController.
class ReleaseUploadWebController extends SintController {

  // ── State ──
  final RxInt phase = 0.obs; // 0=type, 1=form, 2=summary
  final RxBool isUploading = false.obs;
  final RxBool hasSharedPost = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = ''.obs;

  // ── Type selection ──
  final Rx<ReleaseType> releaseType = ReleaseType.single.obs;
  final Rx<ItemlistType> itemlistType = ItemlistType.single.obs;
  bool get isSingle => releaseType.value == ReleaseType.single;
  bool get isAlbum => !isSingle;

  // ── Form fields ──
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descController = TextEditingController();

  // Genres (release_genres.json) — multi-select up to 3
  final RxList<String> selectedInstruments = <String>[].obs;
  final RxString selectedInstrument = ''.obs; // legacy compat
  final RxList<String> instrumentNames = <String>[].obs;

  // Subgenres (release_subgenres.json) — multi-select up to 5
  final RxList<String> selectedGenres = <String>[].obs;
  final RxList<String> genreNames = <String>[].obs;

  // Legacy single genre (kept for backward compat in buildReleaseItems)
  final RxString selectedGenre = ''.obs;

  // Publisher / year fields
  final RxBool isSelfPublished = true.obs;
  final publisherController = TextEditingController();
  final Rx<int> publishedYear = DateTime.now().year.obs;

  // ── Files ──
  final Rx<Uint8List?> coverBytes = Rx(null);
  final RxString coverFileName = ''.obs;
  final RxList<PlatformFile> releaseFiles = <PlatformFile>[].obs;

  /// Track names for album uploads (one per file, editable by user).
  final RxList<String> trackNames = <String>[].obs;

  /// Alias for publishedYear (used by ReleaseTracksPhase).
  Rx<int> get publicationYear => publishedYear;

  // ── Reactive title tracker (for Siguiente button) ──
  final RxString _titleText = ''.obs;

  // ── Computed ──
  /// For singles: EMXI and Cyberneom accept PDF (books/articles), others accept audio.
  /// For albums (tracks): always audio regardless of app.
  bool get singleAcceptsPdf => AppFlavour.singleAcceptsPdf() && isSingle;
  String get acceptedFileType => singleAcceptsPdf ? 'PDF' : 'MP3';
  List<String> get acceptedExtensions =>
      singleAcceptsPdf ? ['pdf'] : ['mp3'];

  // ── Reactive description tracker ──
  final RxString _descText = ''.obs;

  bool get canProceedToForm => true; // Type is always selected
  bool get canProceedToSummary =>
      _titleText.value.isNotEmpty &&
      selectedInstruments.isNotEmpty &&
      _descText.value.isNotEmpty &&
      releaseFiles.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final user = Sint.find<UserService>();
    authorController.text = user.profile.name;

    // Keep reactive text fields in sync for Obx-driven button state
    titleController.addListener(() {
      _titleText.value = titleController.text.trim();
    });
    descController.addListener(() {
      _descText.value = descController.text.trim();
    });

    _loadInstrumentsAndGenres();
  }

  Future<void> _loadInstrumentsAndGenres() async {
    try {
      // Load release genres
      final instrumentStr = await rootBundle.loadString(DataAssets.releaseGenresJsonPath);
      final List<dynamic> instrumentsJson = jsonDecode(instrumentStr);
      instrumentNames.value = instrumentsJson
          .map<String>((e) => e['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      // Load release subgenres
      final genreStr = await rootBundle.loadString(DataAssets.releaseSubgenresJsonPath);
      final List<dynamic> genresJson = jsonDecode(genreStr);
      genreNames.value = genresJson
          .map<String>((e) => e['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      AppConfig.logger.d('Loaded ${instrumentNames.length} release genres, ${genreNames.length} release subgenres');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_releases', operation: 'loadInstrumentsAndGenres');
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    authorController.dispose();
    descController.dispose();
    publisherController.dispose();
    super.onClose();
  }

  // ── Navigation ──
  void selectType(ReleaseType type, {ItemlistType? subtype}) {
    // Reset form when changing type
    if (releaseType.value != type) {
      _resetForm();
    }
    releaseType.value = type;
    itemlistType.value = subtype ?? (type == ReleaseType.single
        ? ItemlistType.single
        : ItemlistType.album);
    phase.value = 1;
  }

  void _resetForm() {
    titleController.clear();
    authorController.clear();
    descController.clear();
    coverBytes.value = null;
    releaseFiles.clear();
    selectedInstruments.clear();
    selectedGenres.clear();
  }

  void goBack() {
    if (phase.value > 0) phase.value--;
  }

  void goNext() {
    if (phase.value == 0) {
      phase.value = 1;
    } else if (phase.value == 1 && canProceedToSummary) {
      phase.value = 2; // Albums go to tracks phase, singles go to summary
    } else if (phase.value == 2 && isAlbum) {
      phase.value = 3; // Albums: tracks → summary
    }
  }

  // ── Genre helpers ──
  void toggleInstrument(String instrument) {
    if (selectedInstruments.contains(instrument)) {
      selectedInstruments.remove(instrument);
    } else if (selectedInstruments.length < 3) {
      selectedInstruments.add(instrument);
    }
    // Sync legacy field
    selectedInstrument.value = selectedInstruments.isNotEmpty ? selectedInstruments.first : '';
  }

  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else if (selectedGenres.length < 5) {
      selectedGenres.add(genre);
    }
    // Sync legacy field
    selectedGenre.value = selectedGenres.isNotEmpty ? selectedGenres.first : '';
  }

  // ── File picking ──
  Future<void> pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      coverBytes.value = result.files.first.bytes;
      coverFileName.value = result.files.first.name;
    }
  }

  Future<void> pickReleaseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: acceptedExtensions,
      allowMultiple: isAlbum,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      if (isSingle) {
        releaseFiles.assignAll([result.files.first]);
      } else {
        releaseFiles.addAll(result.files);
      }
    }
  }

  void addFilesFromBytes(List<PlatformFile> files) {
    if (isSingle && files.isNotEmpty) {
      releaseFiles.assignAll([files.first]);
    } else {
      releaseFiles.addAll(files);
    }
  }

  /// Add a file from raw bytes (used by HTML5 drag & drop).
  void addFileFromRawBytes(String name, Uint8List bytes) {
    final file = PlatformFile(name: name, size: bytes.length, bytes: bytes);
    if (isSingle) {
      releaseFiles.assignAll([file]);
    } else {
      releaseFiles.add(file);
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < releaseFiles.length) {
      releaseFiles.removeAt(index);
    }
  }

  // ── Build release items from form data ──
  Itemlist buildItemlist() {
    return Itemlist(
      name: titleController.text.trim(),
      description: descController.text.trim(),
      type: itemlistType.value,
    );
  }

  List<AppReleaseItem> buildReleaseItems() {
    final items = <AppReleaseItem>[];
    final user = Sint.find<UserService>();

    // Merge instruments + subgenres into categories
    final categories = <String>[];
    categories.addAll(selectedInstruments);
    categories.addAll(selectedGenres);

    for (int i = 0; i < releaseFiles.length; i++) {
      final file = releaseFiles[i];
      final name = isSingle
          ? titleController.text.trim()
          : file.name.replaceAll(RegExp(r'\.[^.]+$'), '');

      items.add(AppReleaseItem(
        name: name,
        description: descController.text.trim(),
        ownerEmail: user.user.email,
        ownerName: authorController.text.trim(),
        type: isSingle ? ReleaseType.single : ReleaseType.album,
        mediaType: singleAcceptsPdf ? MediaItemType.pdf : MediaItemType.song,
        categories: categories,
      ));
    }
    return items;
  }
}
