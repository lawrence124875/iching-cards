import 'package:flutter/material.dart';

import '../shared/widgets/card_back.dart';
import 'feature_registry.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primary = registeredFeatures.where((f) => f.placement == FeaturePlacement.primary);
    final secondary = registeredFeatures.where((f) => f.placement == FeaturePlacement.secondary);

    void open(AppFeature f) => Navigator.of(context).push(MaterialPageRoute<void>(builder: f.builder));

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              // minWidth 撐滿寬度，Column 才會水平置中（否則會靠左收縮）
              constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: box.maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      child: const AspectRatio(aspectRatio: 0.62, child: CardBack()),
                    ),
                    const SizedBox(height: 36),
                    Text('易經卦卡', style: t.displaySmall),
                    const SizedBox(height: 12),
                    Text('易經不是用來算命，\n而是練習看象與做決定。',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(color: QianColors.textSub, fontSize: 15)),
                    const SizedBox(height: 40),
                    for (final f in primary)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FilledButton(onPressed: () => open(f), child: Text(f.label)),
                      ),
                    for (final f in secondary)
                      TextButton(onPressed: () => open(f), child: Text(f.label)),
                    const SizedBox(height: 40),
                    Text('內容僅供自我探索與娛樂參考', style: t.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
