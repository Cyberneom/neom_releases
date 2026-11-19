import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/address.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/domain/use_cases/mastering_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/data_assets.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

/// In-memory [PlatformFile] wrapper retaining loaded [bytes] and [size] for
/// synchronous web release UI phases (`file_picker` 13+ compatibility).
final class ReleasePickedFile extends PlatformFile {
  ReleasePickedFile({
    required this.name,
    required int size,
    Uint8List? bytes,
    this.path,
    Uri? uri,
  })  : _size = size,
        _bytes = bytes,
        uri = uri ?? _safeUriFromPath(path);

  static Uri _safeUriFromPath(String? path) {
    if (path == null || path.isEmpty) return Uri();
    try {
      return Uri.file(path);
    } catch (_) {
      return Uri();
    }
  }

  @override
  final String name;
  final int _size;
  final Uint8List? _bytes;

  @override
  final String? path;

  @override
  final Uri uri;

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => _size;

  @override
  Future<int?> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async => _bytes ?? Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() {
    final data = _bytes;
    return data == null || data.isEmpty
        ? const Stream<Uint8List>.empty()
        : Stream<Uint8List>.value(data);
  }
}

/// Preserves synchronous `.size` and `.bytes` access across web release UI phases.
extension ReleasePlatformFileCompat on PlatformFile {
  int get size {
    final self = this;
    if (self is ReleasePickedFile) return self._size;
    return lengthSync() ?? 0;
  }

  Uint8List? get bytes {
    final self = this;
    if (self is ReleasePickedFile) return self._bytes;
    return null;
  }
}

/// Lightweight controller for the web release upload modal.
/// Delegates actual upload to ReleaseUploadController.
class ReleaseUploadWebController extends SintController {

  // ── State ──
  final RxInt phase = 0.obs; // 0=type, 1=form, 2=tracks/dropshipping, 3=dropshipping/summary, 4=summary/success
  final RxBool isUploading = false.obs;
  bool isSubmitting = false;
  final RxBool hasSharedPost = false.obs;

  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = ''.obs;

  // ── Type selection ──
  final Rx<ReleaseType> releaseType = ReleaseType.single.obs;
  final Rx<ItemlistType> itemlistType = ItemlistType.single.obs;
  bool get isSingle => releaseType.value == ReleaseType.single;
  bool get isArtwork => releaseType.value == ReleaseType.artwork;
  bool get isAlbum => releaseType.value == ReleaseType.album ||
      releaseType.value == ReleaseType.ep ||
      releaseType.value == ReleaseType.demo;

  // ── Form fields ──
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descController = TextEditingController();

  // Curatorial fields for Artwork (ReleaseType.artwork)
  final artCategoryController = TextEditingController();
  final artTechniqueController = TextEditingController();
  final artMediumController = TextEditingController();
  final artDimensionsController = TextEditingController();
  final RxBool artIsOriginal = true.obs;
  final RxBool artIsSigned = true.obs;
  final RxBool artIsFramed = false.obs;
  final RxBool artIncludesShipping = false.obs;

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

  // Physical Sale / Dropshipping
  final RxBool isPhysical = false.obs;
  final physicalPriceController = TextEditingController();
  final RxBool shippingIncluded = false.obs;
  final shippingCityController = TextEditingController();
  final shippingStateController = TextEditingController();
  final shippingDaysController = TextEditingController();

  // ── Files ──
  final Rx<Uint8List?> coverBytes = Rx(null);
  final RxString coverFileName = ''.obs;
  final RxList<PlatformFile> releaseFiles = <PlatformFile>[].obs;
  final RxSet<int> masteredTrackIndices = <int>{}.obs;

  /// Track names for album uploads (one per file, editable by user).
  final RxList<String> trackNames = <String>[].obs;

  /// Alias for publishedYear (used by ReleaseTracksPhase).
  Rx<int> get publicationYear => publishedYear;

  // ── Reactive title tracker (for Siguiente button) ──
  final RxString _titleText = ''.obs;

  // ── Computed ──
  /// For singles: EMXI and Cyberneom accept PDF (books/articles), others accept audio.
  /// For albums (tracks): always audio regardless of app.
  /// For artworks: accept image formats (JPG, PNG, WebP).
  bool get singleAcceptsPdf => AppFlavour.singleAcceptsPdf() && isSingle;
  String get acceptedFileType => isArtwork
      ? 'JPG, PNG, WebP'
      : (singleAcceptsPdf ? 'PDF' : 'MP3');
  List<String> get acceptedExtensions => isArtwork
      ? ['jpg', 'jpeg', 'png', 'webp']
      : (singleAcceptsPdf ? ['pdf'] : ['mp3']);

  // ── Reactive description tracker ──
  final RxString _descText = ''.obs;

