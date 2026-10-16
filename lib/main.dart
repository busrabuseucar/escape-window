import 'package:flutter/material.dart';

import 'data/models/daily_feature_snapshot.dart';
import 'features/usage_collector/android_usage_stats_collector.dart';
import 'features/usage_collector/demo_data_provider.dart';
import 'features/usage_collector/tracked_app_catalog.dart';
import 'hybrid/hybrid_risk_engine.dart';
import 'hybrid/hybrid_risk_result.dart';
import 'escape/rule_based_escape_window_engine.dart';
import 'interventions/cooldown_policy.dart';
import 'interventions/intervention_engine.dart';
import 'interventions/intervention_models.dart';
import 'interventions/intervention_outcome_store.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/intervention/intervention_screen.dart';
import 'ui/onboarding/app_selection_screen.dart';
import 'ui/onboarding/goal_setup_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/onboarding/usage_permission_screen.dart';
import 'ui/privacy/privacy_screen.dart';
import 'ui/risk_detail/risk_detail_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const EscapeWindowApp());
}

class EscapeWindowApp extends StatelessWidget {
  const EscapeWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESCAPE Window AI',
      theme: AppTheme.light(),
      home: const _AppFlow(),
    );
  }
}

class _AppFlow extends StatefulWidget {
  const _AppFlow();

