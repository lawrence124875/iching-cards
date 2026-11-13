import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

/// 功能介紹：首次開啟時只顯示三頁核心（抽卦、卦記、分享與會員／免費規則，0.8.0），可略過；
/// 首頁右上角選單「功能介紹」看完整九頁（[full]）。其他功能第一次進入時各自說明（雙卦導覽、梅花 ⓘ）。
/// 五頁：抽卦／擲錢／蓍草、卦記（含備份）、呼吸音景（432Hz、7.83Hz 雙耳節拍）、分享與會員、選單（意見回饋、使用統計開關）。
/// 文案只描述做法，不寫任何療效（Google Play 健康宣稱政策，REFERENCE §14.2）。
Future<void> showIntro(NavigatorState navigator, {bool full = false}) => navigator.push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => IntroPage(full: full),
    ));

class IntroPage extends StatefulWidget {
  const IntroPage({super.key, this.full = false});

  /// true：完整九頁（選單重看）；false：首次開啟的三頁核心。
  final bool full;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _index = 0;

  static const _icons = [
    Icons.style_outlined,
    Icons.local_florist_outlined,
    Icons.compare_arrows,
    Icons.auto_awesome_outlined,
    Icons.menu_book_outlined,
    Icons.bookmark_outline,
    Icons.air,
    Icons.ios_share,
    Icons.mail_outline,
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// 略過或看完都算看過（返回鍵關閉也是，見 PopScope）。
  void _finish() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final all = [
      (l.intro1Title, l.intro1Body, _icons[0]),
      (l.introMeihuaTitle, l.introMeihuaBody, _icons[1]),
      (l.introCrossTitle, l.introCrossBody, _icons[2]),
      (l.introEasternTitle, l.introEasternBody, _icons[3]),
      (l.introLearnTitle, l.introLearnBody, _icons[4]),
      (l.intro2Title, l.intro2Body, _icons[5]),
      (l.intro3Title, l.intro3Body, _icons[6]),
      (l.intro4Title, l.intro4Body, _icons[7]),
      (l.intro5Title, l.intro5Body, _icons[8]),
    ];
    // 首次開啟：抽卦、卦記、分享與會員（含免費規則）
    final pages = widget.full ? all : [all[0], all[5], all[7]];
    final last = _index == pages.length - 1;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) AppServices.of(context).intro?.markSeen();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: last ? const SizedBox(height: 48) : TextButton(onPressed: _finish, child: Text(l.introSkip)),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            Icon(pages[i].$3, size: 72, color: QianColors.earth),
                            const SizedBox(height: 32),
                            Text(pages[i].$1, textAlign: TextAlign.center, style: t.headlineSmall),
                            const SizedBox(height: 20),
                            Text(pages[i].$2,
                                textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: QianColors.textSub)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? QianColors.earth : QianColors.mountain,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Text(last ? l.introStart : l.introNext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
