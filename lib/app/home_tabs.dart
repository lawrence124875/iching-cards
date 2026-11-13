import 'package:flutter/material.dart';

import '../core/iching/hexagram_table.dart';
import '../features/coin_cast/coin_cast_feature.dart';
import '../features/cross/cross_feature.dart';
import '../features/daily/daily_feature.dart';
import '../features/daily/daily_page.dart';
import '../features/draw/draw_feature.dart';
import '../features/eastern/eastern_feature.dart';
import '../features/learn/hexagram_library_page.dart';
import '../features/learn/hexagram_quiz_page.dart';
import '../features/learn/lesson_course.dart';
import '../features/learn/lesson_list_page.dart';
import '../features/meihua/meihua_feature.dart';
import '../features/yarrow/yarrow_feature.dart';
import '../l10n/l10n.dart';
import '../shared/premium/ad_banner.dart';
import '../shared/widgets/adaptive_layout.dart';
import '../shared/widgets/card_back.dart';
import '../shared/widgets/card_face.dart';
import 'feature_registry.dart';
import 'services.dart';
import 'settings_page.dart';
import 'theme.dart';

/// 起卦入口（0.9.0）：今日分頁與起卦分頁共用。遠端關掉的不顯示。
class _System {
  const _System(this.feature, this.icon, this.desc);

  final AppFeature feature;
  final IconData icon;
  final LocalizedText desc;
}

List<_System> _systems(BuildContext context) {
  final ids = activeFeatures(AppServices.of(context).flags).map((f) => f.id).toSet();
  return [
    _System(drawFeature, Icons.style_outlined, (l) => l.descDraw),
    _System(coinCastFeature, Icons.toll_outlined, (l) => l.descCoins),
    _System(yarrowFeature, Icons.grass_outlined, (l) => l.descYarrow),
    _System(meihuaFeature, Icons.local_florist_outlined, (l) => l.descMeihua),
    _System(crossFeature, Icons.compare_arrows, (l) => l.descCross),
    _System(easternFeature, Icons.auto_awesome_outlined, (l) => l.descEastern),
  ].where((s) => ids.contains(s.feature.id) && s.feature.builder != null).toList();
}

Future<void> _open(BuildContext context, AppFeature f, VoidCallback onReturn) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: f.builder!));
  onReturn();
}

/// 「今日」分頁（0.9.1 精簡）：品牌＋設定齒輪、今日一卦大卡、抽一卦卡（含免費剩餘次數）、
/// 其他起卦小卡（圓底圖示、會員內容角落鎖頭）、底部箴言＋免責。會員入口在設定頁與次數用完時。
class TodayTab extends StatelessWidget {
  const TodayTab({super.key, required this.onReturn});

  /// 從其他頁回來時呼叫（首頁重建、重新讀取今日一卦與剩餘次數）。
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final s = AppServices.of(context);
    final daily = activeFeatures(s.flags).any((f) => f.id == dailyFeature.id);
    final systems = _systems(context);
    final draw = systems.where((x) => x.feature.id == drawFeature.id);
    final tiles = systems
        .where((x) => const {'meihua', 'cross', 'eastern'}.contains(x.feature.id))
        .toList();

