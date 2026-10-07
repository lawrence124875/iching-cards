import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../../shared/premium/cast_gate.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import '../../shared/widgets/question_dialog.dart';

/// 擲錢起卦：三枚銅錢擲六次，由初爻往上；含變爻與之卦。
/// 版面固定在一個畫面內：說明 → 卦象＋六爻表（空間不足時等比縮小）→ 底部按鈕。
class CoinCastPage extends StatefulWidget {
  const CoinCastPage({super.key});

  @override
  State<CoinCastPage> createState() => _CoinCastPageState();
}

class _CoinCastPageState extends State<CoinCastPage> {
  static const _method = ThreeCoins();
  final List<CoinToss> _tosses = [];
  String _question = '';

  bool get _done => _tosses.length == 6;

  bool _checking = false;

  /// 每一卦（六擲）只在第一擲前檢查一次免費次數（§23）。
  Future<bool> _allowed() async {
    if (_tosses.isNotEmpty) return true;
    if (_checking) return false;
    _checking = true;
    final ok = await ensureCanCast(context);
    _checking = false;
    return ok && mounted;
  }

  Future<void> _toss() async {
    if (_done || !await _allowed()) return;
    setState(() => _tosses.add(_method.tossOnce(AppServices.of(context).random)));
  }

  Future<void> _openReading(List<LineValue> lines) async {
    final ads = AppServices.of(context).ads;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReadingPage(cast: CastResult(methodId: _method.id, lines: lines), question: _question),
    ));
    ads.readingClosed(); // 看完解讀回來：依限頻規則可能跳插頁
  }

  Future<void> _tossAll() async {
    if (!await _allowed()) return;
    final r = AppServices.of(context).random;
    setState(() {
      while (_tosses.length < 6) {
        _tosses.add(_method.tossOnce(r));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final lines = [for (final x in _tosses) x.line];
    final padded = [...lines.map((l) => l.isYang), ...List.filled(6 - lines.length, false)];
    final changing = {for (var i = 0; i < lines.length; i++) if (lines[i].isChanging) i + 1};

    final top = [
      Text(
        l.coinsInstructions,
        textAlign: TextAlign.center,
        style: t.bodySmall,
      ),
      // 擲完六次就不再寫想問的事（存進卦記時仍可修改）
      QuestionPrompt(
        question: _question,
        onChanged: (q) => setState(() => _question = q),
        enabled: !_done,
      ),
    ];
    final lineTable = LayoutBuilder(
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            // 至少 320 寬（橫放時左欄窄，整塊等比縮小而不擠壓），平板不隨螢幕無限加寬
            width: box.maxWidth.clamp(320, 480).toDouble(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                HexagramGlyph(
                  lines: padded,
                  changing: changing,
                  width: 104,
                  visibleCount: lines.length,
                ),
                const SizedBox(height: 20),
                // 六列固定保留，未擲的爻顯示「—」，畫面不會隨擲錢跳動。
                for (var i = 5; i >= 0; i--) _row(t, l, i, i < lines.length ? _tosses[i] : null),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
    final buttons = [
      if (!_done) ...[
        FilledButton(onPressed: _toss, child: Text(l.coinsToss(_tosses.length + 1))),
        TextButton(onPressed: _tossAll, child: Text(l.coinsTossAll)),
      ] else ...[
        FilledButton(
          onPressed: () => _openReading(lines),
          child: Text(l.viewReading),
        ),
        TextButton(onPressed: () => setState(_tosses.clear), child: Text(l.coinsRestart)),
      ],
    ];

    return Scaffold(
      appBar: AppBar(), // 首頁連結已寫「三枚銅錢起卦」，這裡不再重複標題
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => isShortWide(box.biggest)
              // 手機橫放：卦象與六爻在左、說明與按鈕在右
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
                  child: Row(
                    children: [
                      Expanded(child: lineTable),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 320,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [...top, const SizedBox(height: 16), ...buttons],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                  child: Column(
                    children: [...top, Expanded(child: lineTable), ...buttons],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _row(TextTheme t, AppLocalizations l, int i, CoinToss? toss) {
    final line = toss?.line;
    final next = i == _tosses.length;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: l.isChinese ? 44 : 60, // 英文「Line 1」較寬
            child: Text(l.linePosition(i + 1),
                style: t.titleMedium?.copyWith(
                  color: line == null && !next ? QianColors.textSub.withValues(alpha: 0.5) : null,
                )),
          ),
          Text(toss == null ? '' : toss.coins.join(' + '), style: t.bodySmall),
          const Spacer(),
          Text(
            line == null
                ? '—'
                : '${l.coinLineValue(line.value, l.lineKind(line))}${line.isChanging ? l.coinChangingMark : ''}',
            style: t.bodyMedium?.copyWith(
              color: line == null
                  ? QianColors.textSub.withValues(alpha: 0.5)
                  : (line.isChanging ? QianColors.rice : QianColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
