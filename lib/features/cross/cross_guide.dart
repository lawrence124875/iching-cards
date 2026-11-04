import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/theme.dart';
import '../../core/content/cross_content.dart';
import '../../l10n/l10n.dart';

/// 雙卦交叉的 3 頁引導（內容在 iching-content `<語言>/cross/templates.json` 的 `guide`）。
/// 第一次進入時自動顯示（看過的記號存在 App 文件資料夾 `cross_guide_seen.txt`），交叉頁右上 ⓘ 可重看。
Future<void> showCrossGuideOnce(BuildContext context) async {
  File? f;
  try {
    f = File('${(await getApplicationDocumentsDirectory()).path}/cross_guide_seen.txt');
    if (await f.exists()) return;
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final shown = await showCrossGuide(context);
  if (shown) {
    try {
      await f.writeAsString('1');
    } catch (_) {}
  }
}

/// 顯示引導；內容讀不到時回傳 false。
Future<bool> showCrossGuide(BuildContext context) async {
  final cc = await crossSource.load(L10n.language.contentFolder);
  final pages = cc?.guide ?? const [];
  if (cc == null || pages.isEmpty || !context.mounted) return false;
  await showDialog<void>(context: context, builder: (_) => _GuideDialog(cc: cc, pages: pages));
  return true;
}

class _GuideDialog extends StatefulWidget {
  const _GuideDialog({required this.cc, required this.pages});

  final CrossContent cc;
  final List<({String title, String body})> pages;

  @override
  State<_GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<_GuideDialog> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = widget.pages[_i];
    final last = _i == widget.pages.length - 1;
    return AlertDialog(
      title: Text(p.title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.body, style: t.bodyMedium),
          const SizedBox(height: 16),
          Center(
            child: Text('${_i + 1} / ${widget.pages.length}',
                style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          ),
        ]),
      ),
      actions: [
        FilledButton(
          onPressed: () => last ? Navigator.pop(context) : setState(() => _i++),
          child: Text(widget.cc.s(last ? 'guideDone' : 'guideNext')),
        ),
      ],
    );
  }
}
