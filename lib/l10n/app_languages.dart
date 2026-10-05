import 'dart:ui';

/// App 支援的語言（HANDOFF §16）。
///
/// - 介面文字放在 lib/l10n/app_<語言>.arb；解讀內容放在私人 repo iching-content/<contentFolder>/。
/// - **上線原則（§12）**：內容沒有完整翻譯的語言不開放。只有 [contentReady] 為 true 的語言
///   會出現在 [enabled]；其餘語言即使有 ARB，使用者也看不到。
/// - 新增語言：① 新增 app_xx.arb ② 在 [all] 加一行（contentReady 先填 false）
///   ③ 內容寫完、CI 匯入該語言資料夾後改成 true。
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.locale,
    required this.contentFolder,
    required this.contentReady,
  });

  /// 與內容資料夾、術語表一致的代碼：zh-Hant、en、zh-Hans、ja…
  final String code;

  /// 交給 MaterialApp 的 Locale。繁中一定要帶 scriptCode Hant，
  /// 否則 Material 內建文字（日期選擇器等）會用簡體。
  final Locale locale;

  /// 內容資料夾（assets/content/<contentFolder>/NN.json）。
  final String contentFolder;

  /// 解讀內容是否已完整翻譯。
  final bool contentReady;

  @override
  String toString() => code;
}

class AppLanguages {
  AppLanguages._();

  static const zhHant = AppLanguage(
    code: 'zh-Hant',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    contentFolder: 'zh-Hant',
    contentReady: true,
  );

  static const en = AppLanguage(
    code: 'en',
    locale: Locale('en'),
    contentFolder: 'en',
    contentReady: true, // 2026-10-05 英文 64 卦完成（§22）
  );

  static const zhHans = AppLanguage(
    code: 'zh-Hans',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    contentFolder: 'zh-Hans',
    contentReady: true, // 2026-10-05 由繁中轉出（iching-content tools/to_hans.py，§19.2 第 5 項）
  );

  static const ja = AppLanguage(
    code: 'ja',
    locale: Locale('ja'),
    contentFolder: 'ja',
    contentReady: false, // 2026-10-05 介面完成，64 卦撰寫中（§22、iching-content ja/README.md）
  );

  /// 已有介面翻譯（ARB）的語言。順序無意義。
  static const all = [zhHant, en, zhHans, ja];

  /// 只看介面不開放內容的測試用開關：建置時加 --dart-define=FORCE_LANG=en，
  /// 不論手機語言一律用該語言介面（內容仍退回繁中）。正式版不加。
  static const _forced = String.fromEnvironment('FORCE_LANG');

  static AppLanguage? byCode(String code) {
    for (final l in all) {
      if (l.code == code) return l;
    }
    return null;
  }

  static AppLanguage? get forced => _forced.isEmpty ? null : byCode(_forced);

  /// 使用者看得到的語言。
  static List<AppLanguage> get enabled {
    final f = forced;
    return [
      for (final l in all)
        if (l.contentReady || l == f) l,
    ];
  }

  /// 手機設定的語言清單（依偏好順序）→ App 使用的語言。
  ///
  /// - 中文：明確標示簡體（Hans），或地區為中國、新加坡、馬來西亞時優先簡體，其餘優先繁體；
  ///   沒有開放的那一種就用另一種（簡體使用者看繁體，比看英文好）。
  /// - 其他語言照語言代碼比對；都對不上時用英文（若已開放），否則繁中。
  static AppLanguage resolve(Iterable<Locale> device, {List<AppLanguage>? available}) {
    final f = available == null ? forced : null;
    if (f != null) return f;
    final langs = available ?? enabled;
    AppLanguage? find(String code) {
      for (final l in langs) {
        if (l.code == code) return l;
      }
      return null;
    }

    for (final d in device) {
      if (d.languageCode == 'zh') {
        final hans = d.scriptCode == 'Hans' ||
            (d.scriptCode == null && const {'CN', 'SG', 'MY'}.contains(d.countryCode));
        final hit = hans ? (find('zh-Hans') ?? find('zh-Hant')) : (find('zh-Hant') ?? find('zh-Hans'));
        if (hit != null) return hit;
        continue;
      }
      final hit = find(d.languageCode);
      if (hit != null) return hit;
    }
    return find('en') ?? find('zh-Hant') ?? langs.first;
  }
}
