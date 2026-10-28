import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../l10n/l10n.dart';

/// 開 App 時檢查 Google Play 有沒有新版（每次啟動一次）；有就在底部提示「更新」，
/// 背景下載完成後再提示「重新啟動」安裝。
class UpdatePrompt extends StatefulWidget {
  const UpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  static bool _checked = false; // 整個 App 執行期間只檢查一次

  @override
  void initState() {
    super.initState();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final updates = AppServices.of(context).updates;
    if (!await updates.available() || !mounted) return;
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.updateAvailable),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(label: l.updateAction, onPressed: _download),
    ));
  }

  Future<void> _download() async {
    final updates = AppServices.of(context).updates;
    if (!await updates.download() || !mounted) return;
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.updateReady),
      duration: const Duration(days: 1), // 等使用者自己按
      action: SnackBarAction(label: l.updateRestart, onPressed: updates.install),
    ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
