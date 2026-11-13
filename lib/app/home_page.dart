import 'package:flutter/material.dart';

import '../core/iching/hexagram_table.dart';
import '../core/journal/journal_entry.dart';
import '../features/feedback/feedback_page.dart';
import '../features/intro/intro_page.dart';
import '../features/journal/journal_entry_page.dart';
import '../features/share/share.dart';
import '../shared/format.dart';
import '../shared/premium/ad_banner.dart';
import '../shared/premium/paywall_page.dart';

import '../shared/widgets/adaptive_layout.dart';
import '../shared/widgets/card_back.dart';
import '../l10n/l10n.dart';
import 'feature_registry.dart';
import 'services.dart';
import 'settings_page.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 從功能頁返回時加一，讓「今日狀態」重新讀取額度與最近一筆卦記。
  int _refresh = 0;

  Future<void> _push(WidgetBuilder builder) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    if (mounted) setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final s = AppServices.of(context);
    final features = activeFeatures(s.flags).toList();
    final primary = features.where((f) => f.placement == FeaturePlacement.primary && f.builder != null);
    final secondary = features.where((f) => f.placement == FeaturePlacement.secondary && f.builder != null);

    void open(AppFeature f) => _push(f.builder!);

    final brand = [
      const SizedBox(
        width: 168,
        child: AspectRatio(aspectRatio: 0.62, child: CardBack()),
      ),
      const SizedBox(height: 32),
      Text(l.appTitle, style: t.displaySmall),
      const SizedBox(height: 6),
      Text(l.appSubtitle, style: t.titleSmall?.copyWith(color: QianColors.earth, letterSpacing: tracking(4))),
    ];
    final motto = Text(l.homeMotto,
        textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: QianColors.textSub, fontSize: 15));
    // 0.8.0：今日狀態（免費版剩餘次數、最近一筆卦記）
    final status = _TodayStatus(key: ValueKey(_refresh), onOpenEntry: (id) => _push((_) => JournalEntryPage(entryId: id)));
    // 0.6.6+68：主按鈕全寬一排、金色漸層；次要選項兩個一列、深色底金細框（Wrap 置中，單數時最後一個置中）
    // 0.8.0：會員內容（雙卦交叉）在免費版加鎖頭小圖示
    final actions = [
      for (final f in primary)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HomeButton(width: 290, height: 52, primary: true, label: f.label(l), onTap: () => open(f)),
        ),
      if (secondary.isNotEmpty)
        ValueListenableBuilder<bool>(
          valueListenable: s.premium.isPremium,
          builder: (context, premium, _) => Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final f in secondary)
                _HomeButton(
                  width: 140,
                  height: 46,
                  primary: false,
                  label: f.label(l),
                  locked: f.memberContent && !premium,
                  onTap: () => open(f),
                ),
            ],
          ),
        ),
    ];

    // 0.1.0+16：整頁一定一屏顯示完（不捲動）。主內容放在 FittedBox 裡，螢幕矮或系統字體放大時
    // 等比縮小；免責聲明固定貼在底部，不會被擠到畫面外。
    return Scaffold(
      bottomNavigationBar: const AdBanner(), // 免費版底部橫幅（§23）
      body: SafeArea(
        child: Stack(children: [
          LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      // 手機橫放（矮而寬）：卦卡與標題在左、箴言與按鈕在右，不必縮得太小
                      child: isShortWide(box.biggest)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(mainAxisSize: MainAxisSize.min, children: brand),
                                const SizedBox(width: 56),
                                SizedBox(
                                  width: 320,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [motto, const SizedBox(height: 12), status, const SizedBox(height: 12), ...actions]),
                                ),
                              ],
                            )
                          : SizedBox(
                              // 平板、摺疊機：不隨螢幕無限加寬
                              width: (box.maxWidth - 56).clamp(0, 480).toDouble(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...brand,
                                  const SizedBox(height: 16),
                                  motto,
                                  const SizedBox(height: 16),
                                  status,
                                  const SizedBox(height: 16),
                                  ...actions,
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l.homeDisclaimer,
                  style: t.bodySmall?.copyWith(fontSize: 11, color: QianColors.textSub.withValues(alpha: 0.75)),
                ),
              ),
            ],
          ),
        ),
          PositionedDirectional(top: 4, end: 4, child: _HomeMenu(onSettings: () => _push((_) => const SettingsPage()))),
        ]),
      ),
    );
  }
}

/// 首頁今日狀態（0.8.0）：免費版顯示今天還能免費起卦幾次；有卦記時顯示最近一筆，點了打開。
/// 訂閱戶不顯示次數。沒有任何內容時不佔空間。
class _TodayStatus extends StatefulWidget {
  const _TodayStatus({super.key, required this.onOpenEntry});

