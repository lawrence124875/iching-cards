import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/updates/app_updates.dart';

void main() {
  test('沒有更新功能時（測試、iOS）：不提示、不下載', () async {
    const u = NoAppUpdates();
    expect(await u.available(), isFalse);
    expect(await u.download(), isFalse);
  });
}
