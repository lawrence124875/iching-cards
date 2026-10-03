import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/services.dart';
import 'core/audio/just_audio_playback.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  // 卦卡為 9:16 直式設計，固定直向（HANDOFF §11.2）。
  // Android 另在 AndroidManifest 設定 screenOrientation，避免啟動瞬間閃成橫向。
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 呼吸音景的背景播放與通知控制；失敗不影響其他功能
  // 通知類別名稱跟著手機語言（L10n 在 MaterialApp 決定語言前先依手機設定判斷）
  final l = L10n.current;
  await JustAudioPlayback.initBackground(channelName: l.breathChannelName, album: l.appTitle);
  final services = Services.standard();
  await services.reminders.init(); // 不拋例外；失敗時提醒功能停用
  runApp(AppServices(services: services, child: const IchingApp()));
}

/// 思源黑體／宋體為 SIL OFL 1.1，散布時須附授權全文（顯示於系統授權頁）。
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final name in ['NotoSansTC', 'NotoSerifTC']) {
      final text = await rootBundle.loadString('assets/licenses/$name-OFL.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
