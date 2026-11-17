import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/feedback/feedback_page.dart';
import '../features/guying/guying_about_page.dart';
import '../features/intro/intro_page.dart';
import '../features/journal/journal_backup_menu.dart';
import '../features/share/share.dart';
import '../l10n/l10n.dart';
import '../shared/premium/paywall_page.dart';
import '../shared/premium/ad_banner.dart';
import '../shared/widgets/adaptive_layout.dart';
import '../shared/widgets/daily_reminder_dialog.dart';
import 'services.dart';
import 'theme.dart';

/// 隱私權政策（本 repo GitHub Pages，§20）。
const privacyPolicyUrl = 'https://lawrence124875.github.io/iching-cards/privacy.html';

/// 服務條款（本 repo docs/terms.html，2026-11-02；訂閱、試用、退款、免責）。
const termsOfServiceUrl = 'https://lawrence124875.github.io/iching-cards/terms.html';

/// 設定（0.8.0 從首頁選單拆出；0.9.0 起首頁右上角齒輪進入，原選單的會員、功能介紹、推薦、意見回饋也併入）：
/// 每日一卦提醒、分享匿名使用統計、廣告隱私設定（需要同意的地區才出現）、隱私權政策、服務條款。
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
          if (!s.isPremium)
            ListTile(
              leading: Icon(Icons.workspace_premium_outlined, color: QianColors.earth),
              title: Text(l.menuPremium),
              onTap: () => openPaywall(context, source: 'menu'),
            ),
          ListTile(
            leading: const Icon(Icons.phonelink_setup_outlined),
            title: Text(l.menuBackupMove),
            subtitle: Text(l.menuBackupMoveHint),
            onTap: () => _backupSheet(context),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: QianColors.earth),
            title: Text(l.menuIntro),
            onTap: () => showIntro(Navigator.of(context), full: true),
          ),
          ListTile(
            leading: Icon(Icons.ios_share, color: QianColors.earth),
            title: Text(l.menuShareApp),
            onTap: () => shareApp(context),
          ),
          if (s.feedback != null)
            ListTile(
              leading: Icon(Icons.mail_outline, color: QianColors.earth),
              title: Text(l.menuFeedback),
              onTap: () => openFeedback(context),
            ),
          const Divider(),
          if (s.dailyStore != null)
            ListTile(
              leading: Icon(Icons.notifications_none, color: QianColors.earth),
              title: Text(l.menuDailyReminder),
              onTap: () => showDailyReminderDialog(context),
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: s.theme.mode,
            builder: (context, mode, _) => ListTile(
              leading: Icon(Icons.contrast, color: QianColors.earth),
              title: Text(l.appearance),
              subtitle: Text(_modeLabel(l, mode)),
              onTap: () => _pickAppearance(context, s, mode),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: s.guying.enabled,
            builder: (context, on, _) => SwitchListTile(
              secondary: Icon(Icons.image_outlined, color: QianColors.earth),
              title: Text(l.guyingToggle),
              subtitle: Text(l.guyingToggleHint),
              value: on,
              onChanged: s.guying.set,
            ),
          ),
          ListTile(
            leading: Icon(Icons.menu_book_outlined, color: QianColors.earth),
            title: Text(l.guyingAbout),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const GuyingAboutPage())),
          ),
          if (usage != null)
            ValueListenableBuilder<bool>(
              valueListenable: usage.enabled,
              builder: (context, on, _) => SwitchListTile(
                secondary: Icon(Icons.insights_outlined, color: QianColors.earth),
                title: Text(l.menuShareUsage),
                value: on,
                onChanged: (v) => usage.set(v),
              ),
            ),
          if (s.ads.privacyOptionsRequired && !s.isPremium)
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: QianColors.earth),
              title: Text(l.menuAdPrivacy),
              onTap: () => s.ads.showPrivacyOptions(),
            ),
          ListTile(
            leading: Icon(Icons.policy_outlined, color: QianColors.earth),
            title: Text(l.menuPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: QianColors.earth),
            title: Text(l.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(termsOfServiceUrl), mode: LaunchMode.externalApplication),
          ),
          // LC Lab 其他 App：圖示在 assets/other_apps（不連網抓），以外部應用程式開 Play 商店頁；不加權限、不追蹤。
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(l.otherAppsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: QianColors.earth)),
          ),
          _OtherApp(
            icon: 'assets/other_apps/tarot.png',
            name: l.otherAppTarotName,
            desc: l.otherAppTarotDesc,
            url: 'https://play.google.com/store/apps/details?id=com.lclab.tarot',
          ),
          _OtherApp(
            icon: 'assets/other_apps/english.png',
            name: l.otherAppEnglishName,
            desc: l.otherAppEnglishDesc,
            url: 'https://play.google.com/store/apps/details?id=tw.bcc.englishapp',
          ),
          // 奇門羅盤：上架後在 Remote Config 把 qg_other_app_qimen 設為 1 才顯示（預設不顯示，避免商店頁還沒開）
          if (s.flags.intValue('qg_other_app_qimen', 0) == 1)
            _OtherApp(
              icon: 'assets/other_apps/qimen.png',
              name: l.otherAppQimenName,
              desc: l.otherAppQimenDesc,
              url: 'https://play.google.com/store/apps/details?id=com.lclab.qimen',
            ),
        ],
      ),
    );
  }

  static String _modeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
        ThemeMode.light => l.appearanceLight,
        ThemeMode.dark => l.appearanceDark,
        ThemeMode.system => l.appearanceSystem,
      };

  /// 外觀三選一（跟隨系統／淺色／深色），選了立即套用。
  static Future<void> _pickAppearance(BuildContext context, Services s, ThemeMode current) async {
    final l = context.l10n;
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.appearance),
        children: [
          for (final m in const [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(m),
              child: Row(children: [
                Icon(m == current ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 20, color: QianColors.earth),
                const SizedBox(width: 16),
                Expanded(child: Text(_modeLabel(l, m))),
              ]),
            ),
        ],
      ),
    );
    if (picked != null && picked != current) await s.theme.set(picked);
  }
}

/// 備份與換手機：匯出／還原卦記與設定（與卦記列表選單同一套）。
void _backupSheet(BuildContext context) {
  final l = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: Text(l.journalMenuBackup),
          onTap: () {
            Navigator.pop(sheet);
            JournalBackupMenu.backup(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l.journalMenuRestore),
          onTap: () {
            Navigator.pop(sheet);
            JournalBackupMenu.restore(context);
          },
        ),
      ]),
    ),
  );
}

/// 設定頁「LC Lab 其他 App」的一列：圖示、名稱、一句說明。
class _OtherApp extends StatelessWidget {
  const _OtherApp({required this.icon, required this.name, required this.desc, required this.url});

  final String icon;
  final String name;
  final String desc;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(icon, width: 44, height: 44),
        ),
        title: Text(name),
        subtitle: Text(desc),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
}
