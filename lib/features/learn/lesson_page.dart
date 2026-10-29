import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/lessons.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';

/// 一課的內容：段落（可附卦畫示意、條列）、重點整理、練習；底部「下一課」。
class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final folder = L10n.language.contentFolder;
    return FutureBuilder<(Lesson, String)?>(
      future: lessonSource.load(folder, id),
      builder: (context, snap) {
        final r = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(l.learnLessonNumber(id))),
          body: r == null
              ? Center(child: snap.connectionState == ConnectionState.done ? Text(l.learnMissing) : const CircularProgressIndicator())
              : _Body(lesson: r.$1, fallback: r.$2 != folder),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lesson, required this.fallback});

  final Lesson lesson;
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final s = AppServices.of(context);
    final next = lesson.id < lessonCount ? lesson.id + 1 : null;
    return ListView(
      padding: readablePadding(context, top: 16, bottom: 40),
      children: [
        if (fallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l.learnFallbackNote, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          ),
        Text(lesson.title, style: t.headlineSmall),
        if (lesson.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(lesson.subtitle, style: t.bodyMedium?.copyWith(color: QianColors.earth)),
        ],
        for (final sec in lesson.sections) _SectionView(section: sec),
        if (lesson.keyPoints.isNotEmpty)
          _Box(title: l.learnKeyPoints, children: [
            for (final k in lesson.keyPoints)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('・', style: TextStyle(color: QianColors.rice)),
                  Expanded(child: Text(k, style: t.bodyMedium)),
                ]),
              ),
          ]),
        if (lesson.practice.isNotEmpty)
          _Box(title: l.learnPractice, children: [Text(lesson.practice, style: t.bodyMedium)]),
        if (next != null) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              if (!s.isPremium && !lessonIsFree(next) &&
                  !await openPaywall(context, source: 'lesson', note: l.learnPaywallNote)) {
                return;
              }
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => LessonPage(id: next)));
            },
            child: Text(l.learnNext),
          ),
        ],
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});

  final LessonSection section;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading, style: t.titleMedium),
          for (final p in section.body.split('\n\n'))
            if (p.trim().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(p, style: t.bodyMedium)),
          if (section.glyphs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 16,
                children: [
                  for (final g in section.glyphs)
                    SizedBox(
                      width: 140,
                      child: Column(children: [
                        HexagramGlyph(lines: g.lines, changing: g.changing, width: 44),
                        const SizedBox(height: 8),
                        Text(g.caption,
                            textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
                      ]),
                    ),
                ],
              ),
            ),
          for (final it in section.items)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (it.lines != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12, top: 4),
                    child: HexagramGlyph(lines: it.lines!, width: 24),
                  ),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: it.label, style: t.titleSmall?.copyWith(color: QianColors.earth)),
                    const TextSpan(text: '\n'),
                    TextSpan(text: it.text, style: t.bodyMedium),
                  ])),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: QianColors.inkCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: QianColors.rice)), ...children],
      ),
    );
  }
}
