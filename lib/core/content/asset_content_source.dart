import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'content_source.dart';
import 'hexagram_content.dart';

/// 從 App 內資產讀取：assets/content/<語言資料夾>/NN.json、assets/cards/NN.webp（圖不分語言）。
/// 這些檔案由 CI 從私人 repo 匯入（scripts/import_content.sh）。
/// [folder] 每次讀取時取值，App 語言改變後自動讀對應語言（HANDOFF §16）。
class AssetContentSource implements ContentSource {
  AssetContentSource({required this.folder, AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final String Function() folder;
  final AssetBundle _bundle;
  final Map<String, HexagramContent?> _cache = {};
  Future<Set<String>>? _assets;

  Future<Set<String>> _assetList() => _assets ??= AssetManifest.loadFromAssetBundle(_bundle)
      .then((m) => m.listAssets().toSet())
      .catchError((Object _) => <String>{});

  static String _code(int n) => n.toString().padLeft(2, '0');

  @override
  Future<HexagramContent?> hexagram(int number) async {
    final path = 'assets/content/${folder()}/${_code(number)}.json';
    if (_cache.containsKey(path)) return _cache[path];
    HexagramContent? result;
    if ((await _assetList()).contains(path)) {
      try {
        final raw = await _bundle.loadString(path);
        result = HexagramContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('內容解析失敗：$path（$e）');
      }
    }
    return _cache[path] = result;
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
