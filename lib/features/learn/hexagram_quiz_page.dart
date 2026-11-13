import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import '../../reading/detail_page.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';

/// 認卦練習（0.9.0，參考塔羅 App 的認牌練習）：看卦象，從四個卦名選一個。
/// 一輪 [roundSize] 題；答錯的卦之後會多出現（[QuizProgress] 間隔重複）。答完顯示卦的全名（上下卦），可點開詳解。
class HexagramQuizPage extends StatefulWidget {
  const HexagramQuizPage({super.key});

  static const roundSize = 10;

  @override
  State<HexagramQuizPage> createState() => _HexagramQuizPageState();
}

class _HexagramQuizPageState extends State<HexagramQuizPage> {
  late final Services _s = AppServices.of(context);
  List<int> _questions = const [];
  int _index = 0;
  int _correct = 0;
  List<int> _choices = const [];
  int? _picked;
  int _mastered = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final q = await _s.quiz.pick(HexagramQuizPage.roundSize, _s.random);
    final m = await _s.quiz.mastered();
    if (!mounted) return;
    setState(() {
      _questions = q;
      _index = 0;
      _correct = 0;
      _mastered = m;
      _prepare();
    });
  }

  void _prepare() {
    _picked = null;
    if (_index >= _questions.length) return;
    final answer = _questions[_index];
    final others = <int>{};
    while (others.length < 3) {
      final n = _s.random.nextInt(64) + 1;
      if (n != answer) others.add(n);
    }
    _choices = [answer, ...others]..shuffle(_s.random);
  }

  Future<void> _pick(int n) async {
    if (_picked != null) return;
    final answer = _questions[_index];
    final ok = n == answer;
    setState(() {
      _picked = n;
      if (ok) _correct++;
    });
    await _s.quiz.record(answer, correct: ok);
  }

  Future<void> _next() async {
    final last = _index + 1 >= _questions.length;
    final m = last ? await _s.quiz.mastered() : _mastered;
    if (!mounted) return;
    setState(() {
      _index++;
      _mastered = m;
      _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final done = _questions.isNotEmpty && _index >= _questions.length;

    Widget body;
    if (_questions.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (done) {
      body = ListView(
        padding: readablePadding(context, top: 48, bottom: 32),
        children: [
          const Icon(Icons.emoji_events_outlined, size: 56, color: QianColors.earth),
          const SizedBox(height: 16),
          Text(l.quizDone(_correct, _questions.length), textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: 8),
          Text(l.quizMastered(_mastered),
              textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: QianColors.textSub)),
          const SizedBox(height: 32),
          Center(child: FilledButton(onPressed: _start, child: Text(l.quizAgain))),
        ],
      );
    } else {
      final answer = HexagramTable.byNumber(_questions[_index]);
      final picked = _picked;
      body = ListView(
        padding: readablePadding(context, top: 16, bottom: 32),
        children: [
          Text(l.quizProgress(_index + 1, _questions.length),
              textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          const SizedBox(height: 24),
          Center(child: HexagramGlyph(lines: answer.lines, width: 96)),
          const SizedBox(height: 24),
          Text(l.quizPrompt, textAlign: TextAlign.center, style: t.titleMedium),
          const SizedBox(height: 16),
          for (final n in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Choice(
                label: l.hexName(HexagramTable.byNumber(n)),
                state: picked == null
                    ? _ChoiceState.open
                    : n == answer.number
                        ? _ChoiceState.right
                        : n == picked
                            ? _ChoiceState.wrong
                            : _ChoiceState.idle,
                onTap: () => _pick(n),
              ),
            ),
          if (picked != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => DetailPage(number: answer.number),
                )),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(l.hexFullName(answer)),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: FilledButton(onPressed: _next, child: Text(l.quizNext))),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.quizTitle)),
      bottomNavigationBar: const AdBanner(),
      body: body,
    );
  }
}

enum _ChoiceState { open, idle, right, wrong }

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.state, required this.onTap});

  final String label;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ChoiceState.right => QianColors.earth,
      _ChoiceState.wrong => Colors.redAccent,
      _ => QianColors.mountain,
    };
    return OutlinedButton.icon(
      onPressed: state == _ChoiceState.open ? onTap : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: color, width: state == _ChoiceState.right || state == _ChoiceState.wrong ? 2 : 1),
        foregroundColor: QianColors.text,
        disabledForegroundColor: QianColors.text,
      ),
      icon: switch (state) {
        _ChoiceState.right => const Icon(Icons.check_circle_outline, color: QianColors.earth),
        _ChoiceState.wrong => const Icon(Icons.cancel_outlined, color: Colors.redAccent),
        _ => const SizedBox.shrink(),
      },
      label: Text(label),
    );
  }
}
