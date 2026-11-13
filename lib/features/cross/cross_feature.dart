import 'package:flutter/material.dart';

import '../../app/app_feature.dart';
import '../../app/services.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../core/meihua/lunar_moment.dart';
import '../../core/meihua/meihua_engine.dart';
import '../../shared/cast/stepwise_cast_page.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/question_dialog.dart';
import '../meihua/meihua_city_store.dart';
import 'cross_guide.dart';
import 'cross_reading_page.dart';

/// 雙卦交叉（易經 × 梅花，HANDOFF §2.4）：寫下問題 → 三錢起卦（扣一般起卦額度）→ 以擲完那一刻的時間起梅花卦 → 交叉頁。
/// 免費版只看預覽（共識／部分呼應／分歧標題），完整內容屬會員；遠端開關 `qg_feature_cross`、`qg_cross_free_preview`。
final crossFeature = AppFeature(
  id: 'cross',
  label: (l) => l.featureCross,
  placement: FeaturePlacement.secondary,
  builder: (_) => const CrossCastPage(),
  memberContent: true,
);

/// 從解讀頁「換個角度再看」直接用這一卦做雙卦交叉（0.8.0）：不再起卦、不扣額度，梅花以此刻時間起卦。
/// 免費版規則同 [CrossCastPage]：遠端關掉預覽時先開訂閱頁。
Future<void> openCrossWithCast(BuildContext context, CastResult cast, String question) async {
  final s = AppServices.of(context);
  if (!s.isPremium && !s.limits.crossFreePreview) {
    if (!await openPaywall(context, source: 'cross')) return;
    if (!context.mounted) return;
  }
  await showCrossGuideOnce(context);
  if (!context.mounted) return;
  var q = question;
  if (q.isEmpty) q = await askQuestion(context) ?? '';
  final city = await MeihuaCityStore.load();
  final meihua = MeihuaEngine.byTime(LunarMoment.fromDateTime(DateTime.now(), longitude: city?.longitude));
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CrossReadingPage(iching: cast, meihua: meihua, question: q, solarCity: city?.name),
  ));
}

class CrossCastPage extends StatefulWidget {
  const CrossCastPage({super.key});

  @override
  State<CrossCastPage> createState() => _CrossCastPageState();
}

class _CrossCastPageState extends State<CrossCastPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final s = AppServices.of(context);
      if (!s.isPremium && !s.limits.crossFreePreview) {
        final ok = await openPaywall(context, source: 'cross');
        if (!ok) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
      if (mounted) await showCrossGuideOnce(context);
    });
  }

  Future<void> _done(BuildContext context, CastResult cast, String question) async {
    var q = question;
    if (q.isEmpty) q = await askQuestion(context) ?? '';
    final city = await MeihuaCityStore.load();
    final meihua = MeihuaEngine.byTime(LunarMoment.fromDateTime(DateTime.now(), longitude: city?.longitude));
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CrossReadingPage(iching: cast, meihua: meihua, question: q, solarCity: city?.name),
    ));
  }

  @override
  Widget build(BuildContext context) => StepwiseCastPage(
        method: const ThreeCoins(),
        instructions: (l) => l.coinsInstructions,
        stepLabel: (l, n) => l.coinsToss(n),
        allLabel: (l) => l.coinsTossAll,
        note: (l) => l.crossCastNote,
        onDone: _done,
      );
}