  final void Function(String entryId) onOpenEntry;

  @override
  State<_TodayStatus> createState() => _TodayStatusState();
}

class _TodayStatusState extends State<_TodayStatus> {
  late final Services _s = AppServices.of(context);
  late Future<(int, JournalEntry?)> _data = _load();

  Future<(int, JournalEntry?)> _load() async {
    final left = await _s.quota.freeLeft();
    final journal = _s.journal;
    final entries = journal == null ? const <JournalEntry>[] : await journal.all();
    return (left, entries.isEmpty ? null : entries.first);
  }

  @override
  void initState() {
    super.initState();
    _s.premium.isPremium.addListener(_reload);
    _s.journal?.addListener(_reload);
  }

  @override
  void dispose() {
    _s.premium.isPremium.removeListener(_reload);
    _s.journal?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return FutureBuilder<(int, JournalEntry?)>(
      future: _data,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox(height: 20);
        final (left, last) = data;
        final style = t.bodySmall?.copyWith(color: QianColors.earth);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_s.isPremium)
              Text(left > 0 ? l.homeFreeLeft(left) : l.castLimitTitle, textAlign: TextAlign.center, style: style),
            if (last != null)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onOpenEntry(last.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    '${l.homeLastEntry(_entryTitle(l, last))}${l.separator}${formatDate(last.createdAt)}',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: QianColors.textSub, decoration: TextDecoration.underline),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 卦記標題（與卦記列表相同：本卦、本卦 → 之卦，或命理卡片的名稱）。
String _entryTitle(AppLocalizations l, JournalEntry e) {
  final cast = e.isCard ? null : e.cast;
  if (cast == null) return l.journalMethodLabel(e.labelKey);
  final p = HexagramTable.byNumber(cast.primary);
  final c = cast.changed == null ? null : HexagramTable.byNumber(cast.changed!);
  return c == null ? l.journalTitleSingle(l.hexName(p)) : l.journalTitleChange(l.hexName(p), l.hexName(c));
}

enum _MenuItem { premium, intro, shareApp, feedback, settings }

/// 首頁右上角選單（0.8.0 精簡）：謙卦會員、功能介紹、推薦給朋友、意見回饋、設定。
/// 每日一卦提醒、使用統計、廣告隱私、隱私權政策與服務條款移到設定頁（[SettingsPage]）。
class _HomeMenu extends StatelessWidget {
  const _HomeMenu({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppServices.of(context);
    return PopupMenuButton<_MenuItem>(
      icon: const Icon(Icons.more_vert, color: QianColors.textSub),
      onSelected: (item) {
        switch (item) {
          case _MenuItem.premium:
            openPaywall(context, source: 'menu');
          case _MenuItem.intro:
            showIntro(Navigator.of(context), full: true);
          case _MenuItem.shareApp:
            shareApp(context);
          case _MenuItem.feedback:
            openFeedback(context);
          case _MenuItem.settings:
            onSettings();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _MenuItem.premium, child: Text(l.menuPremium)),
        PopupMenuItem(value: _MenuItem.intro, child: Text(l.menuIntro)),
        PopupMenuItem(value: _MenuItem.shareApp, child: Text(l.menuShareApp)),
        if (s.feedback != null) PopupMenuItem(value: _MenuItem.feedback, child: Text(l.menuFeedback)),
        PopupMenuItem(value: _MenuItem.settings, child: Text(l.menuSettings)),
      ],
    );
  }
}

/// 首頁按鈕：主按鈕金色漸層＋柔光；次要按鈕深色漸層底＋半透明金框。圓角膠囊形。
class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.width,
    required this.height,
    required this.primary,
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  final double width;
  final double height;
  final bool primary;
  final String label;
  final VoidCallback onTap;

  /// 會員內容：文字前加鎖頭小圖示（0.8.0）。
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: primary ? QianColors.ink : QianColors.rice,
          fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
        );
    final decoration = primary
        ? qianPrimaryButtonDecoration(radius: radius)
        : qianSecondaryButtonDecoration(
            radius: radius, border: Border.all(color: QianColors.earth.withValues(alpha: 0.55)));
    return Semantics(
      button: true,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              splashColor: (primary ? QianColors.ink : QianColors.earth).withValues(alpha: 0.12),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (locked) ...[
                        const Icon(Icons.lock_outline, size: 14, color: QianColors.earth),
                        const SizedBox(width: 4),
                      ],
                      Text(label, maxLines: 1, style: style),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
