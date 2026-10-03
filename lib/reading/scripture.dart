import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 經文：非中文語言顯示「漢字原文（小字、灰穗、宋體）＋譯文」（HANDOFF §22）。
/// [original] 為空或與譯文相同（中文語言）時只顯示 [text]。
class Scripture extends StatelessWidget {
  const Scripture({super.key, required this.text, this.original = '', this.style});

  final String text;
  final String original;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final body = style ?? Theme.of(context).textTheme.bodyLarge;
    if (original.isEmpty || original == text) return Text(text, style: body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(original,
            style: TextStyle(fontFamily: kSerif, fontSize: 14.5, height: 1.7, color: QianColors.textSub)),
        const SizedBox(height: 4),
        Text(text, style: body),
      ],
    );
  }
}
