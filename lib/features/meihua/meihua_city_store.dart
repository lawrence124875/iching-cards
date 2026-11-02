import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/meihua/solar_time.dart';

/// 時辰校正選的城市（選用，預設關閉），存在 App 文件資料夾的 `meihua_city.txt`。
class MeihuaCityStore {
  MeihuaCityStore._();

  static Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/meihua_city.txt');

  static Future<MeihuaCity?> load() async {
    try {
      final f = await _file();
      return await f.exists() ? MeihuaCities.byId((await f.readAsString()).trim()) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(MeihuaCity? city) async {
    try {
      final f = await _file();
      if (city == null) {
        if (await f.exists()) await f.delete();
      } else {
        await f.writeAsString(city.id);
      }
    } catch (_) {}
  }
}
