import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'app_review.dart';

/// Google Play In-App Review（iOS 為 SKStoreReviewController）。**唯一 import in_app_review 的檔案**。
/// 側載、自用版、沒有 Play 時 isAvailable 為 false 或請求無聲失敗，不影響使用。
class StoreAppReview implements AppReview {
  const StoreAppReview();

  @override
  Future<void> request() async {
    try {
      final r = InAppReview.instance;
      if (await r.isAvailable()) await r.requestReview();
    } catch (e) {
      debugPrint('評分邀請失敗：$e');
    }
  }
}
