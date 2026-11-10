import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/content/eastern_content.dart';
import '../../core/eastern/birth_profile.dart';
import '../../core/meihua/solar_time.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'birth_store.dart';

/// 出生資料：國曆生日、出生時間（可勾「不知道」）、出生城市（選填，真太陽時）。只存手機。
class BirthSetupPage extends StatefulWidget {
  const BirthSetupPage({super.key, required this.ec, this.initial});

  final EasternContent ec;
  final BirthProfile? initial;

  @override
  State<BirthSetupPage> createState() => _BirthSetupPageState();
}

class _BirthSetupPageState extends State<BirthSetupPage> {
  late DateTime _date = widget.initial == null
      ? DateTime(1990, 1, 1)
      : DateTime(widget.initial!.year, widget.initial!.month, widget.initial!.day);
  late TimeOfDay? _time = widget.initial?.hour == null
      ? (widget.initial == null ? const TimeOfDay(hour: 12, minute: 0) : null)
      : TimeOfDay(hour: widget.initial!.hour!, minute: widget.initial!.minute);
  late bool _unknown = widget.initial != null && widget.initial!.hour == null;
  late String? _cityId = widget.initial?.cityId;

  EasternContent get ec => widget.ec;

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0));
    if (t != null) setState(() => _time = t);
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: QianColors.inkCard,
      builder: (ctx) => SafeArea(
        child: ListView(children: [
          ListTile(
            title: Text(ec.s('setup.cityNone')),
            trailing: _cityId == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, 'off'),
          ),
          for (final c in MeihuaCities.all)
            ListTile(
              title: Text(c.name),
              trailing: _cityId == c.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, c),
            ),
        ]),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _cityId = picked is MeihuaCity ? picked.id : null);
  }

  Future<void> _save() async {
    final t = _unknown ? null : (_time ?? const TimeOfDay(hour: 12, minute: 0));
    await BirthStore.save(BirthProfile(
      year: _date.year,
      month: _date.month,
      day: _date.day,
      hour: t?.hour,
      minute: t?.minute ?? 0,
      cityId: _unknown ? null : _cityId,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ec.s('setup.deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ec.s('setup.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ec.s('setup.delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await BirthStore.save(null);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final city = MeihuaCities.byId(_cityId);
    return Scaffold(
      appBar: AppBar(title: Text(ec.s('setup.title'))),
      body: ListView(
        padding: readablePadding(context, top: 16, bottom: 40),
        children: [
          Text(ec.s('setup.intro'), style: t.bodySmall),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ec.s('setup.date')),
            subtitle: Text('${_date.year}-${_two(_date.month)}-${_two(_date.day)}'),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: !_unknown,
            title: Text(ec.s('setup.time')),
            subtitle: Text(_unknown || _time == null ? '—' : '${_two(_time!.hour)}:${_two(_time!.minute)}'),
            trailing: const Icon(Icons.schedule),
            onTap: _unknown ? null : _pickTime,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _unknown,
            onChanged: (v) => setState(() => _unknown = v ?? false),
            title: Text(ec.s('setup.unknownTime')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_unknown) Text(ec.s('setup.unknownTimeNote'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          if (!_unknown) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ec.s('setup.city')),
              subtitle: Text(city?.name ?? ec.s('setup.cityNone')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCity,
            ),
            Text(ec.s('setup.timeNote'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          ],
          const SizedBox(height: 28),
          Center(child: FilledButton(onPressed: _save, child: Text(ec.s('setup.save')))),
          if (widget.initial != null) ...[
            const SizedBox(height: 12),
            Center(child: TextButton(onPressed: _delete, child: Text(ec.s('setup.delete')))),
          ],
        ],
      ),
    );
  }
}
