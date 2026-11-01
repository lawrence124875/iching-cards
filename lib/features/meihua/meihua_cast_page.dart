import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/meihua/lunar_moment.dart';
import '../../core/meihua/meihua_cast.dart';
import '../../core/meihua/meihua_engine.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/premium/cast_gate.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'meihua_reading_page.dart';

/// 梅花起卦：時間（免費每天 1 次＋獎勵 1 次）、數字、字數（會員）。
class MeihuaCastPage extends StatefulWidget {
  const MeihuaCastPage({super.key, this.initial = MeihuaMethod.time});

  final MeihuaMethod initial;

  @override
  State<MeihuaCastPage> createState() => _MeihuaCastPageState();
}

class _MeihuaCastPageState extends State<MeihuaCastPage> {
  late MeihuaMethod _method = widget.initial;
  final _question = TextEditingController();
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _words = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_question, _first, _second, _words]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _num(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v == null || v <= 0) ? null : v;
  }

  bool get _ready => switch (_method) {
        MeihuaMethod.time => true,
        MeihuaMethod.number => _num(_first) != null && _num(_second) != null,
        MeihuaMethod.wordCount => MeihuaEngine.countWords(_words.text) > 0,
      };

  Future<void> _select(MeihuaMethod m) async {
    final s = AppServices.of(context);
    if (m != MeihuaMethod.time && !s.isPremium &&
        !await openPaywall(context, source: 'meihua_method', note: context.l10n.meihuaPaywallMethodNote)) {
      return;
    }
    if (mounted) setState(() => _method = m);
  }

  Future<void> _cast() async {
    if (_busy || !_ready) return;
    final s = AppServices.of(context);
    // 訂閱後才能用數字、字數；在這頁中途退訂的情況一律退回時間起卦
    if (_method != MeihuaMethod.time && !s.isPremium) {
      setState(() => _method = MeihuaMethod.time);
      return;
    }
    _busy = true;
    final pass = await ensureCanCast(context, quota: s.meihuaQuota, type: 'meihua');
    _busy = false;
    if (pass == null || !mounted) return;
    final moment = LunarMoment.fromDateTime(DateTime.now());
    final cast = switch (_method) {
      MeihuaMethod.time => MeihuaEngine.byTime(moment),
      MeihuaMethod.number => MeihuaEngine.byNumbers(_num(_first)!, _num(_second)!, moment),
      MeihuaMethod.wordCount => MeihuaEngine.byWordCount(MeihuaEngine.countWords(_words.text), moment),
    };
    final question = _method == MeihuaMethod.wordCount ? _words.text.trim() : _question.text.trim();
    if (pass.interstitial) {
      await pauseBeforeReading(context);
      if (!mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MeihuaReadingPage(cast: cast, question: question)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final premium = AppServices.of(context).isPremium;
    final m = LunarMoment.fromDateTime(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(l.meihuaCastTitle)),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: readablePadding(context, top: 16, bottom: 32),
        children: [
          SegmentedButton<MeihuaMethod>(
            segments: [
              for (final x in MeihuaMethod.values)
                ButtonSegment(
                  value: x,
                  label: Text(l.methodName(x.id)),
                  icon: x != MeihuaMethod.time && !premium ? const Icon(Icons.lock_outline, size: 16) : null,
                ),
            ],
            selected: {_method},
            showSelectedIcon: false,
            onSelectionChanged: (v) => _select(v.first),
          ),
          const SizedBox(height: 20),
          ...switch (_method) {
            MeihuaMethod.time => [
                Text(l.meihuaTimeHint, style: t.bodyMedium),
                const SizedBox(height: 8),
                Text(l.meihuaLunarNumbers(m.yearNumber, m.month, m.day, m.hourNumber),
                    style: t.bodySmall?.copyWith(color: QianColors.textSub)),
                const SizedBox(height: 16),
                _field(_question, l.meihuaQuestionHint),
              ],
            MeihuaMethod.number => [
                Text(l.meihuaNumberHint, style: t.bodyMedium),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_first, l.meihuaFirstNumber, number: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_second, l.meihuaSecondNumber, number: true)),
                ]),
                const SizedBox(height: 16),
                _field(_question, l.meihuaQuestionHint),
              ],
            MeihuaMethod.wordCount => [
                Text(l.meihuaWordsHint, style: t.bodyMedium),
                const SizedBox(height: 12),
                _field(_words, l.meihuaQuestionHint, maxLines: 3),
                const SizedBox(height: 6),
                Text(l.meihuaWordCount(MeihuaEngine.countWords(_words.text)),
                    style: t.bodySmall?.copyWith(color: QianColors.textSub)),
              ],
          },
          const SizedBox(height: 28),
          FilledButton(onPressed: _ready ? _cast : null, child: Text(l.meihuaCastButton)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false, int maxLines = 1}) => TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)] : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      );
}
