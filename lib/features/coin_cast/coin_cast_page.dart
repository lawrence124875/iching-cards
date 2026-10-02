import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../reading/reading_page.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import '../../shared/widgets/question_dialog.dart';

const _lineNames = ['初', '二', '三', '四', '五', '上'];

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

  void _toss() {
    if (_done) return;
    setState(() => _tosses.add(_method.tossOnce(AppServices.of(context).random)));
  }

  void _tossAll() {
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
    final lines = [for (final x in _tosses) x.line];
    final padded = [...lines.map((l) => l.isYang), ...List.filled(6 - lines.length, false)];
    final changing = {for (var i = 0; i < lines.length; i++) if (lines[i].isChanging) i + 1};

    return Scaffold(
      appBar: AppBar(title: const Text('三枚銅錢起卦')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
          child: Column(
            children: [
              Text(
                '陽面 3、陰面 2，三枚相加得一爻；由下往上擲六次，6 與 9 為變爻。',
                textAlign: TextAlign.center,
                style: t.bodySmall,
              ),
              QuestionPrompt(question: _question, onChanged: (q) => setState(() => _question = q)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth,
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
                            for (var i = 5; i >= 0; i--) _row(t, i, i < lines.length ? _tosses[i] : null),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_done) ...[
                FilledButton(onPressed: _toss, child: Text('擲第 ${_tosses.length + 1} 次')),
                TextButton(onPressed: _tossAll, child: const Text('一次擲完')),
              ] else ...[
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ReadingPage(
                      cast: CastResult(methodId: _method.id, lines: lines),
                      question: _question,
                    ),
                  )),
                  child: const Text('看解讀'),
                ),
                TextButton(onPressed: () => setState(_tosses.clear), child: const Text('重新起卦')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(TextTheme t, int i, CoinToss? toss) {
    final line = toss?.line;
    final next = i == _tosses.length;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text('${_lineNames[i]}爻',
                style: t.titleMedium?.copyWith(
                  color: line == null && !next ? QianColors.textSub.withValues(alpha: 0.5) : null,
                )),
          ),
          Text(toss == null ? '' : toss.coins.join(' + '), style: t.bodySmall),
          const Spacer(),
          Text(
            line == null ? '—' : '${line.value}　${line.label}${line.isChanging ? '（變）' : ''}',
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
