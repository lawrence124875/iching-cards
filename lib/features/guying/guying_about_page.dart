import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../core/guying/guying.dart';
import '../../l10n/l10n.dart';
import '../../reading/section.dart';
import '../../shared/widgets/adaptive_layout.dart';

/// 原書在 Wikimedia Commons 的頁面（哈佛燕京圖書館藏本，Public domain）。
const guyingSourceUrl = 'https://commons.wikimedia.org/wiki/Category:%E6%96%B7%E6%98%93%E5%A4%A9%E6%A9%9F';

/// 關於古圖：出處、如何看卦影；最上面可直接打開／關閉「顯示古圖」。
class GuyingAboutPage extends StatelessWidget {
  const GuyingAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pref = AppServices.of(context).guying;
    return Scaffold(
      appBar: AppBar(title: Text(l.guyingAbout)),
      body: FutureBuilder<GuyingContent?>(
        future: guyingSource.load(L10n.contentFolder),
        builder: (context, snap) {
          final c = snap.data;
          return ListView(
            padding: readablePadding(context, top: 8, bottom: 40),
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: pref.enabled,
                builder: (context, on, _) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.guyingToggle),
                  subtitle: Text(l.guyingToggleHint),
                  value: on,
                  onChanged: pref.set,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(GuyingSource.imagePath(15),
                    fit: BoxFit.fitWidth, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              if (c != null)
                for (final s in c.about) Section(title: s.heading, child: Text(s.body)),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l.guyingViewSource),
                  onPressed: () => launchUrl(Uri.parse(guyingSourceUrl), mode: LaunchMode.externalApplication),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
