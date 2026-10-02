import 'dart:async';

import 'package:flutter/material.dart';

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
      title: '謙卦',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomePage(),
    );
  }
}
