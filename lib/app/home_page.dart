import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/premium/ad_banner.dart';
import '../shared/premium/paywall_page.dart';

import '../shared/widgets/card_back.dart';
import '../l10n/l10n.dart';
import 'feature_registry.dart';
import 'services.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final features = activeFeatures(AppServices.of(context).flags).toList();
    final primary = features.where((f) => f.placement == FeaturePlacement.primary && f.builder != null);
    final secondary = features.where((f) => f.placement == FeaturePlacement.secondary && f.builder != null);

    void open(AppFeature f) => Navigator.of(context).push(MaterialPageRoute<void>(builder: f.builder!));

    // 0.1.0+16：整頁一定一屏顯示完（不捲動）。主內容放在 FittedBox 裡，螢幕矮或系統字體放大時
    // 等比縮小；免責聲明固定貼在底部，不會被擠到畫面外。
    return Scaffold(
      bottomNavigationBar: const AdBanner(), // 免費版底部橫幅（§23）
      body: SafeArea(
        child: Stack(children: [
          LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth - 56,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 168,
                              child: AspectRatio(aspectRatio: 0.62, child: CardBack()),
                            ),
                            const SizedBox(height: 32),
                            Text(l.appTitle, style: t.displaySmall),
                            const SizedBox(height: 6),
                            Text(l.appSubtitle, style: t.titleSmall?.copyWith(color: QianColors.earth, letterSpacing: tracking(4))),
                            const SizedBox(height: 16),
                            Text(l.homeMotto,
                                textAlign: TextAlign.center,
                                style: t.bodyLarge?.copyWith(color: QianColors.textSub, fontSize: 15)),
                            const SizedBox(height: 32),
                            for (final f in primary)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: FilledButton(onPressed: () => open(f), child: Text(f.label(l))),
                              ),
                            for (final f in secondary)
                              TextButton(onPressed: () => open(f), child: Text(f.label(l))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l.homeDisclaimer,
                  style: t.bodySmall?.copyWith(fontSize: 11, color: QianColors.textSub.withValues(alpha: 0.75)),
                ),
              ),
            ],
          ),
        ),
          const PositionedDirectional(top: 4, end: 4, child: _HomeMenu()),
        ]),
      ),
    );
  }
}

enum _MenuItem { premium, adPrivacy, privacyPolicy }

/// 首頁右上角選單：謙卦會員、廣告隱私設定（需要同意的地區才出現）、隱私權政策。
class _HomeMenu extends StatelessWidget {
  const _HomeMenu();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = AppServices.of(context);
    return PopupMenuButton<_MenuItem>(
      icon: const Icon(Icons.more_vert, color: QianColors.textSub),
      onSelected: (item) {
        switch (item) {
          case _MenuItem.premium:
            openPaywall(context, source: 'menu');
          case _MenuItem.adPrivacy:
            s.ads.showPrivacyOptions();
          case _MenuItem.privacyPolicy:
            launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _MenuItem.premium, child: Text(l.menuPremium)),
        if (s.ads.privacyOptionsRequired && !s.isPremium)
          PopupMenuItem(value: _MenuItem.adPrivacy, child: Text(l.menuAdPrivacy)),
        PopupMenuItem(value: _MenuItem.privacyPolicy, child: Text(l.menuPrivacyPolicy)),
      ],
    );
  }
}

/// 隱私權政策（本 repo GitHub Pages，§20）。
const privacyPolicyUrl = 'https://lawrence124875.github.io/iching-cards/privacy.html';
