import 'package:flutter/widgets.dart';

/// 處理通知等外部開啟（payload）；認得就導覽並回傳 true。
typedef PayloadHandler = bool Function(NavigatorState navigator, String payload);

enum FeaturePlacement { primary, secondary }

/// 首頁入口。每個功能是 lib/features/ 下的一個資料夾，對外只公開一個 AppFeature。
class AppFeature {
  const AppFeature({
    required this.id,
    required this.label,
    required this.placement,
    required this.builder,
    this.openPayload,
  });

  final String id;
  final String label;
  final FeaturePlacement placement;
  final WidgetBuilder builder;
  final PayloadHandler? openPayload;
}
