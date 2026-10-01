import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../reading/reading_page.dart';
import '../../shared/widgets/hexagram_glyph.dart';

const _lineNames = ['初', '二', '三', '四', '五', '上'];

/// 擲錢起卦：三枚銅錢擲六次，由初爻往上；含變爻與之卦。
class CoinCastPage extends StatefulWidget {
  const CoinCastPage({super.key});

  @override
  State<CoinCastPage> createState() => _CoinCastPageState();
}

class _CoinCastPageState extends State<CoinCastPage> {
  static const _method = ThreeCoins();
  final List<CoinToss> _tosses = [];

  bool get _done => _tosses.length == 6;

  void _toss() {
    if (_done) return;
    setState(() => _tosses.add(_method.tossOnce(AppServices.of(context).random)));
  }

  void _tossAll() {
    final r = AppServices.of(context).random;
    setState(() {
      while (_tosses.length < 6) {
        _tosses.add(_method.tossOnce(r));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lines = [for (final x in _tosses) x.line];
    final padded = [...lines.map((l) => l.isYang), ...List.filled(6 - lines.length, false)];
    final changing = {for (var i = 0; i < lines.length; i++) if (lines[i].isChanging) i + 1};

    return Scaffold(
      appBar: AppBar(title: const Text('三枚銅錢起卦')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          children: [
            Text(
              '每次擲三枚銅錢：陽面記 3、陰面記 2，三枚相加得一爻。'
              '共擲六次，由最下面的初爻往上排。6 與 9 是會變的爻。',
              style: t.bodyMedium?.copyWith(color: QianColors.textSub),
            ),
            const SizedBox(height: 28),
            Center(
              child: HexagramGlyph(
                lines: padded,
                changing: changing,
                width: 120,
                visibleCount: lines.length,
              ),
            ),
            const SizedBox(height: 28),
            for (var i = lines.length - 1; i >= 0; i--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text('${_lineNames[i]}爻', style: t.titleMedium)),
                    Text(_tosses[i].coins.join(' + '), style: t.bodySmall),
                    const Spacer(),
                    Text(
                      '${lines[i].value}　${lines[i].label}${lines[i].isChanging ? '（變）' : ''}',
                      style: t.bodyMedium?.copyWith(
                        color: lines[i].isChanging ? QianColors.rice : QianColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            if (!_done) ...[
              FilledButton(onPressed: _toss, child: Text('擲第 ${_tosses.length + 1} 次')),
              const SizedBox(height: 4),
              TextButton(onPressed: _tossAll, child: const Text('一次擲完')),
            ] else ...[
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ReadingPage(cast: CastResult(methodId: _method.id, lines: lines)),
                )),
                child: const Text('看解讀'),
              ),
              const SizedBox(height: 4),
              TextButton(onPressed: () => setState(_tosses.clear), child: const Text('重新起卦')),
            ],
          ],
        ),
      ),
    );
  }
}
