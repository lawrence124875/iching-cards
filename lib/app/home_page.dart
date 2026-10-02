import 'package:flutter/material.dart';

import '../shared/widgets/card_back.dart';
import 'feature_registry.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primary = registeredFeatures.where((f) => f.placement == FeaturePlacement.primary && f.builder != null);
    final secondary = registeredFeatures.where((f) => f.placement == FeaturePlacement.secondary && f.builder != null);

    void open(AppFeature f) => Navigator.of(context).push(MaterialPageRoute<void>(builder: f.builder!));

    // 0.1.0+16：整頁一定一屏顯示完（不捲動）。主內容放在 FittedBox 裡，螢幕矮或系統字體放大時
    // 等比縮小；免責聲明固定貼在底部，不會被擠到畫面外。
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
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
                            Text('謙卦', style: t.displaySmall),
                            const SizedBox(height: 6),
                            Text('易經六十四卦卡', style: t.titleSmall?.copyWith(color: QianColors.earth, letterSpacing: 4)),
                            const SizedBox(height: 16),
                            Text('易經不是用來算命，\n而是練習看象與做決定。',
                                textAlign: TextAlign.center,
                                style: t.bodyLarge?.copyWith(color: QianColors.textSub, fontSize: 15)),
                            const SizedBox(height: 32),
                            for (final f in primary)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: FilledButton(onPressed: () => open(f), child: Text(f.label)),
                              ),
                            for (final f in secondary)
                              TextButton(onPressed: () => open(f), child: Text(f.label)),
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
                  '內容僅供自我探索與娛樂參考',
                  style: t.bodySmall?.copyWith(fontSize: 11, color: QianColors.textSub.withValues(alpha: 0.75)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
