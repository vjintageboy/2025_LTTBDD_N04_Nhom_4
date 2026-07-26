import 'dart:convert';
import 'package:flutter/widgets.dart';

/// Returns an [ImageProvider] for a stored image string that is either a remote
/// URL (http/https) or a base64-encoded image. Mirrors how this app stores
/// images: base64 in a text column, or an external URL.
ImageProvider imageProviderFromSource(String source) {
  final isRemote =
      source.startsWith('http://') || source.startsWith('https://');
  return isRemote ? NetworkImage(source) : MemoryImage(base64Decode(source));
}
