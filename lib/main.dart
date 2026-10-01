import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 卦卡為 9:16 直式設計，固定直向（HANDOFF §11.2）。
  // Android 另在 AndroidManifest 設定 screenOrientation，避免啟動瞬間閃成橫向。
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(AppServices(services: Services.standard(), child: const IchingApp()));
}
