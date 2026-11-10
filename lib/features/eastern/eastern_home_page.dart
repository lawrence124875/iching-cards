import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/content/eastern_content.dart';
import '../../core/eastern/birth_profile.dart';
import '../../l10n/l10n.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'birth_setup_page.dart';
import 'birth_store.dart';
import 'ziwei_year_page.dart';

/// 東方命理入口：簡介、出生資料、年度基調（紫微）。
class EasternHomePage extends StatefulWidget {
  const EasternHomePage({super.key});

  @override
  State<EasternHomePage> createState() => _EasternHomePageState();
}

class _EasternHomePageState extends State<EasternHomePage> {
  late final Future<EasternContent?> _content = () async {
    await BirthStore.load();
    return easternSource.load(L10n.language.contentFolder);
  }();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureEastern)),
      bottomNavigationBar: const AdBanner(),
      body: FutureBuilder<EasternContent?>(
        future: _content,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final ec = snap.data;
          if (ec == null) return Center(child: Text(l.learnMissing));
          return ValueListenableBuilder<BirthProfile?>(
            valueListenable: BirthStore.current,
            builder: (context, p, _) => ListView(
              padding: readablePadding(context, top: 16, bottom: 32),
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 48, color: QianColors.earth),
                const SizedBox(height: 12),
                Text(ec.s('intro'), style: t.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (p == null) ...[
                  Text(ec.s('setup.needSetup'), textAlign: TextAlign.center, style: t.bodySmall),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton(
                      onPressed: () => openBirthSetup(context, ec),
                      child: Text(ec.s('setup.setupButton')),
                    ),
                  ),
                ] else ...[
                  EasternEntry(
                    icon: Icons.wb_twilight_outlined,
                    title: ec.s('ziwei.entry'),
                    subtitle: ec.s('ziwei.entrySub'),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => ZiweiYearPage(profile: p))),
                  ),
                  const SizedBox(height: 24),
                  Text(birthSummary(ec, p), textAlign: TextAlign.center, style: t.bodySmall),
                  Center(
                    child: TextButton(
                      onPressed: () => openBirthSetup(context, ec),
                      child: Text(ec.s('setup.edit')),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 出生資料摘要（例如「1990-05-20 08:30」）。
String birthSummary(EasternContent ec, BirthProfile p) {
  final date = '${p.year}-${_two(p.month)}-${_two(p.day)}';
  return p.hasHour
      ? ec.s('setup.summary', {'date': date, 'time': '${_two(p.hour!)}:${_two(p.minute)}'})
      : ec.s('setup.summaryNoTime', {'date': date});
}

Future<void> openBirthSetup(BuildContext context, EasternContent ec) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => BirthSetupPage(ec: ec, initial: BirthStore.current.value)));

class EasternEntry extends StatelessWidget {
  const EasternEntry({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

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
