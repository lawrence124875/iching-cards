import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/hexagram_content.dart';
import '../../core/daily/daily_hexagram.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/card_back.dart';
import '../../shared/widgets/card_face.dart';
import '../../shared/widgets/flip_card.dart';

/// 今日一卦（0.9.0）：翻開今天的卦 → 卦名、這一天的一組解讀標題與「給現在的你」→ 看完整解讀。
/// 同一天再打開看到的是同一卦（[DailyHexagramStore]）；不計入每日免費起卦次數（2026-11-13 Lawrence 決定）。
class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late final Services _s = AppServices.of(context);
  int? _hex;
  bool _loaded = false;
  HexagramContent? _content;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final hex = await _s.dailyHexagram.today(DateTime.now());
    final content = hex == null ? null : await _s.content.hexagram(hex);
    if (!mounted) return;
    setState(() {
      _hex = hex;
      _content = content;
      _loaded = true;
    });
  }

  Future<void> _flip() async {
    if (_hex != null) return;
    final hex = await _s.dailyHexagram.drawToday(DateTime.now(), _s.random);
    await _s.quota.recordCast(counted: false); // 只記「今天起過卦」（每日提醒用），不扣次數
    final content = await _s.content.hexagram(hex);
    if (!mounted) return;
    setState(() {
      _hex = hex;
      _content = content;
    });
  }

  /// 這一天固定用哪一組解讀（同一天看到同一組）。
  int _readingIndex(int count) {
    final n = DateTime.now();
    return count == 0 ? 0 : (n.year * 372 + n.month * 31 + n.day) % count;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hex = _hex;
    final info = hex == null ? null : HexagramTable.byNumber(hex);
    final readings = _content?.readings ?? const <ReadingContent>[];
    final index = _readingIndex(readings.length);
    final reading = readings.isEmpty ? null : readings[index];

    final card = SizedBox(
      width: 200,
      child: AspectRatio(
        aspectRatio: 0.62,
        child: GestureDetector(
          onTap: _loaded ? _flip : null,
          child: Semantics(
            button: hex == null,
            label: hex == null ? l.dailyFlip : null,
            child: FlipCard(
              flipped: info != null,
              back: const CardBack(),
              front: info == null ? const SizedBox.shrink() : CardFace(info: info, zoomable: true),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.dailyTitle)),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: readablePadding(context, top: 16, bottom: 32),
        children: [
          Text(
            info == null ? l.dailyPrompt : l.hexFullName(info),
            textAlign: TextAlign.center,
            style: info == null ? t.bodyLarge?.copyWith(color: QianColors.textSub) : t.headlineSmall,
          ),
          const SizedBox(height: 20),
          Center(child: card),
          const SizedBox(height: 24),
          if (info == null)
            Center(child: FilledButton(onPressed: _loaded ? _flip : null, child: Text(l.dailyFlip)))
          else ...[
            if (reading != null) ...[
              Text(reading.title, textAlign: TextAlign.center, style: t.titleLarge?.copyWith(color: QianColors.earth)),
              const SizedBox(height: 12),
              Text(reading.forYou, style: t.bodyLarge),
            ],
            const SizedBox(height: 24),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ReadingPage(
                    cast: DailyHexagramStore.castOf(info.number),
                    readingIndex: reading == null ? null : index,
                  ),
                )),
                child: Text(l.viewReading),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(l.dailyNotCounted,
              textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
        ],
      ),
    );
  }
}
