import 'package:flutter/material.dart';

import 'home_page.dart';
import 'theme.dart';

class IchingApp extends StatelessWidget {
  const IchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '謙卦',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomePage(),
    );
  }
}