    return Scaffold(
      bottomNavigationBar: const AdBanner(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: readablePadding(context, horizontal: 20, top: 8, bottom: 24, maxWidth: 560),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.appTitle, style: t.headlineSmall),
                  const SizedBox(height: 2),
                  Text(l.appSubtitle,
                      style: t.titleSmall?.copyWith(color: QianColors.earth, letterSpacing: tracking(2))),
                ]),
              ),
              IconButton(
                tooltip: l.menuSettings,
                icon: const Icon(Icons.settings_outlined, color: QianColors.textSub),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
                  onReturn();
                },
              ),
            ]),
            const SizedBox(height: 16),
            if (daily) _TodayCard(onReturn: onReturn),
            for (final x in draw) _DrawCard(system: x, onTap: () => _open(context, x.feature, onReturn)),
            if (tiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                child: Text(l.drawOtherMethods, style: t.titleMedium),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: s.premium.isPremium,
                builder: (context, premium, _) => IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final x in tiles)
                      Expanded(
                        child: _SystemTile(
                          system: x,
                          locked: x.feature.memberContent && !premium,
                          onTap: () => _open(context, x.feature, onReturn),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(l.homeMotto,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: QianColors.textSub.withValues(alpha: 0.85), height: 1.7)),
            const SizedBox(height: 6),
            Text(
              l.homeDisclaimer,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(fontSize: 11, color: QianColors.textSub.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「起卦」分頁：每種起卦方式一列，附一句說明。
class CastTab extends StatelessWidget {
  const CastTab({super.key, required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppServices.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navCast)),
      bottomNavigationBar: const AdBanner(),
      body: ValueListenableBuilder<bool>(
        valueListenable: s.premium.isPremium,
        builder: (context, premium, _) => ListView(
          padding: readablePadding(context, top: 8, bottom: 40),
          children: [
            for (final x in _systems(context))
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Icon(x.icon, color: QianColors.earth),
                  title: Row(children: [
                    Flexible(child: Text(x.feature.label(l))),
                    if (x.feature.memberContent && !premium) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 16, color: QianColors.earth),
                    ],
                  ]),
                  subtitle: Text(x.desc(l)),
                  trailing: const Icon(Icons.chevron_right, color: QianColors.textSub),
                  onTap: () => _open(context, x.feature, onReturn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 「學習」分頁：六十四卦卦庫、認卦練習（0.9.0，不上鎖），再來是易經、梅花易數、紫微、八字四套課程（各自的開頭可免費試讀）。
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ids = activeFeatures(AppServices.of(context).flags).map((f) => f.id).toSet();
    final courses = [
      (ichingCourse, Icons.menu_book_outlined),
      if (ids.contains(meihuaFeature.id)) (meihuaCourse, Icons.local_florist_outlined),
      if (ids.contains(easternFeature.id)) ...[
        (ziweiCourse, Icons.auto_awesome_outlined),
        (baziCourse, Icons.calendar_month_outlined),
      ],
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navLearn)),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: readablePadding(context, top: 8, bottom: 40),
        children: [
          for (final (icon, title, desc, page) in <(IconData, String, String, Widget)>[
            (Icons.grid_view_outlined, l.libraryTitle, l.libraryDesc, const HexagramLibraryPage()),
            (Icons.quiz_outlined, l.quizTitle, l.quizDesc, const HexagramQuizPage()),
          ])
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Icon(icon, color: QianColors.earth),
                title: Text(title),
                subtitle: Text(desc),
                trailing: const Icon(Icons.chevron_right, color: QianColors.textSub),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
              ),
            ),
          const SizedBox(height: 8),
          for (final (c, icon) in courses)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Icon(icon, color: QianColors.earth),
                title: Text(c.title(context)),
                subtitle: Text(l.learnLessonCount(c.count)),
                trailing: const Icon(Icons.chevron_right, color: QianColors.textSub),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => LessonListPage(course: c),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

/// 今日一卦大卡：還沒翻顯示牌背與提示；翻過顯示今天的卦；連續天數 ≥ 1 時顯示。
class _TodayCard extends StatefulWidget {
  const _TodayCard({required this.onReturn});

  final VoidCallback onReturn;

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  late final Services _s = AppServices.of(context);
  int? _hex;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final hex = await _s.dailyHexagram.today(now);
    final streak = await _s.dailyHexagram.streak(now);
    if (!mounted) return;
    setState(() {
      _hex = hex;
      _streak = streak;
    });
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DailyPage()));
    widget.onReturn();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hex = _hex;
    final info = hex == null ? null : HexagramTable.byNumber(hex);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            SizedBox(
              width: 96,
              child: AspectRatio(
                aspectRatio: 0.62,
                child: FittedBox(
                  child: SizedBox(
                    width: 200,
                    height: 200 / 0.62,
                    child: info == null ? const CardBack() : CardFace(info: info),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.dailyTitle, style: t.titleLarge),
                const SizedBox(height: 6),
                if (info == null)
                  Text(l.dailyPrompt, style: t.bodyMedium?.copyWith(color: QianColors.textSub))
                else ...[
                  Text(l.homeTodayDrawn, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
                  Text(l.hexFullName(info), style: t.titleMedium?.copyWith(color: QianColors.earth)),
                ],
                if (_streak > 0) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.local_fire_department_outlined, size: 16, color: QianColors.earth),
                    const SizedBox(width: 4),
                    Flexible(child: Text(l.homeStreak(_streak), style: t.bodySmall)),
                  ]),
                ],
                if (info == null) ...[
                  const SizedBox(height: 10),
                  Text(l.dailyFlip, style: t.labelLarge?.copyWith(color: QianColors.earth)),
                ],
              ]),
            ),
            const Icon(Icons.chevron_right, color: QianColors.textSub),
          ]),
        ),
      ),
    );
  }
}

/// 免費版今天還能起卦幾次（訂閱戶不顯示）。
class _FreeLeft extends StatefulWidget {
  const _FreeLeft();

  @override
  State<_FreeLeft> createState() => _FreeLeftState();
}

class _FreeLeftState extends State<_FreeLeft> {
  late final Services _s = AppServices.of(context);
  late final Future<int> _left = _s.quota.freeLeft();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return ValueListenableBuilder<bool>(
      valueListenable: _s.premium.isPremium,
      builder: (context, premium, _) => premium
          ? const SizedBox.shrink()
          : FutureBuilder<int>(
              future: _left,
              builder: (context, snap) {
                final left = snap.data;
                if (left == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(left > 0 ? l.homeFreeLeft(left) : l.castLimitTitle,
                      style: t.bodySmall?.copyWith(color: QianColors.earth)),
                );
              },
            ),
    );
  }
}

/// 首頁的小系統卡（並排）。
class _SystemTile extends StatelessWidget {
  const _SystemTile({required this.system, required this.locked, required this.onTap});

  final _System system;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              _avatar(system.icon),
              if (locked)
                PositionedDirectional(
                  end: -4,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: QianColors.inkCard,
                    child: Icon(Icons.lock_outline, size: 12, color: QianColors.earth, semanticLabel: l.learnLocked),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(system.feature.label(l), textAlign: TextAlign.center, style: t.labelLarge),
          ]),
        ),
      ),
    );
  }
}

Widget _avatar(IconData icon) => CircleAvatar(
      backgroundColor: QianColors.earth.withValues(alpha: 0.15),
      foregroundColor: QianColors.earth,
      child: Icon(icon),
    );

/// 抽一卦（0.9.1）：和今日一卦同樣的卡片樣式，免費版剩餘次數放在卡內。
class _DrawCard extends StatelessWidget {
  const _DrawCard({required this.system, required this.onTap});

  final _System system;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            _avatar(system.icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(system.feature.label(l), style: t.titleMedium?.copyWith(color: QianColors.earth)),
                const SizedBox(height: 2),
                Text(system.desc(l), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
                const _FreeLeft(),
              ]),
            ),
            const Icon(Icons.chevron_right, color: QianColors.textSub),
          ]),
        ),
      ),
    );
  }
}