  @override
  State<_AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<_AppFlow> {
  static const _demoProvider = DemoDataProvider();
  static const _hybridEngine = HybridRiskEngine();
  static const _usageCollector = AndroidUsageStatsCollector();
  static const _cooldownPolicy = CooldownPolicy();
  InterventionOutcomeStore get _interventionStore => SharedPreferencesInterventionOutcomeStore(
    recordsKey: useDemoData ? "escape_demo_outcomes_v1" : "escape_intervention_outcomes_v1",
  );
  bool interventionsEnabled = true;

  bool consentCompleted = false;
  bool usagePermissionCompleted = false;
  bool appSelectionCompleted = false;
  bool goalCompleted = false;
  bool useDemoData = false;
  double dailyLimitMinutes = 120;
  Set<String> trackedPackages = {...TrackedAppCatalog.defaultPackages};
  Future<_EvaluationBundle>? _evaluationFuture;

  @override
  Widget build(BuildContext context) {
    if (!consentCompleted) {
      return OnboardingScreen(
        onContinue: () => setState(() => consentCompleted = true),
      );
    }

    if (!usagePermissionCompleted && !useDemoData) {
      return UsagePermissionScreen(
        collector: _usageCollector,
        onDemo: () => setState(() { useDemoData = true; }),
        onGranted: () => setState(() => usagePermissionCompleted = true),
      );
    }

    if (!appSelectionCompleted) {
      return AppSelectionScreen(
        initialSelection: trackedPackages,
        onSaved: (selection) => setState(() {
          trackedPackages = selection;
          appSelectionCompleted = true;
          _evaluationFuture = null;
        }),
      );
    }

    if (!goalCompleted) {
      return GoalSetupScreen(
        onSaved: (limit) => setState(() {
          dailyLimitMinutes = limit;
          goalCompleted = true;
          _evaluationFuture = _evaluate();
        }),
      );
    }

    _evaluationFuture ??= _evaluate();

    return FutureBuilder<_EvaluationBundle>(
      future: _evaluationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('ESCAPE Window AI')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Risk değerlendirmesi oluşturulamadı.'),
                    const SizedBox(height: 8),
                    if (snapshot.hasError)
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _evaluationFuture = _evaluate();
                      }),
                      child: const Text('Tekrar dene'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        useDemoData = true;
                        usagePermissionCompleted = false;
                        _evaluationFuture = _evaluate();
                      }),
                      child: const Text('Kontrollü demo verisiyle devam et'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bundle = snapshot.data!;
        final result = bundle.result;
        final assessment = result.assessment;

        return DashboardScreen(
          isDemo: bundle.source == 'demo',
          assessment: assessment,
          dailyLimitMinutes: dailyLimitMinutes,
          onRiskDetails: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RiskDetailScreen(assessment: assessment),
              ),
            );
          },
          onOpenIntervention: () => _openIntervention(context, result),
          onHistory: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryScreen(
                  history: bundle.recentHistory,
                  assessment: assessment,
                ),
              ),
            );
          },
          onPrivacy: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrivacyScreen(
                  onDeleteLocalDemoData: _resetState,
                  interventionsEnabled: interventionsEnabled,
                  onInterventionsChanged: (value) => setState(() => interventionsEnabled = value),
                  trackedPackages: trackedPackages,
                  onTrackedPackagesChanged: _updateTrackedPackages,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_EvaluationBundle> _evaluate() async {
    if (useDemoData) {
      final recent = _demoProvider.persistentRiskScenario();
      final result = await _hybridEngine.evaluate(
        calibrationHistory: _demoProvider.normalScenario(),
        recentFeatures: recent,
        userDailyLimitMinutes: dailyLimitMinutes,
      );
      return _EvaluationBundle(result: result, recentHistory: recent, source: 'demo');
    }

    final status = await _usageCollector.getAccessStatus();
    if (!status.supported || !status.granted) {
      throw const UsageStatsUnavailableException(
        'Android kullanım erişimi açık değil. İzni etkinleştir veya demo modunu kullan.',
      );
    }

    if (trackedPackages.isEmpty) {
      throw const UsageStatsUnavailableException(
        'Değerlendirme için en az bir takip uygulaması seçilmelidir.',
      );
    }

    // Use fourteen completed days so today's partial data does not distort
    // completeness. First 7 days calibrate personal baseline; last 7 are the
    // current evaluation window.
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final days = <DailyFeatureSnapshot>[];

    for (var offset = 14; offset >= 1; offset--) {
      final day = DateTime(anchor.year, anchor.month, anchor.day - offset);
      days.add(
        await _usageCollector.collectDay(
          day: day,
          userDailyLimitMinutes: dailyLimitMinutes,
          trackedSocialPackages: trackedPackages,
        ),
      );
    }

    final calibration = days.sublist(0, 7);
    final recent = days.sublist(7, 14);
    final result = await _hybridEngine.evaluate(
      calibrationHistory: calibration,
      recentFeatures: recent,
      userDailyLimitMinutes: dailyLimitMinutes,
    );

    return _EvaluationBundle(
      result: result,
      recentHistory: recent,
      source: 'android_usage_stats',
    );
  }

  void _updateTrackedPackages(Set<String> selection) {
    setState(() {
      trackedPackages = {...selection};
      _evaluationFuture = _evaluate();
    });
  }

  Future<void> _openIntervention(
    BuildContext context,
    HybridRiskResult result,
  ) async {
    if (!interventionsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mikro müdahaleler kapalı.')));
      return;
    }
    const escapeEngine = RuleBasedEscapeWindowEngine();
    const interventionEngine = DeterministicInterventionEngine();

    final assessment = result.assessment;
    final persistenceIsSufficient = assessment.bpi >= 0.40;
    final now = DateTime.now();
    final latestCooldownUntil =
        await _interventionStore.latestCooldownUntil();
    final cooldownActive = _cooldownPolicy.isCooldownActive(
      now: now,
      cooldownUntil: latestCooldownUntil,
    );

    if (!context.mounted) return;

    final decision = escapeEngine.evaluate(
      assessment: assessment,
      persistenceIsSufficient: persistenceIsSufficient,
      cooldownActive: cooldownActive,
      interventionEligible: true,
    );
    final recommendation = interventionEngine.recommend(
      windowDecision: decision,
      assessment: assessment,
    );

    if (recommendation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decision.reason)),
      );
      return;
    }

    final shownAt = DateTime.now();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterventionScreen(
          recommendation: recommendation,
          onResponse: (response) async {
            final respondedAt = DateTime.now();
            final cooldownUntil = _cooldownPolicy.cooldownUntil(
              response: response,
              respondedAt: respondedAt,
            );

            await _interventionStore.append(
              InterventionOutcomeRecord(
                id: '${shownAt.microsecondsSinceEpoch}-${recommendation.type.name}',
                shownAt: shownAt,
                respondedAt: respondedAt,
                response: response,
                cooldownUntil: cooldownUntil,
                riskLevel: assessment.riskLevel,
                confidence: assessment.confidence,
                dermVersion: assessment.dermVersion,
                interventionType: recommendation.type,
                reason: recommendation.reason,
                drivers: assessment.drivers,
              ),
            );

            if (!context.mounted) return;
            if (response != InterventionResponse.noResponse) {
              Navigator.of(context).pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_responseMessage(response))),
            );
          },
        ),
      ),
    );
  }

  Future<void> _resetState() async {
    await const SharedPreferencesInterventionOutcomeStore().clear();
    await const SharedPreferencesInterventionOutcomeStore(recordsKey: "escape_demo_outcomes_v1").clear();
    if (!mounted) return;
    setState(() {
      interventionsEnabled = true;
      consentCompleted = false;
      usagePermissionCompleted = false;
      appSelectionCompleted = false;
      goalCompleted = false;
      useDemoData = false;
      dailyLimitMinutes = 120;
      trackedPackages = {...TrackedAppCatalog.defaultPackages};
      _evaluationFuture = null;
    });
  }

  String _responseMessage(InterventionResponse response) => switch (response) {
        InterventionResponse.accepted => 'Müdahale kabul edildi.',
        InterventionResponse.delayed => 'Müdahale ertelendi. Otomatik bildirim planlanmaz.',
        InterventionResponse.dismissed => 'Müdahale şimdilik geçildi. Risk puanın bundan dolayı artmaz.',
        InterventionResponse.noResponse => 'Yanıt kaydedilmedi.',
      };
}

class _EvaluationBundle {
  const _EvaluationBundle({
    required this.result,
    required this.recentHistory,
    required this.source,
  });

  final HybridRiskResult result;
  final List<DailyFeatureSnapshot> recentHistory;
  final String source;
}
