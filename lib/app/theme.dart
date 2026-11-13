import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// 謙卦主題配色（REFERENCE §6.1）：天玄地黃，玄底黃點綴。
///
/// 0.11.0 起有深色（原玄底）與淺色（宣紙底）兩組，設定頁「外觀」選跟隨系統／淺色／深色（[ThemePref]）。
/// 色名沿用深色語意（ink＝主背景、text＝主文字…），值依 [dark] 切換；app.dart 的 builder 設定 [dark]，
/// 切換時整棵樹重建、重繪（[rebuildForTheme]）。因為是 getter，不能放在 const 運算式裡。
/// 牌面圖、古圖、圖片上的文字不跟著換（[onImage]、[onGold] 固定）。
class QianColors {
  QianColors._();

  /// 目前是否深色（app.dart builder 依設定與系統亮度決定）。
  static bool dark = true;

  static Color get ink => dark ? const Color(0xFF1C1B22) : const Color(0xFFF3ECDD); // 玄墨／宣紙：主背景
  static Color get inkCard => dark ? const Color(0xFF26242E) : const Color(0xFFFBF7EE); // 玄灰／素白：卡片底
  static Color get earth => dark ? const Color(0xFFC9A45C) : const Color(0xFF946C2A); // 地黃：主色
  static Color get rice => dark ? const Color(0xFFD8B56A) : const Color(0xFF85601F); // 稻金：點綴
  static Color get mountain => dark ? const Color(0xFF7E6A52) : const Color(0xFFA8957B); // 山褐：輔色、框線
  static Color get text => dark ? const Color(0xFFE8D9B0) : const Color(0xFF2E2922); // 淡金／墨：主文字
  static Color get textSub => dark ? const Color(0xFFA89F8C) : const Color(0xFF6E6555); // 灰穗：次文字
  static const paper = Color(0xFFEDE4D0); // 紙白

  /// 金色按鈕、金色晶片上的字（深淺模式都用玄墨）。
  static const onGold = Color(0xFF1C1B22);

  /// 圖片（牌面、呼吸音景背景圖）上的字：一律淡金加黑影。
  static const onImage = Color(0xFFE8D9B0);
}

/// 主題切換後整個畫面重建與重繪：QianColors 是全域值，不會自動通知已建好的元件與 CustomPainter。
void rebuildForTheme(Element root) {
  void rebuild(Element e) {
    e.markNeedsBuild();
    e.visitChildren(rebuild);
  }

  root.visitChildren(rebuild);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    void repaint(RenderObject r) {
      r.markNeedsPaint();
      r.visitChildren(repaint);
    }

    for (final v in RendererBinding.instance.renderViews) {
      repaint(v);
    }
  });
}

/// 字體：卦名、經文、標題用宋體；白話解讀與介面用黑體（REFERENCE §6.2）。
/// 0.1.0+17 起打包思源宋體／黑體子集（REFERENCE §15）；子集外的罕用字由系統字體補上。
///
/// 依介面語言選字族（[AppFonts.current]，MaterialApp 的 builder 依語言設定）：
/// - 中文、英文…：思源 TC 為主，簡體字由 SC 子集補（只含 TC 缺的字，2026-10-05）。
/// - 日文（2026-10-05）：思源 JP 為主（日本字形），JP 子集沒有的字再由 TC、SC 補。
/// - 韓文（2026-10-05）：思源 KR 為主（韓文音節與韓式漢字字形），其餘同日文。
/// 每個指定 [kSerif]／[kSans] 的地方都要帶對應的 fallback，否則 copyWith 會沿用黑體的 fallback。
/// 經文的漢字原文（非中文語言時顯示在譯文上方）一律用 [AppFonts.chinese]：那是中文經文，用中文字形。
class AppFonts {
  const AppFonts._(this.serif, this.sans, this.serifFallback, this.sansFallback, {this.tracking = true});

  final String serif;
  final String sans;
  final List<String> serifFallback;
  final List<String> sansFallback;

  /// 是否加字距（[tracking]）。泰文字母間加距會把上方的母音、聲調符號拆離字母（例「อี้จิง」），
  /// 擲錢頁、首頁副標都會出現，所以泰文一律不加（2026-10-07 商店截圖發現）。
  final bool tracking;

