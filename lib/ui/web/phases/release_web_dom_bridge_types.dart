import 'dart:typed_data';

/// Cross-platform representation of a DOM-dropped file in `neom_releases`.
class ReleaseDroppedFile {
  final String name;
  final int size;
  final Object handle;

  const ReleaseDroppedFile({
    required this.name,
    required this.size,
    required this.handle,
  });
}

/// Handle for a positioned invisible HTML drop overlay `<div>`.
abstract class ReleaseDropOverlayHandle {
  void reposition({
    required double left,
    required double top,
    required double width,
    required double height,
  });

  void dispose();
}

const int kMaxReleaseCoverBytes = 20 * 1024 * 1024; // 20 MiB
const int kMaxReleaseMediaBytes = 150 * 1024 * 1024; // 150 MiB
const int kMaxReleasePdfPreviewBytes = 100 * 1024 * 1024; // 100 MiB
const int kMaxDroppedReleaseFiles = 64;

typedef ReleaseBytesCallback = void Function(Uint8List bytes);

final RegExp _kUnsafeDroppedNameChars = RegExp(
  r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
);
final RegExp _kWindowsUnsafeFileChars = RegExp(r'[:*?"<>|]');
final RegExp _kWindowsReservedStem = RegExp(
  r'^(?:con|prn|aux|nul|com[1-9]|lpt[1-9])$',
  caseSensitive: false,
);
const List<String> _kActivePdfPolyglotTokens = <String>[
  '<!doctype',
  '<html',
  '<head',
  '<body',
  '<script',
  '<svg',
  '<?xml',
  '<iframe',
  '<object',
  '<embed',
  'javascript:',
];

String _truncateUtf16Safe(String input, int maxUnits) {
  if (maxUnits <= 0 || input.isEmpty) return '';
  if (input.length <= maxUnits) return input;
  var end = maxUnits;
  final lastUnit = input.codeUnitAt(end - 1);
  if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
    end -= 1;
  }
  return end <= 0 ? '' : input.substring(0, end);
}

/// Sanitizes a browser drag-and-drop filename against BiDi spoofing, C0/C1/NEL/LS/PS
/// controls, Windows reserved device stems, and path separators.
String sanitizeDroppedReleaseFileName(String rawName) {
  var base = rawName
      .replaceAll(_kUnsafeDroppedNameChars, '')
      .split(RegExp(r'[/\\]+'))
      .last
      .replaceAll(_kWindowsUnsafeFileChars, '_')
      .replaceAll('..', '.')
      .trim();
  while (base.startsWith('.')) {
    base = base.substring(1).trimLeft();
  }
  while (base.endsWith('.')) {
    base = base.substring(0, base.length - 1).trimRight();
  }
  if (base.isEmpty || base == '.' || base == '..') {
    return 'unnamed_file';
  }
  final dotIdx = base.indexOf('.');
  final stem = dotIdx > 0 ? base.substring(0, dotIdx) : base;
  if (_kWindowsReservedStem.hasMatch(stem)) {
    base = '_$base';
  }
  if (base.length <= 255) return base;
  final lastDot = base.lastIndexOf('.');
  if (lastDot > 0 && base.length - lastDot <= 16) {
    final ext = base.substring(lastDot);
    return '${_truncateUtf16Safe(base.substring(0, lastDot), 255 - ext.length)}$ext';
  }
  return _truncateUtf16Safe(base, 255);
}

/// Validates that [bytes] represents a bounded PDF document (`%PDF-` signature
/// within the first 1024 bytes per ISO 32000-1) and contains no active HTML/SVG/XML/script
/// polyglot markup in the inspected header window.
bool hasValidPdfSignature(
  Uint8List bytes, {
  int maxBytes = kMaxReleasePdfPreviewBytes,
}) {
  if (!maxBytes.isFinite ||
      maxBytes <= 0 ||
      bytes.length < 5 ||
      bytes.length > maxBytes) {
    return false;
  }
  final int scanEnd = bytes.length < 1024 ? bytes.length : 1024;
  // Skip optional UTF-8 BOM + leading whitespace/NULs before checking '<'.
  int firstNonWs = 0;
  if (scanEnd >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    firstNonWs = 3;
  }
  while (firstNonWs < scanEnd &&
      (bytes[firstNonWs] == 0x00 ||
          bytes[firstNonWs] == 0x20 ||
          bytes[firstNonWs] == 0x09 ||
          bytes[firstNonWs] == 0x0A ||
          bytes[firstNonWs] == 0x0C ||
          bytes[firstNonWs] == 0x0D)) {
    firstNonWs++;
  }
  if (firstNonWs < scanEnd && bytes[firstNonWs] == 0x3C /* '<' */) {
    return false;
  }
  var foundPdfMagic = false;
  for (int i = 0; i <= scanEnd - 5; i++) {
    if (bytes[i] == 0x25 &&
        bytes[i + 1] == 0x50 &&
        bytes[i + 2] == 0x44 &&
        bytes[i + 3] == 0x46 &&
        bytes[i + 4] == 0x2D) {
      foundPdfMagic = true;
      break;
    }
  }
  if (!foundPdfMagic) return false;

  // Reject `%PDF-` + HTML/SVG/XML/script polyglots within the header window.
  final sb = StringBuffer();
  for (int i = 0; i < scanEnd; i++) {
    final b = bytes[i];
    if (b == 0) continue;
    if (b >= 0x41 && b <= 0x5A) {
      sb.writeCharCode(b + 0x20);
    } else if (b >= 0x20 && b <= 0x7E) {
      sb.writeCharCode(b);
    } else {
      sb.writeCharCode(0x20);
    }
  }
  final normalizedHead = sb.toString();
  for (final token in _kActivePdfPolyglotTokens) {
    if (normalizedHead.contains(token)) {
      return false;
    }
  }
  return true;
}
