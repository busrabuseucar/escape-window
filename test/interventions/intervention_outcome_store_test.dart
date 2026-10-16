import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/interventions/intervention_models.dart';
import 'package:escape_window_ai/interventions/intervention_outcome_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('demo and physical outcomes have separate storage', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'escape_demo_outcomes_v1': <String>['invalid demo row'],
      'escape_intervention_outcomes_v1': <String>['invalid physical row'],
    });
    const demo = SharedPreferencesInterventionOutcomeStore(recordsKey: 'escape_demo_outcomes_v1');
    await demo.clear();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('escape_demo_outcomes_v1'), isNull);
    expect(prefs.getStringList('escape_intervention_outcomes_v1'), hasLength(1));
  });

  test('persists and restores intervention outcome with cooldown', () async {
    const store = SharedPreferencesInterventionOutcomeStore();
    final shownAt = DateTime(2026, 9, 4, 8, 0);
    final respondedAt = DateTime(2026, 9, 4, 8, 1);
    final cooldownUntil = DateTime(2026, 9, 4, 14, 1);

    final record = InterventionOutcomeRecord(
      id: 'test-1',
      shownAt: shownAt,
      respondedAt: respondedAt,
      response: InterventionResponse.accepted,
      cooldownUntil: cooldownUntil,
      riskLevel: RiskLevel.elevated,
      confidence: ConfidenceLevel.high,
      dermVersion: 'derm-rule-v0.2.0-pilot',
      interventionType: InterventionType.goalReminder,
      reason: 'SRFI + PBD birlikte etkin.',
      drivers: const [
        RiskDriver.selfRegulationFailure,
        RiskDriver.personalDeviation,
      ],
    );

    await store.append(record);
    final restored = await store.readAll();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'test-1');
    expect(restored.single.response, InterventionResponse.accepted);
    expect(restored.single.riskLevel, RiskLevel.elevated);
    expect(restored.single.confidence, ConfidenceLevel.high);
    expect(restored.single.interventionType, InterventionType.goalReminder);
    expect(
      restored.single.drivers,
      const [
        RiskDriver.selfRegulationFailure,
        RiskDriver.personalDeviation,
      ],
    );
    expect(restored.single.cooldownUntil, cooldownUntil);
    expect(await store.latestCooldownUntil(), cooldownUntil);
  });

  test('latestCooldownUntil follows the latest response, not largest timestamp', () async {
    const store = SharedPreferencesInterventionOutcomeStore();

    Future<void> add({
      required String id,
      required DateTime respondedAt,
      required DateTime cooldownUntil,
    }) {
      return store.append(
        InterventionOutcomeRecord(
          id: id,
          shownAt: respondedAt.subtract(const Duration(minutes: 1)),
          respondedAt: respondedAt,
          response: InterventionResponse.dismissed,
          cooldownUntil: cooldownUntil,
          riskLevel: RiskLevel.watch,
          confidence: ConfidenceLevel.medium,
          dermVersion: 'derm-rule-v0.2.0-pilot',
          interventionType: InterventionType.shortBreak,
          reason: 'test',
          drivers: const [RiskDriver.behavioralPersistence],
        ),
      );
    }

    await add(
      id: 'newer',
      respondedAt: DateTime(2026, 9, 4, 12),
      cooldownUntil: DateTime(2026, 9, 5, 0),
    );
    await add(
      id: 'older-but-longer',
      respondedAt: DateTime(2026, 9, 4, 10),
      cooldownUntil: DateTime(2026, 9, 5, 8),
    );

    expect(
      await store.latestCooldownUntil(),
      DateTime(2026, 9, 5, 0),
    );
  });

  test('clear removes all locally persisted intervention outcomes', () async {
    const store = SharedPreferencesInterventionOutcomeStore();

    await store.append(
      InterventionOutcomeRecord(
        id: 'test-clear',
        shownAt: DateTime(2026, 9, 4, 8),
        respondedAt: DateTime(2026, 9, 4, 8, 1),
        response: InterventionResponse.noResponse,
        cooldownUntil: DateTime(2026, 9, 4, 14, 1),
        riskLevel: RiskLevel.watch,
        confidence: ConfidenceLevel.medium,
        dermVersion: 'derm-rule-v0.2.0-pilot',
        interventionType: InterventionType.shortBreak,
        reason: 'test',
        drivers: const [],
      ),
    );

    await store.clear();

    expect(await store.readAll(), isEmpty);
    expect(await store.latestCooldownUntil(), isNull);
  });
}