  static const chinese = AppFonts._('NotoSerifTC', 'NotoSansTC', ['NotoSerifSC'], ['NotoSansSC']);
  static const japanese =
      AppFonts._('NotoSerifJP', 'NotoSansJP', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC']);
  static const korean =
      AppFonts._('NotoSerifKR', 'NotoSansKR', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC']);
  static const thai =
      AppFonts._('NotoSerifThai', 'NotoSansThai', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC'],
          tracking: false);
  /// 阿拉伯文（2026-10-07）：內文 Noto Naskh Arabic（書本常用的 Naskh 體）、介面 Noto Sans Arabic；
  /// 拼音與外文原名的拉丁字母由 TC 補。版面方向（RTL）由 MaterialApp 依 ar locale 自動決定。
  /// 不加字距：阿拉伯字母是連寫體，字距會把字母之間的連筆拆開。
  static const arabic = AppFonts._(
      'NotoNaskhArabic', 'NotoSansArabic', ['NotoSerifTC', 'NotoSerifSC'], ['NotoSansTC', 'NotoSansSC'],
      tracking: false);

  /// 語言代碼（Locale.languageCode）→ 字族組合。
  static AppFonts forLanguage(String languageCode) => switch (languageCode) {
        'ja' => japanese,
        'ko' => korean,
        'th' => thai,
        'ar' => arabic,
        _ => chinese,
      };

  /// 目前介面語言的字族（app.dart 的 builder 設定；沒有 context 的地方也能用）。
  static AppFonts current = chinese;
}

String get kSerif => AppFonts.current.serif;
String get kSans => AppFonts.current.sans;
List<String> get kSerifFallback => AppFonts.current.serifFallback;
List<String> get kSansFallback => AppFonts.current.sansFallback;

/// 系統列（無邊框畫面）：透明、深色模式用淺色圖示（玄底），導覽列不加系統的半透明遮罩。
/// main() 開機時套用；AppBar 也用同一份，進出各頁不會閃動。
/// 淺色模式改深色圖示。
SystemUiOverlayStyle get qianSystemBars => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: QianColors.dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: QianColors.dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: QianColors.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

/// 字距：寫 `letterSpacing: tracking(2)`，不加字距的文字（泰文）回傳 0。
double tracking(double value) => AppFonts.current.tracking ? value : 0;

ThemeData buildTheme([AppFonts fonts = AppFonts.chinese]) {
  final brightness = QianColors.dark ? Brightness.dark : Brightness.light;
  double ls(double value) => fonts.tracking ? value : 0;
  final serif = fonts.serif, serifFallback = fonts.serifFallback;
  final scheme = ColorScheme.fromSeed(
    seedColor: QianColors.earth,
    brightness: brightness,
  ).copyWith(
    primary: QianColors.earth,
    onPrimary: QianColors.onGold,
    secondary: QianColors.mountain,
    surface: QianColors.ink,
    onSurface: QianColors.text,
    onSurfaceVariant: QianColors.textSub,
    surfaceContainerHighest: QianColors.inkCard,
    surfaceContainerHigh: QianColors.inkCard,
    surfaceContainer: QianColors.inkCard,
    surfaceContainerLow: QianColors.inkCard,
    outline: QianColors.mountain,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
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
      titleTextStyle: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 19, color: QianColors.text, letterSpacing: ls(2)),
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 40, height: 1.2, letterSpacing: ls(8), color: QianColors.text),
      headlineSmall: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 24, height: 1.4, letterSpacing: ls(2), color: QianColors.text),
      titleMedium: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 17, height: 1.5, letterSpacing: ls(1), color: QianColors.rice),
      bodyLarge: TextStyle(fontFamily: serif, fontFamilyFallback: serifFallback, fontSize: 17, height: 1.9, color: QianColors.text),
      bodyMedium: TextStyle(fontSize: 15.5, height: 1.8, color: QianColors.text),
      bodySmall: TextStyle(fontSize: 13, height: 1.6, color: QianColors.textSub),
      labelLarge: TextStyle(fontSize: 16, letterSpacing: ls(2)),
    ),
    // 0.6.7+69：全 app 按鈕統一成首頁樣式（膠囊形；主按鈕金色漸層、次按鈕深色漸層底＋半透明金框）。
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: QianColors.onGold,
        disabledForegroundColor: QianColors.onGold.withValues(alpha: 0.6),
        shadowColor: Colors.transparent,
        elevation: 0,
        minimumSize: const Size(200, 52),
        shape: const StadiumBorder(),
        textStyle: TextStyle(fontSize: 16, letterSpacing: ls(2), fontWeight: FontWeight.w600),
      ).copyWith(
        backgroundBuilder: (context, states, child) => DecoratedBox(
          decoration: qianPrimaryButtonDecoration(enabled: !states.contains(WidgetState.disabled)),
          child: child,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: QianColors.rice,
        disabledForegroundColor: QianColors.textSub.withValues(alpha: 0.6),
        side: BorderSide(color: QianColors.earth.withValues(alpha: 0.55)),
        minimumSize: const Size(160, 48),
        shape: const StadiumBorder(),
        textStyle: TextStyle(fontSize: 16, letterSpacing: ls(2), fontWeight: FontWeight.w500),
      ).copyWith(
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
            color: QianColors.earth.withValues(alpha: states.contains(WidgetState.disabled) ? 0.25 : 0.55))),
        backgroundBuilder: (context, states, child) => DecoratedBox(
          decoration: qianSecondaryButtonDecoration(),
          child: child,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: QianColors.textSub),
    ),
  );
}


/// 主按鈕底：金色漸層＋柔光（首頁 0.6.6+68 定案；filledButtonTheme 與首頁共用）。
BoxDecoration qianPrimaryButtonDecoration({bool enabled = true, BorderRadius? radius}) => BoxDecoration(
      borderRadius: radius ?? BorderRadius.circular(999),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          for (final c in const [Color(0xFFEACB86), Color(0xFFC9A45C), Color(0xFFAE8641)])
            enabled ? c : c.withValues(alpha: 0.35),
        ],
      ),
      boxShadow: enabled
          ? [BoxShadow(color: QianColors.earth.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 4))]
          : null,
    );

/// 次要按鈕底：深色漸層（框線另由 outlinedButtonTheme 的 side 或 [border] 畫）。
BoxDecoration qianSecondaryButtonDecoration({BorderRadius? radius, BoxBorder? border}) => BoxDecoration(
      borderRadius: radius ?? BorderRadius.circular(999),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [QianColors.dark ? const Color(0xFF2E2B36) : const Color(0xFFFFFDF8), QianColors.inkCard],
      ),
      border: border,
    );
