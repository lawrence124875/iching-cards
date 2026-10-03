import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/app/feature_registry.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/telemetry/analytics.dart';
import 'package:iching_cards/core/telemetry/analytics_listener.dart';
import 'package:iching_cards/core/telemetry/remote_flags.dart';

class _Recorder implements Analytics {
  final logged = <(String, Map<String, Object>)>[];

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async => logged.add((name, params));
}

class _Off implements RemoteFlags {
  _Off(this.off);
  final Set<String> off;

  @override
  bool featureEnabled(String featureId) => !off.contains(featureId);
}

void main() {
  final events = <AppEvent>[
    const ReadingShown(methodId: 'coins', primary: 15, changed: 2),
    const JournalSaved(hasReminder: true),
    const BreathStarted(hexagram: 15, minutes: 3, silent: false, binaural: true),
    const BreathCompleted(hexagram: 15, minutes: 3),
  ];

  test('統計事件一律 qg_ 開頭、名稱合規、參數只有字串或數字', () {
    final valid = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');
    for (final e in events) {
      final d = AnalyticsListener.describe(e)!;
      expect(d.$1, startsWith('qg_'));
      expect(valid.hasMatch(d.$1), isTrue, reason: d.$1);
      expect(d.$2.length, lessThanOrEqualTo(25));
      for (final entry in d.$2.entries) {
        expect(valid.hasMatch(entry.key), isTrue, reason: entry.key);
        expect(entry.value is String || entry.value is num, isTrue, reason: entry.key);
      }
    }
  });

  test('事件匯流排的事件會轉送到統計', () async {
    final bus = EventBus();
    final rec = _Recorder();
    final listener = AnalyticsListener(bus, rec);
    events.forEach(bus.emit);
    await Future<void>.delayed(Duration.zero);
    expect(rec.logged.map((e) => e.$1), [
      'qg_reading_shown',
      'qg_journal_saved',
      'qg_breath_started',
      'qg_breath_completed',
    ]);
    expect(rec.logged.first.$2, {'method': 'coins', 'hexagram': 15, 'has_changed': 1});
    await listener.dispose();
  });

  test('遠端開關：參數名稱 qg_feature_<id>，預設全開，關掉的功能不出現在入口', () {
    expect(featureFlagKey('journal'), 'qg_feature_journal');
    final ids = registeredFeatures.map((f) => f.id).toList();
    expect(activeFeatures(const DefaultRemoteFlags()).map((f) => f.id), ids);
    expect(activeFeatures(_Off({'journal'})).map((f) => f.id), isNot(contains('journal')));
    // Remote Config 參數名稱限制：字母或底線開頭，最多 256 字
    for (final id in ids) {
      expect(RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(featureFlagKey(id)), isTrue, reason: id);
    }
  });
}
