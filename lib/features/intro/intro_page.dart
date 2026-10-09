import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

/// 功能介紹：首次開啟時顯示一次（可略過），之後可從首頁右上角選單重看。
/// 四頁：抽卦／擲錢、卦記、呼吸音景（432Hz、7.83Hz 雙耳節拍）、分享與會員。
/// 文案只描述做法，不寫任何療效（Google Play 健康宣稱政策，HANDOFF §14.2）。
Future<void> showIntro(NavigatorState navigator) => navigator.push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const IntroPage(),
    ));

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _index = 0;

  static const _icons = [Icons.style_outlined, Icons.bookmark_outline, Icons.air, Icons.ios_share];

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
    final pages = [
      (l.intro1Title, l.intro1Body),
      (l.intro2Title, l.intro2Body),
      (l.intro3Title, l.intro3Body),
      (l.intro4Title, l.intro4Body),
    ];
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
                            Icon(_icons[i], size: 72, color: QianColors.earth),
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
