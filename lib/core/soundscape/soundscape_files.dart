import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import 'session_renderer.dart';

/// 準備練習音檔：在背景 isolate 合成（不卡畫面），存到暫存資料夾。
/// 同一組設定直接沿用上次的檔案；換設定時刪掉舊檔，只留一個（5 分鐘約 13 MB）。
abstract class SoundscapeFiles {
  Future<String> prepare(SessionSpec spec);
}

class CachedSoundscapeFiles implements SoundscapeFiles {
  static const _prefix = 'breath_';

  @override
  Future<String> prepare(SessionSpec spec) async {
    final dir = (await getTemporaryDirectory()).path;
    final path = '$dir/$_prefix${spec.key}.wav';
    final file = File(path);
    if (await file.exists() && await file.length() > 44) return path;

    await for (final e in Directory(dir).list()) {
      final name = e.uri.pathSegments.isEmpty ? '' : e.uri.pathSegments.last;
      if (e is File && name.startsWith(_prefix)) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
    await _renderInBackground(spec, path);
    return path;
  }
}

// 頂層函式：送進 isolate 的閉包只帶 spec 與 path，不夾帶其他物件。
Future<void> _renderInBackground(SessionSpec spec, String path) =>
    Isolate.run(() => renderSessionToFile(spec, path));
