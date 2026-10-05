import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/l10n.dart';
import 'feature_registry.dart';
import 'home_page.dart';
import 'services.dart';
import 'theme.dart';

class IchingApp extends StatefulWidget {
  const IchingApp({super.key});

  @override
  State<IchingApp> createState() => _IchingAppState();
}

class _IchingAppState extends State<IchingApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _taps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_taps != null) return;
    final reminders = AppServices.of(context).reminders;
    _taps = reminders.taps.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = reminders.takeLaunchPayload();
      if (p != null) _open(p);
    });
  }

  /// 通知帶來的 payload 交給認得它的功能（例如卦記開啟該筆紀錄）。
  void _open(String payload) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    for (final f in registeredFeatures) {
      if (f.openPayload?.call(nav, payload) ?? false) return;
    }
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      // 介面語言（HANDOFF §16）：只開放內容已完整翻譯的語言（AppLanguages.enabled），
      // 依手機語言設定選擇；同步給 L10n.language，讓通知等沒有 context 的地方用同一語言。
      supportedLocales: [for (final l in AppLanguages.enabled) l.locale],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (locales, _) {
        final lang = AppLanguages.resolve(locales ?? const []);
        L10n.language = lang;
        return lang.locale;
      },
      theme: buildTheme(),
      // 字族依介面語言（日文用思源 JP，HANDOFF §15）：Localizations 決定語言後才知道，所以在 builder 換主題。
      builder: (context, child) {
        final fonts = AppFonts.forLanguage(Localizations.localeOf(context).languageCode);
        AppFonts.current = fonts;
        return Theme(data: buildTheme(fonts), child: child!);
      },
      home: const HomePage(),
    );
  }
}
