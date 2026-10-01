import 'package:flutter/widgets.dart';

enum FeaturePlacement { primary, secondary }

/// 首頁入口。每個功能是 lib/features/ 下的一個資料夾，對外只公開一個 AppFeature。
class AppFeature {
  const AppFeature({
    required this.id,
    required this.label,
    required this.placement,
    required this.builder,
  });

  final String id;
  final String label;
  final FeaturePlacement placement;
  final WidgetBuilder builder;
}
