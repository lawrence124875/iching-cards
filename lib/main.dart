import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/services.dart';
import 'core/audio/just_audio_playback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 卦卡為 9:16 直式設計，固定直向（HANDOFF §11.2）。
  // Android 另在 AndroidManifest 設定 screenOrientation，避免啟動瞬間閃成橫向。
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 呼吸音景的背景播放與通知控制；失敗不影響其他功能
  await JustAudioPlayback.initBackground();
  final services = Services.standard();
  await services.reminders.init(); // 不拋例外；失敗時提醒功能停用
  runApp(AppServices(services: services, child: const IchingApp()));
}
