import 'dart:typed_data';

import 'release_web_dom_bridge_types.dart';

void Function() registerReleaseBodyDrop({
  required void Function(List<ReleaseDroppedFile> files) onDrop,
  bool stopPropagation = false,
}) {
  return () {};
}

void Function() readReleaseDroppedFile(
  ReleaseDroppedFile file, {
  required int maxBytes,
  required ReleaseBytesCallback onLoaded,
}) {
  return () {};
}

ReleaseDropOverlayHandle? mountReleaseDropOverlay({
  required double left,
  required double top,
  required double width,
  required double height,
  void Function()? onClick,
  void Function()? onDragOver,
  void Function()? onDragLeave,
  void Function(List<ReleaseDroppedFile> files)? onDrop,
}) {
  return null;
}

String createReleasePdfBlobUrl(Uint8List bytes) => '';

void revokeReleasePdfBlobUrl(String blobUrl) {}
