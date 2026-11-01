import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../learn/lesson_list_page.dart';
import 'meihua_cast_page.dart';
import 'meihua_feature.dart';

/// 梅花易數入口：簡介、課程、起卦。
class MeihuaHomePage extends StatelessWidget {
  const MeihuaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureMeihua)),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: readablePadding(context, top: 16, bottom: 32),
        children: [
          const Icon(Icons.local_florist_outlined, size: 48, color: QianColors.earth),
          const SizedBox(height: 12),
          Text(l.meihuaIntro, style: t.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          _Entry(
            icon: Icons.menu_book_outlined,
            title: l.meihuaCourseTitle,
            subtitle: l.meihuaCourseSubtitle,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => LessonListPage(course: meihuaCourse))),
          ),
          const SizedBox(height: 12),
          _Entry(
            icon: Icons.blur_on_outlined,
            title: l.meihuaCastTitle,
            subtitle: l.meihuaCastSubtitle,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MeihuaCastPage())),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: QianColors.inkCard,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Icon(icon, color: QianColors.earth),
        title: Text(title, style: t.titleMedium),
        subtitle: Text(subtitle, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
        trailing: const Icon(Icons.chevron_right, color: QianColors.textSub),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
