import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 選擇幾天後提醒回顧：不提醒／3／7／14／30 天／自訂。value 為 null 表示不提醒。
class ReminderPicker extends StatelessWidget {
  const ReminderPicker({super.key, required this.days, required this.onChanged});

  static const presets = [3, 7, 14, 30];

  final int? days;
  final ValueChanged<int?> onChanged;

  Future<void> _custom(BuildContext context) async {
    final c = TextEditingController(text: days?.toString() ?? '');
    final v = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('幾天後提醒？'),
        content: TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '天', hintText: '1～365'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(c.text.trim());
              if (n != null && n >= 1 && n <= 365) Navigator.pop(context, n);
            },
            child: const Text('好'),
          ),
        ],
      ),
    );
    c.dispose();
    if (v != null) onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final custom = days != null && !presets.contains(days);
    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: QianColors.earth,
          labelStyle: TextStyle(color: selected ? QianColors.ink : QianColors.text),
          showCheckmark: false,
        );
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip('不提醒', days == null, () => onChanged(null)),
        for (final d in presets) chip('$d 天', days == d, () => onChanged(d)),
        chip(custom ? '$days 天' : '自訂', custom, () => _custom(context)),
      ],
    );
  }
}
