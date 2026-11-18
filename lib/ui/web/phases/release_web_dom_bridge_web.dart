import 'dart:js_interop';
import 'dart:typed_data';

import 'release_web_dom_bridge_types.dart';

@JS('document')
external _DomDocument? get _document;

extension type _DomDocument._(JSObject _) implements JSObject {
  external _DomElement? get body;
  external _DomElement createElement(JSString tagName);
}

extension type _DomElement._(JSObject _) implements JSObject {
  external _DomCssStyle get style;
  external void appendChild(JSObject child);
  external void remove();
  external void addEventListener(JSString type, JSFunction listener);
  external void removeEventListener(JSString type, JSFunction listener);
}

extension type _DomCssStyle._(JSObject _) implements JSObject {
  external set position(String value);
  external set left(String value);
  external set top(String value);
  external set width(String value);
  external set height(String value);
  external set zIndex(String value);
  external set cursor(String value);
  external set opacity(String value);
}

extension type _DomDragEvent._(JSObject _) implements JSObject {
  external void preventDefault();
  external void stopPropagation();
  external _DomDataTransfer? get dataTransfer;
}

extension type _DomDataTransfer._(JSObject _) implements JSObject {
  external _DomFileList? get files;
}

extension type _DomFileList._(JSObject _) implements JSObject {
  external int get length;
  external _DomFile? item(int index);
}

extension type _DomFile._(JSObject _) implements JSObject {
  external String get name;
  external num get size;
}

@JS('Blob')
extension type _DomPdfBlob._(JSObject _) implements JSObject {
  external factory _DomPdfBlob(
    JSArray<JSAny?> blobParts, [
    _DomBlobPropertyBag options,
  ]);
}

extension type _DomBlobPropertyBag._(JSObject _) implements JSObject {
  external factory _DomBlobPropertyBag({String type});
}

@JS('URL.createObjectURL')
external String _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

double _clampOverlayPx(double v) =>
    v.isFinite ? v.clamp(0.0, 32768.0).toDouble() : 0.0;

String createReleasePdfBlobUrl(Uint8List bytes) {
  if (!hasValidPdfSignature(bytes)) return '';
  final options = _DomBlobPropertyBag(type: 'application/pdf');
  final blob = _DomPdfBlob(<JSAny?>[bytes.toJS].toJS, options);
  return _createObjectUrl(blob);
}

void revokeReleasePdfBlobUrl(String blobUrl) {
  if (!blobUrl.startsWith('blob:')) return;
  try {
    _revokeObjectUrl(blobUrl);
  } catch (_) {}
}

@JS('FileReader')
extension type _DomFileReader._(JSObject _) implements JSObject {
  external factory _DomFileReader();
  external int get readyState;
  external JSAny? get result;
  external set onloadend(JSFunction? callback);
  external void readAsArrayBuffer(JSObject blob);
  external void abort();
}

List<ReleaseDroppedFile> _extractDroppedFiles(_DomDragEvent dragEvent) {
  final list = dragEvent.dataTransfer?.files;
  if (list == null || list.length <= 0) return const [];
  final limit = list.length < kMaxDroppedReleaseFiles
      ? list.length
      : kMaxDroppedReleaseFiles;
  final out = <ReleaseDroppedFile>[];
  for (int i = 0; i < limit; i++) {
    final f = list.item(i);
    if (f == null) continue;
    final rawSize = f.size;
    final safeSize = rawSize.isFinite && rawSize >= 0 ? rawSize.toInt() : 0;
    out.add(
      ReleaseDroppedFile(
        name: sanitizeDroppedReleaseFileName(f.name),
        size: safeSize,
        handle: f,
      ),
    );
  }
  return out;
}

void Function() registerReleaseBodyDrop({
  required void Function(List<ReleaseDroppedFile> files) onDrop,
  bool stopPropagation = false,
}) {
  final body = _document?.body;
  if (body == null) return () {};

  final dragOverFn = ((JSAny? event) {
    if (event != null && event.isA<JSObject>()) {
      _DomDragEvent._(event as JSObject).preventDefault();
    }
  }).toJS;

  final dropFn = ((JSAny? event) {
    var dropped = const <ReleaseDroppedFile>[];
    if (event != null && event.isA<JSObject>()) {
      final dragEvent = _DomDragEvent._(event as JSObject);
      dragEvent.preventDefault();
      if (stopPropagation) {
        dragEvent.stopPropagation();
      }
      dropped = _extractDroppedFiles(dragEvent);
    }
    onDrop(dropped);
  }).toJS;

  body.addEventListener('dragover'.toJS, dragOverFn);
  body.addEventListener('drop'.toJS, dropFn);

  var disposed = false;
  return () {
    if (disposed) return;
    disposed = true;
    body.removeEventListener('dragover'.toJS, dragOverFn);
    body.removeEventListener('drop'.toJS, dropFn);
  };
}

