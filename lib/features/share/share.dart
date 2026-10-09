import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/card_face.dart';

/// Google Play 商店頁（分享文字附上的下載連結）。
const storeUrl = 'https://play.google.com/store/apps/details?id=com.lclab.qiangua';

/// 分享面板在 iPad 上要知道從哪裡彈出；手機上不影響。
Rect? _origin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}

/// 推薦給朋友：分享一段文字＋商店連結。
Future<void> shareApp(BuildContext context) async {
  final l = context.l10n;
  final origin = _origin(context);
  try {
    await SharePlus.instance.share(ShareParams(text: l.shareAppText(storeUrl), sharePositionOrigin: origin));
  } catch (_) {
    if (context.mounted) _failed(context);
  }
}

/// 分享這一卦：預覽卦象卡片，按「分享圖片」後輸出 PNG 並附上文字與商店連結。
/// 卡片只放卦面、卦名與這組解讀的標題與卦象，不放使用者寫的問題（隱私）。
Future<void> showShareReading(
  BuildContext context, {
  required HexagramInfo info,
  String? title,
  String? image,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ShareDialog(info: info, title: title, image: image),
    );

void _failed(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.shareFailed)));

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.info, this.title, this.image});

  final HexagramInfo info;
  final String? title;
  final String? image;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final origin = _origin(context);
    setState(() => _busy = true);
    try {
      final boundary = _card.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final file = File('${(await getTemporaryDirectory()).path}/qiangua_${widget.info.number}.png');
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      final name = l.hexFullName(widget.info);
      final text = widget.title == null ? l.shareAppText(storeUrl) : l.shareReadingText(name, widget.title!, storeUrl);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: origin,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.shareFailed)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      content: SizedBox(
        width: 300,
        child: FittedBox(
          child: RepaintBoundary(
            key: _card,
            child: ShareCard(info: widget.info, title: widget.title, image: widget.image),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share, size: 18),
          label: Text(l.shareImage),
        ),
      ],
    );
  }
}

/// 分享用的卦象卡片（固定 360×640 邏輯像素，輸出時 3 倍＝1080×1920）。
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.info, this.title, this.image});

  final HexagramInfo info;
  final String? title;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Container(
      width: 360,
      height: 640,
      color: QianColors.ink,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Column(
        children: [
          SizedBox(width: 240, child: AspectRatio(aspectRatio: 0.62, child: CardFace(info: info))),
          const SizedBox(height: 18),
          if (title != null)
            Text(title!,
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleLarge),
          if (image != null) ...[
            const SizedBox(height: 10),
            // 卦象文字：依剩下的高度決定行數，最後一行以「…」收尾（不在半行處被切掉）
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final style = t.bodyMedium?.copyWith(color: QianColors.textSub);
                final line = (style?.fontSize ?? 14) * (style?.height ?? 1.4) * MediaQuery.textScalerOf(context).scale(1);
                final lines = (box.maxHeight / line).floor().clamp(1, 6);
                return Text(image!,
                    textAlign: TextAlign.center, maxLines: lines, overflow: TextOverflow.ellipsis, style: style);
              }),
            ),
          ] else
            const Spacer(),
          const SizedBox(height: 8),
          // 名稱與副標一行，太長時等比縮小（英文等副標較長的語言原本會折成兩行、靠邊）
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${l.appTitle}${l.separator}${l.appSubtitle}',
                maxLines: 1, style: t.bodySmall?.copyWith(color: QianColors.earth, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }
}
