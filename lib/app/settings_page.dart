import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../shared/premium/ad_banner.dart';
import '../shared/widgets/adaptive_layout.dart';
import '../shared/widgets/daily_reminder_dialog.dart';
import 'services.dart';
import 'theme.dart';

/// 隱私權政策（本 repo GitHub Pages，§20）。
const privacyPolicyUrl = 'https://lawrence124875.github.io/iching-cards/privacy.html';

/// 服務條款（本 repo docs/terms.html，2026-11-02；訂閱、試用、退款、免責）。
const termsOfServiceUrl = 'https://lawrence124875.github.io/iching-cards/terms.html';

/// 設定（0.8.0 從首頁選單拆出）：每日一卦提醒、分享匿名使用統計、廣告隱私設定（需要同意的地區才出現）、隱私權政策、服務條款。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppServices.of(context);
    final usage = s.usage;
    return Scaffold(
      appBar: AppBar(title: Text(l.menuSettings)),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: readablePadding(context, horizontal: 8, top: 8, bottom: 32),
        children: [
          if (s.dailyStore != null)
            ListTile(
              leading: const Icon(Icons.notifications_none, color: QianColors.earth),
              title: Text(l.menuDailyReminder),
              onTap: () => showDailyReminderDialog(context),
            ),
          if (usage != null)
            ValueListenableBuilder<bool>(
              valueListenable: usage.enabled,
              builder: (context, on, _) => SwitchListTile(
                secondary: const Icon(Icons.insights_outlined, color: QianColors.earth),
                title: Text(l.menuShareUsage),
                value: on,
                onChanged: (v) => usage.set(v),
              ),
            ),
          if (s.ads.privacyOptionsRequired && !s.isPremium)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: QianColors.earth),
              title: Text(l.menuAdPrivacy),
              onTap: () => s.ads.showPrivacyOptions(),
            ),
          ListTile(
            leading: const Icon(Icons.policy_outlined, color: QianColors.earth),
            title: Text(l.menuPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: QianColors.earth),
            title: Text(l.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(termsOfServiceUrl), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}
