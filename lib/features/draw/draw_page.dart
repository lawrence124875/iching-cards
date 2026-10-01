import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../core/iching/hexagram_table.dart';
import '../../reading/reading_page.dart';
import '../../shared/widgets/card_back.dart';
import '../../shared/widgets/card_face.dart';
import '../../shared/widgets/flip_card.dart';

/// 簡單抽卡：靜心 → 點牌翻開 → 看解讀。
class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  static const _method = SimpleDraw();
  CastResult? _cast;

  void _draw() {
    if (_cast != null) return;
    setState(() => _cast = _method.cast(AppServices.of(context).random));
  }

  void _reset() => setState(() => _cast = null);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cast = _cast;
    return Scaffold(
      appBar: AppBar(title: const Text('抽一卦')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: Column(
            children: [
              Text(
                cast == null ? '心裡想著眼前的一件事，準備好了就點牌。' : '這是此刻的象。',
                style: t.bodyMedium?.copyWith(color: QianColors.textSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.62,
                    child: GestureDetector(
                      onTap: _draw,
                      child: Semantics(
                        button: cast == null,
                        label: cast == null ? '翻牌' : null,
                        child: FlipCard(
                          flipped: cast != null,
                          back: const CardBack(),
                          front: cast == null
                              ? const SizedBox.shrink()
                              : CardFace(info: HexagramTable.byNumber(cast.primary)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (cast == null)
                FilledButton(onPressed: _draw, child: const Text('翻牌'))
              else ...[
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ReadingPage(cast: cast)),
                  ),
                  child: const Text('看解讀'),
                ),
                TextButton(onPressed: _reset, child: const Text('重新抽')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
