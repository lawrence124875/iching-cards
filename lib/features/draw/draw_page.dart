import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../../shared/widgets/card_back.dart';
import '../../shared/widgets/card_face.dart';
import '../../shared/widgets/flip_card.dart';
import '../../shared/premium/cast_gate.dart';
import '../../shared/widgets/question_dialog.dart';

/// 簡單抽卡：靜心 → 點牌翻開 → 看解讀。
class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  static const _method = SimpleDraw();
  CastResult? _cast;
  String _question = '';

  bool _checking = false;

  Future<void> _draw() async {
    if (_cast != null || _checking) return;
    _checking = true;
    final ok = await ensureCanCast(context); // 免費版每日次數（§23）
    _checking = false;
    if (!ok || !mounted) return;
    setState(() => _cast = _method.cast(AppServices.of(context).random));
  }

  Future<void> _openReading(CastResult cast) async {
    final ads = AppServices.of(context).ads;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReadingPage(cast: cast, question: _question)),
    );
    ads.readingClosed(); // 看完解讀回來：依限頻規則可能跳插頁（不在閱讀中跳出）
  }

  void _reset() => setState(() => _cast = null);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cast = _cast;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(), // 首頁按鈕已寫「抽一卦」，這裡不再重複標題
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: Column(
            children: [
              Text(
                cast == null ? l.drawPromptBefore : l.drawPromptAfter,
                style: t.bodyMedium?.copyWith(color: QianColors.textSub),
                textAlign: TextAlign.center,
              ),
              // 翻牌後就不再寫想問的事（存進卦記時仍可修改）
              if (cast == null)
                QuestionPrompt(question: _question, onChanged: (q) => setState(() => _question = q))
              else if (_question.isNotEmpty)
                QuestionPrompt(question: _question, onChanged: (_) {}, enabled: false),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.62,
                    child: GestureDetector(
                      onTap: _draw,
                      child: Semantics(
                        button: cast == null,
                        label: cast == null ? l.drawFlip : null,
                        child: FlipCard(
                          flipped: cast != null,
                          back: const CardBack(),
                          front: cast == null
                              ? const SizedBox.shrink()
                              : CardFace(info: HexagramTable.byNumber(cast.primary), zoomable: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (cast == null)
                FilledButton(onPressed: _draw, child: Text(l.drawFlip))
              else ...[
                FilledButton(
                  onPressed: () => _openReading(cast),
                  child: Text(l.viewReading),
                ),
                TextButton(onPressed: _reset, child: Text(l.drawAgain)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
