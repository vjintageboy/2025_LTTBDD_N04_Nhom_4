import 'dart:convert';
import 'package:flutter/widgets.dart';

/// Returns an [ImageProvider] for a stored image string that is either a remote
/// URL (http/https) or a base64-encoded image. Mirrors how this app stores
/// images: base64 in a text column, or an external URL.
///
/// Returns null when the string is empty or is not decodable base64 (e.g. a
/// legacy storage path), so callers fall back to their placeholder instead of
/// throwing out of `build`.
ImageProvider? imageProviderFromSource(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
  }
  try {
    return MemoryImage(base64Decode(source));
  } on FormatException {
    return null;
  }
}
