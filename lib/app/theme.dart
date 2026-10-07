import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///
/// 依介面語言選字族（[AppFonts.current]，MaterialApp 的 builder 依語言設定）：
/// - 中文、英文…：思源 TC 為主，簡體字由 SC 子集補（只含 TC 缺的字，2026-10-05）。
/// - 日文（2026-10-05）：思源 JP 為主（日本字形），JP 子集沒有的字再由 TC、SC 補。
/// - 韓文（2026-10-05）：思源 KR 為主（韓文音節與韓式漢字字形），其餘同日文。
/// 每個指定 [kSerif]／[kSans] 的地方都要帶對應的 fallback，否則 copyWith 會沿用黑體的 fallback。
/// 經文的漢字原文（非中文語言時顯示在譯文上方）一律用 [AppFonts.chinese]：那是中文經文，用中文字形。
class AppFonts {
  const AppFonts._(this.serif, this.sans, this.serifFallback, this.sansFallback);

  final String serif;
  final String sans;
  final List<String> serifFallback;
  final List<String> sansFallback;

  static const chinese = AppFonts._('NotoSerifTC', 'NotoSansTC', ['NotoSerifSC'], ['NotoSansSC']);
  static const japanese =
      AppFonts._('NotoSerifJP', 'NotoSansJP', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC']);
  static const korean =
      AppFonts._('NotoSerifKR', 'NotoSansKR', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC']);
  static const thai =
      AppFonts._('NotoSerifThai', 'NotoSansThai', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC']);

  /// 語言代碼（Locale.languageCode）→ 字族組合。
  static AppFonts forLanguage(String languageCode) => switch (languageCode) {
        'ja' => japanese,
        'ko' => korean,
        'th' => thai,
        _ => chinese,
      };

  /// 目前介面語言的字族（app.dart 的 builder 設定；沒有 context 的地方也能用）。
  static AppFonts current = chinese;
}

String get kSerif => AppFonts.current.serif;
String get kSans => AppFonts.current.sans;
List<String> get kSerifFallback => AppFonts.current.serifFallback;
List<String> get kSansFallback => AppFonts.current.sansFallback;

/// 系統列（無邊框畫面）：透明、淺色圖示（玄底），導覽列不加系統的半透明遮罩。
/// main() 開機時套用；AppBar 也用同一份，進出各頁不會閃動。
const qianSystemBars = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

ThemeData buildTheme([AppFonts fonts = AppFonts.chinese]) {
  final serif = fonts.serif, serifFallback = fonts.serifFallback;
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
    fontFamily: fonts.sans,
    fontFamilyFallback: fonts.sansFallback,
    colorScheme: scheme,
    scaffoldBackgroundColor: QianColors.ink,
    dividerColor: QianColors.mountain,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: qianSystemBars,
      backgroundColor: QianColors.ink,
      foregroundColor: QianColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 19, color: QianColors.text, letterSpacing: 2),
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 40, height: 1.2, letterSpacing: 8, color: QianColors.text),
      headlineSmall: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 24, height: 1.4, letterSpacing: 2, color: QianColors.text),
      titleMedium: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 17, height: 1.5, letterSpacing: 1, color: QianColors.rice),
      bodyLarge: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 17, height: 1.9, color: QianColors.text),
      bodyMedium: const TextStyle(fontSize: 15.5, height: 1.8, color: QianColors.text),
      bodySmall: const TextStyle(fontSize: 13, height: 1.6, color: QianColors.textSub),
      labelLarge: const TextStyle(fontSize: 16, letterSpacing: 2),
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
