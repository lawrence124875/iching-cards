import 'package:flutter/material.dart';

/// 寫下或修改「想問的事」。回傳 null 表示取消；空字串表示清除。
Future<String?> askQuestion(BuildContext context, {String initial = '', String title = '想問的事'}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: 200,
        decoration: const InputDecoration(hintText: '用一兩句話寫下心裡想著的事（可不填）'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('好')),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// 起卦前的「想問的事」入口：未填時是一個小連結，填了就顯示內容（點擊可修改）。
class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt({super.key, required this.question, required this.onChanged, this.enabled = true});

  final String question;
  final ValueChanged<String> onChanged;
  final bool enabled;

  Future<void> _edit(BuildContext context) async {
    final q = await askQuestion(context, initial: question);
    if (q != null) onChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (question.isEmpty) {
      if (!enabled) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.edit_note, size: 20),
        label: const Text('寫下想問的事（可不填）'),
      );
    }
    return InkWell(
      onTap: enabled ? () => _edit(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text('問：$question',
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
      ),
    );
  }
}
