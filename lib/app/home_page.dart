import 'package:flutter/material.dart';

import '../features/journal/journal_feature.dart';
import '../features/learn/learn_feature.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/adaptive_layout.dart';
import 'feature_registry.dart';
import 'home_tabs.dart';
import 'services.dart';

/// 首頁外框（0.9.0，參考塔羅 App 0.4.0）：底部導覽「今日／起卦／學習／卦記」；手機橫放（矮而寬）改側邊導覽。
/// 學習、卦記被遠端開關關掉時，對應的分頁一起拿掉。
/// 只建目前分頁（不用 IndexedStack）：每個分頁自帶橫幅廣告，看不見的分頁不載入廣告。

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _Tab {
  const _Tab(this.id, this.icon, this.selectedIcon, this.label, this.build);

  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final LocalizedText label;
  final WidgetBuilder build;
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  /// 從今日一卦等頁面回來時加一，讓目前分頁重建、重新讀取今日一卦與剩餘次數。
  int _generation = 0;

  void _refresh() {
    if (mounted) setState(() => _generation++);
  }

  List<_Tab> _tabs(BuildContext context) {
    final ids = activeFeatures(AppServices.of(context).flags).map((f) => f.id).toSet();
    return [
      _Tab('today', Icons.wb_sunny_outlined, Icons.wb_sunny, (l) => l.navToday,
          (_) => TodayTab(onReturn: _refresh)),
      _Tab('cast', Icons.style_outlined, Icons.style, (l) => l.navCast, (_) => CastTab(onReturn: _refresh)),
      if (ids.contains(learnFeature.id))
        _Tab(learnFeature.id, Icons.school_outlined, Icons.school, (l) => l.navLearn, (_) => const LearnTab()),
      if (ids.contains(journalFeature.id))
        _Tab(journalFeature.id, Icons.bookmark_outline, Icons.bookmark, (l) => l.featureJournal, journalFeature.builder!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = _tabs(context);
    final index = _index.clamp(0, tabs.length - 1);
    void select(int i) => setState(() => _index = i);
    final body = KeyedSubtree(key: ValueKey((index, _generation)), child: Builder(builder: tabs[index].build));

    if (isShortWide(MediaQuery.sizeOf(context))) {
      return Scaffold(
        body: Row(children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: 0,
              destinations: [
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label(l)),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: select,
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label(l)),
        ],
      ),
    );
  }
}
