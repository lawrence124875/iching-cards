import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/lessons.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'lesson_page.dart';

/// 課程列表：前 [freeLessonCount] 課免費，其餘未訂閱時顯示鎖頭，點了開訂閱頁（source：lesson）。
class LessonListPage extends StatelessWidget {
  const LessonListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppServices.of(context);
    final folder = L10n.language.contentFolder;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.featureLearn)),
      bottomNavigationBar: const AdBanner(),
      body: ValueListenableBuilder<bool>(
        valueListenable: s.premium.isPremium,
        builder: (context, premium, _) => FutureBuilder<List<Lesson?>>(
          future: Future.wait([
            for (var id = 1; id <= lessonCount; id++) lessonSource.load(folder, id).then((r) => r?.$1),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final lessons = snap.data!.whereType<Lesson>().toList();
            return ListView.separated(
              padding: readablePadding(context, horizontal: 16, top: 8, bottom: 32),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: QianColors.inkCard),
              itemBuilder: (context, i) =>
                  _Tile(lesson: lessons[i], locked: !premium && !lessonIsFree(lessons[i].id)),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.lesson, required this.locked});

  final Lesson lesson;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: QianColors.inkCard,
        foregroundColor: QianColors.earth,
        child: Text('${lesson.id}'),
      ),
      title: Text(lesson.title, style: t.titleMedium),
      subtitle: Text(lesson.subtitle, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
      trailing: locked
          ? Icon(Icons.lock_outline, color: QianColors.textSub, semanticLabel: l.learnLocked)
          : lessonIsFree(lesson.id)
              ? Text(l.learnFree, style: t.labelSmall?.copyWith(color: QianColors.rice))
              : null,
      onTap: () async {
        if (locked && !await openPaywall(context, source: 'lesson', note: l.learnPaywallNote)) return;
        if (!context.mounted) return;
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonPage(id: lesson.id)));
      },
    );
  }
}
