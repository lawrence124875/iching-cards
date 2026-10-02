import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'content_source.dart';
import 'hexagram_content.dart';

/// 從 App 內資產讀取：assets/content/<語言>/NN.json、assets/cards/NN.webp。
/// 這些檔案由 CI 從私人 repo 匯入（scripts/import_content.sh）。
class AssetContentSource implements ContentSource {
  AssetContentSource({required this.locale, AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final String locale;
  final AssetBundle _bundle;
  final Map<int, HexagramContent?> _cache = {};
  Future<Set<String>>? _assets;

  Future<Set<String>> _assetList() => _assets ??= AssetManifest.loadFromAssetBundle(_bundle)
      .then((m) => m.listAssets().toSet())
      .catchError((Object _) => <String>{});

  static String _code(int n) => n.toString().padLeft(2, '0');

  @override
  Future<HexagramContent?> hexagram(int number) async {
    if (_cache.containsKey(number)) return _cache[number];
    final path = 'assets/content/$locale/${_code(number)}.json';
    HexagramContent? result;
    if ((await _assetList()).contains(path)) {
      try {
        final raw = await _bundle.loadString(path);
        result = HexagramContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('內容解析失敗：$path（$e）');
      }
    }
    return _cache[number] = result;
  }

  @override
  Future<ImageProvider?> cardArt(int number) async {
    final path = 'assets/cards/${_code(number)}.webp';
    return (await _assetList()).contains(path) ? AssetImage(path, bundle: _bundle) : null;
  }

  @override
  Future<Uint8List?> cardArtBytes(int number) async {
    final path = 'assets/cards/${_code(number)}.webp';
    if (!(await _assetList()).contains(path)) return null;
    final data = await _bundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