void Function() readReleaseDroppedFile(
  ReleaseDroppedFile file, {
  required int maxBytes,
  required ReleaseBytesCallback onLoaded,
}) {
  if (!maxBytes.isFinite ||
      maxBytes <= 0 ||
      file.size <= 0 ||
      file.size > maxBytes) {
    return () {};
  }
  final reader = _DomFileReader();
  var cancelled = false;
  reader.onloadend = ((JSAny? _) {
    if (cancelled) return;
    final raw = reader.result;
    if (raw == null) return;
    Uint8List? bytes;
    if (raw.isA<JSArrayBuffer>()) {
      bytes = (raw as JSArrayBuffer).toDart.asUint8List();
    } else if (raw.isA<JSUint8Array>()) {
      bytes = (raw as JSUint8Array).toDart;
    }
    if (bytes != null && bytes.isNotEmpty && bytes.length <= maxBytes) {
      onLoaded(Uint8List.fromList(bytes));
    }
  }).toJS;

  try {
    reader.readAsArrayBuffer(file.handle as JSObject);
  } catch (_) {
    reader.onloadend = null;
    return () {};
  }

  return () {
    if (cancelled) return;
    cancelled = true;
    reader.onloadend = null;
    if (reader.readyState == 1) {
      try {
        reader.abort();
      } catch (_) {}
    }
  };
}

class _BrowserOverlayHandle implements ReleaseDropOverlayHandle {
  final _DomElement _div;
  final List<(JSString, JSFunction)> _listeners;
  bool _disposed = false;

  _BrowserOverlayHandle(this._div, this._listeners);

  @override
  void reposition({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    if (_disposed) return;
    _div.style
      ..left = '${_clampOverlayPx(left)}px'
      ..top = '${_clampOverlayPx(top)}px'
      ..width = '${_clampOverlayPx(width)}px'
      ..height = '${_clampOverlayPx(height)}px';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final (type, fn) in _listeners) {
      _div.removeEventListener(type, fn);
    }
    _listeners.clear();
    _div.remove();
  }
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
  final doc = _document;
  final body = doc?.body;
  if (doc == null || body == null) return null;

  final div = doc.createElement('div'.toJS);
  div.style
    ..position = 'fixed'
    ..left = '${_clampOverlayPx(left)}px'
    ..top = '${_clampOverlayPx(top)}px'
    ..width = '${_clampOverlayPx(width)}px'
    ..height = '${_clampOverlayPx(height)}px'
    ..zIndex = '999'
    ..cursor = 'pointer'
    ..opacity = '0';

  final listeners = <(JSString, JSFunction)>[];

  if (onClick != null) {
    final fn = ((JSAny? _) => onClick()).toJS;
    div.addEventListener('click'.toJS, fn);
    listeners.add(('click'.toJS, fn));
  }
  if (onDragOver != null) {
    final fn = ((JSAny? event) {
      if (event != null && event.isA<JSObject>()) {
        final de = _DomDragEvent._(event as JSObject);
        de.preventDefault();
        de.stopPropagation();
      }
      onDragOver();
    }).toJS;
    div.addEventListener('dragover'.toJS, fn);
    listeners.add(('dragover'.toJS, fn));
  }
  if (onDragLeave != null) {
    final fn = ((JSAny? event) {
      if (event != null && event.isA<JSObject>()) {
        _DomDragEvent._(event as JSObject).stopPropagation();
      }
      onDragLeave();
    }).toJS;
    div.addEventListener('dragleave'.toJS, fn);
    listeners.add(('dragleave'.toJS, fn));
  }
  if (onDrop != null) {
    final fn = ((JSAny? event) {
      var dropped = const <ReleaseDroppedFile>[];
      if (event != null && event.isA<JSObject>()) {
        final de = _DomDragEvent._(event as JSObject);
        de.preventDefault();
        de.stopPropagation();
        dropped = _extractDroppedFiles(de);
      }
      onDrop(dropped);
    }).toJS;
    div.addEventListener('drop'.toJS, fn);
    listeners.add(('drop'.toJS, fn));
  }

  body.appendChild(div);
  return _BrowserOverlayHandle(div, listeners);
}