  bool get canProceedToForm => true; // Type is always selected
  bool get canProceedToSummary {
    if (isArtwork) {
      return _titleText.value.isNotEmpty &&
          _descText.value.isNotEmpty &&
          (coverBytes.value != null || releaseFiles.isNotEmpty);
    }
    return _titleText.value.isNotEmpty &&
        selectedInstruments.isNotEmpty &&
        _descText.value.isNotEmpty &&
        releaseFiles.isNotEmpty;
  }

  UserService? get _userService =>
      Sint.isRegistered<UserService>() ? Sint.find<UserService>() : null;

  @override
  void onInit() {
    super.onInit();
    final user = _userService;
    if (user != null) {
      authorController.text = user.profile.name;
    }

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
    artCategoryController.dispose();
    artTechniqueController.dispose();
    artMediumController.dispose();
    artDimensionsController.dispose();
    physicalPriceController.dispose();
    shippingCityController.dispose();
    shippingStateController.dispose();
    shippingDaysController.dispose();
    phase.close();
    isUploading.close();
    hasSharedPost.close();
    uploadProgress.close();
    uploadStatus.close();
    releaseType.close();
    itemlistType.close();
    artIsOriginal.close();
    artIsSigned.close();
    artIsFramed.close();
    artIncludesShipping.close();
    selectedInstruments.close();
    selectedInstrument.close();
    instrumentNames.close();
    selectedGenres.close();
    genreNames.close();
    selectedGenre.close();
    isSelfPublished.close();
    publishedYear.close();
    isPhysical.close();
    shippingIncluded.close();
    coverBytes.close();
    coverFileName.close();
    releaseFiles.close();
    masteredTrackIndices.close();
    trackNames.close();
    _titleText.close();
    _descText.close();
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
        : (type == ReleaseType.artwork ? ItemlistType.gallery : ItemlistType.album));
    phase.value = 1;
  }

  void _resetForm() {
    titleController.clear();
    authorController.clear();
    descController.clear();
    artCategoryController.clear();
    artTechniqueController.clear();
    artMediumController.clear();
    artDimensionsController.clear();
    artIsOriginal.value = true;
    artIsSigned.value = true;
    artIsFramed.value = false;
    isPhysical.value = false;
    physicalPriceController.clear();
    shippingIncluded.value = false;
    shippingCityController.clear();
    shippingStateController.clear();
    shippingDaysController.clear();
    coverBytes.value = null;
    releaseFiles.clear();
    masteredTrackIndices.clear();
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
      // If album -> tracks phase (2). For single/book/artwork -> physical sale phase (2).
      phase.value = 2;
    } else if (phase.value == 2) {
      // If album -> physical sale phase (3). For single/book/artwork -> summary phase (3).
      phase.value = 3;
    } else if (phase.value == 3 && isAlbum) {
      // For album -> summary phase (4).
      phase.value = 4;
    }
  }

  void skipPhysicalSale() {
    isPhysical.value = false;
    if (isAlbum) {
      phase.value = 4; // Album summary
    } else {
      phase.value = 3; // Single / book / artwork summary
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

  static const int _maxCoverBytes = 20 * 1024 * 1024;
  static const int _maxMediaBytes = 150 * 1024 * 1024;
  static const int _maxReleaseFiles = 64;

  Future<Uint8List?> _readBoundedFileBytes(
    PlatformFile file, {
    required int maxBytes,
  }) async {
    final knownSize = file.lengthSync() ?? await file.length();
    if (knownSize != null && (knownSize <= 0 || knownSize > maxBytes)) {
      return null;
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (builder.length + chunk.length > maxBytes) {
        return null;
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    return bytes.isEmpty ? null : bytes;
  }

  // ── File picking ──
  Future<void> pickCoverImage() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (picked == null) return;
      final bytes = await _readBoundedFileBytes(
        picked,
        maxBytes: _maxCoverBytes,
      );
      if (bytes != null && bytes.isNotEmpty) {
        coverBytes.value = bytes;
        coverFileName.value = picked.name.trim();
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_releases',
        operation: 'pickCoverImage',
      );
    }
  }

  Future<void> pickReleaseFiles() async {
    try {
      final List<PlatformFile> pickedFiles;
      if (isAlbum || isArtwork) {
        pickedFiles = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: acceptedExtensions,
        );
      } else {
        final single = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: acceptedExtensions,
        );
        pickedFiles = single == null ? const [] : <PlatformFile>[single];
      }
      if (pickedFiles.isEmpty) return;

      final remainingSlots = isSingle
          ? 1
          : (_maxReleaseFiles - releaseFiles.length).clamp(0, _maxReleaseFiles);
      if (remainingSlots <= 0) return;

      final loaded = <PlatformFile>[];
      for (final f in pickedFiles.take(remainingSlots)) {
        final data = await _readBoundedFileBytes(
          f,
          maxBytes: _maxMediaBytes,
        );
        if (data == null) continue;
        loaded.add(
          ReleasePickedFile(
            name: f.name.trim(),
            size: data.length,
            bytes: data,
            path: f.path,
            uri: f.uri,
          ),
        );
      }
      if (loaded.isEmpty) return;
      if (isSingle) {
        releaseFiles.assignAll([loaded.first]);
      } else {
        releaseFiles.addAll(loaded);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_releases',
        operation: 'pickReleaseFiles',
      );
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
    final file = ReleasePickedFile(name: name, size: bytes.length, bytes: bytes);
    if (isSingle) {
      releaseFiles.assignAll([file]);
    } else {
      releaseFiles.add(file);
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < releaseFiles.length) {
      releaseFiles.removeAt(index);
      masteredTrackIndices.remove(index);
    }
  }

  bool get canMasterTracks =>
      !isArtwork && !singleAcceptsPdf && Sint.isRegistered<MasteringService>();

  Future<void> masterTrackAtIndex(BuildContext context, int index) async {
    if (!canMasterTracks || index < 0 || index >= releaseFiles.length) return;
    final file = releaseFiles[index];
    final mastering = Sint.find<MasteringService>();
    final result = await mastering.openMasteringForTrack(
      context: context,
      initialBytes: file.bytes,
      fileName: file.name,
      trackTitle: isSingle
          ? titleController.text.trim()
          : (index < trackNames.length ? trackNames[index] : file.name),
      genreHint: selectedGenres.isNotEmpty
          ? selectedGenres.first
          : (selectedInstruments.isNotEmpty ? selectedInstruments.first : null),
    );

    if (result != null && result.bytes != null && result.bytes!.isNotEmpty) {
      releaseFiles[index] = ReleasePickedFile(
        name: result.fileName,
        size: result.bytes!.length,
        bytes: result.bytes,
        path: file.path,
        uri: file.uri,
      );
      masteredTrackIndices.add(index);
    } else if (result != null && result.hasMasterAsset) {
      masteredTrackIndices.add(index);
    }
  }

  // ── Build release items from form data ──
  Itemlist buildItemlist() {
    return Itemlist(
      name: titleController.text.trim(),
      description: descController.text.trim(),
      type: isArtwork ? ItemlistType.gallery : itemlistType.value,
    );
  }

  List<AppReleaseItem> buildReleaseItems() {
    final items = <AppReleaseItem>[];
    final ownerEmail = _userService?.user.email ?? '';

    Price? physicalPrice;
    if (isPhysical.value && physicalPriceController.text.trim().isNotEmpty) {
      final physAmt = double.tryParse(physicalPriceController.text.trim());
      if (physAmt != null && physAmt.isFinite && physAmt > 0) {
        physicalPrice = Price(amount: physAmt, currency: AppCurrency.mxn);
      }
    }

    // Merge instruments + subgenres + art category into categories
    final categories = <String>[];
    if (isArtwork && artCategoryController.text.trim().isNotEmpty) {
      categories.add(artCategoryController.text.trim());
    }
    categories.addAll(selectedInstruments);
    categories.addAll(selectedGenres);

    Place? place;
    if (shippingCityController.text.trim().isNotEmpty || shippingStateController.text.trim().isNotEmpty) {
      place = Place(
        address: Address(
          city: shippingCityController.text.trim(),
          state: shippingStateController.text.trim(),
          country: 'México',
        ),
      );
    }

    if (isArtwork) {
      final name = titleController.text.trim();
      items.add(AppReleaseItem(
        name: name,
        description: descController.text.trim(),
        ownerEmail: ownerEmail,
        ownerName: authorController.text.trim(),
        type: ReleaseType.artwork,
        mediaType: MediaItemType.artwork,
        categories: categories.isNotEmpty ? categories : ['Arte'],
        publishedYear: publishedYear.value,
        physicalPrice: physicalPrice,
        place: place,
        artCategory: artCategoryController.text.trim(),
        artTechnique: artTechniqueController.text.trim(),
        artMedium: artMediumController.text.trim(),
        artDimensions: artDimensionsController.text.trim(),
        artIsOriginal: artIsOriginal.value,
        artIsSigned: artIsSigned.value,
        artIsFramed: artIsFramed.value,
        artIncludesShipping: isPhysical.value && (shippingIncluded.value || artIncludesShipping.value),
      ));
      return items;
    }

    for (int i = 0; i < releaseFiles.length; i++) {
      final file = releaseFiles[i];
      final name = isSingle
          ? titleController.text.trim()
          : file.name.replaceAll(RegExp(r'\.[^.]+$'), '');

      items.add(AppReleaseItem(
        name: name,
        description: descController.text.trim(),
        ownerEmail: ownerEmail,
        ownerName: authorController.text.trim(),
        type: isSingle ? ReleaseType.single : ReleaseType.album,
        mediaType: singleAcceptsPdf ? MediaItemType.pdf : MediaItemType.song,
        categories: categories,
        physicalPrice: physicalPrice,
        place: place,
        artIncludesShipping: isPhysical.value && shippingIncluded.value,
      ));
    }
    return items;
  }
}
