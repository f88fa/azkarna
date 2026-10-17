import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failures.dart';

/// Loads and decodes JSON files bundled with the app.
class JsonAssetService {
  JsonAssetService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<Object?> load(String assetPath) async {
    try {
      final raw = await _bundle.loadString(assetPath);
      return jsonDecode(raw);
    } on FormatException {
      throw CacheFailure('Corrupted asset: $assetPath');
    } on FlutterError {
      throw CacheFailure('Missing asset: $assetPath');
    }
  }
}

final jsonAssetServiceProvider = Provider<JsonAssetService>(
  (ref) => JsonAssetService(),
);
