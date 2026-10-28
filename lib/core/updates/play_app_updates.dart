import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_updates.dart';

/// Google Play In-App Updates（彈性更新：背景下載、使用者決定何時重新啟動）。
/// **唯一 import in_app_update 的檔案**。只在從 Play 安裝的 Android 版有效，其他情況一律當作沒有新版。
class PlayAppUpdates implements AppUpdates {
  const PlayAppUpdates();

  @override
  Future<bool> available() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 10));
      return info.updateAvailability == UpdateAvailability.updateAvailable && info.flexibleUpdateAllowed;
    } catch (e) {
      debugPrint('檢查更新失敗：$e'); // 側載、除錯版、沒有 Play 時都會失敗，不影響使用
      return false;
    }
  }

  @override
  Future<bool> download() async {
    try {
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> install() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {}
  }
}
