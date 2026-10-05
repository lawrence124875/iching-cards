import 'package:flutter/material.dart';

/// 謙卦主題配色（HANDOFF §6.1）：天玄地黃，玄底黃點綴。
class QianColors {
  QianColors._();

  static const ink = Color(0xFF1C1B22); // 玄墨：主背景
  static const inkCard = Color(0xFF26242E); // 玄灰：卡片底
  static const earth = Color(0xFFC9A45C); // 地黃：主色
  static const rice = Color(0xFFD8B56A); // 稻金：點綴
  static const mountain = Color(0xFF7E6A52); // 山褐：輔色
  static const text = Color(0xFFE8D9B0); // 淡金：主文字
  static const textSub = Color(0xFFA89F8C); // 灰穗：次文字
  static const paper = Color(0xFFEDE4D0); // 紙白：淺色模式底
}

/// 字體：卦名、經文、標題用宋體；白話解讀與介面用黑體（HANDOFF §6.2）。
/// 0.1.0+17 起打包思源宋體／黑體子集（HANDOFF §15）；子集外的罕用字由系統字體補上。
const kSerif = 'NotoSerifTC';
const kSans = 'NotoSansTC';

/// 簡中（2026-10-05）：繁中字型沒有的簡體字由思源 SC 子集補上（同一設計，字形一致），
/// 子集只含 TC 缺的字（scripts/build_fonts.py）。每個指定 kSerif／kSans 的地方都要帶對應的 fallback，
/// 否則 copyWith 會沿用黑體的 fallback。
const kSerifFallback = ['NotoSerifSC'];
const kSansFallback = ['NotoSansSC'];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: QianColors.earth,
    brightness: Brightness.dark,
  ).copyWith(
    primary: QianColors.earth,
    onPrimary: QianColors.ink,
    secondary: QianColors.mountain,
    surface: QianColors.ink,
    onSurface: QianColors.text,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: kSans,
    fontFamilyFallback: kSansFallback,
    colorScheme: scheme,
    scaffoldBackgroundColor: QianColors.ink,
    dividerColor: QianColors.mountain,
    appBarTheme: const AppBarTheme(
      backgroundColor: QianColors.ink,
      foregroundColor: QianColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, fontSize: 19, color: QianColors.text, letterSpacing: 2),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, fontSize: 40, height: 1.2, letterSpacing: 8, color: QianColors.text),
      headlineSmall: TextStyle(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, fontSize: 24, height: 1.4, letterSpacing: 2, color: QianColors.text),
      titleMedium: TextStyle(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, fontSize: 17, height: 1.5, letterSpacing: 1, color: QianColors.rice),
      bodyLarge: TextStyle(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, fontSize: 17, height: 1.9, color: QianColors.text),
      bodyMedium: TextStyle(fontSize: 15.5, height: 1.8, color: QianColors.text),
      bodySmall: TextStyle(fontSize: 13, height: 1.6, color: QianColors.textSub),
      labelLarge: TextStyle(fontSize: 16, letterSpacing: 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QianColors.earth,
        foregroundColor: QianColors.ink,
        minimumSize: const Size(200, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: QianColors.rice,
        side: const BorderSide(color: QianColors.mountain),
        minimumSize: const Size(160, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: QianColors.textSub),
    ),
  );
}
