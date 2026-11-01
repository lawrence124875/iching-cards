import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/lessons.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'lesson_course.dart';
import 'lesson_page.dart';

/// 課程列表：前幾課免費（[LessonCourse.freeCount]），其餘未訂閱時顯示鎖頭，點了開訂閱頁。
class LessonListPage extends StatelessWidget {
  const LessonListPage({super.key, this.course});

  /// 不傳＝易經學習課程。
  final LessonCourse? course;

  @override
  Widget build(BuildContext context) {
    final s = AppServices.of(context);
    final folder = L10n.language.contentFolder;
    final c = course ?? ichingCourse;
    return Scaffold(
      appBar: AppBar(title: Text(c.title(context))),
      bottomNavigationBar: const AdBanner(),
      body: ValueListenableBuilder<bool>(
        valueListenable: s.premium.isPremium,
        builder: (context, premium, _) => FutureBuilder<List<Lesson?>>(
          future: Future.wait([
            for (var id = 1; id <= c.count; id++) lessonSource.load(folder, id, prefix: c.prefix).then((r) => r?.$1),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final lessons = snap.data!.whereType<Lesson>().toList();
            return ListView.separated(
              padding: readablePadding(context, horizontal: 16, top: 8, bottom: 32),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: QianColors.inkCard),
              itemBuilder: (context, i) =>
                  _Tile(course: c, lesson: lessons[i], locked: !premium && !c.isFree(context, lessons[i].id)),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.course, required this.lesson, required this.locked});

  final LessonCourse course;
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
          : course.isFree(context, lesson.id)
              ? Text(l.learnFree, style: t.labelSmall?.copyWith(color: QianColors.rice))
              : null,
      onTap: () async {
        if (locked && !await openPaywall(context, source: course.paywallSource, note: course.paywallNote(context))) {
          return;
        }
        if (!context.mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => LessonPage(id: lesson.id, course: course)));
      },
    );
  }
}
