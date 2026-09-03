import 'package:flutter/material.dart';

import 'data/models/daily_feature_snapshot.dart';
import 'features/usage_collector/android_usage_stats_collector.dart';
import 'features/usage_collector/demo_data_provider.dart';
import 'hybrid/hybrid_risk_engine.dart';
import 'hybrid/hybrid_risk_result.dart';
import 'escape/rule_based_escape_window_engine.dart';
import 'interventions/intervention_engine.dart';
import 'interventions/intervention_models.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/intervention/intervention_screen.dart';
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

  // MVP category map. This is an engineering classification, not a clinical
  // statement. A later UI will let the user review/select tracked app packages.
  static const Set<String> _defaultSocialPackages = {
    'com.instagram.android',
    'com.zhiliaoapp.musically',
    'com.google.android.youtube',
    'com.twitter.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.reddit.frontpage',
  };

  bool consentCompleted = false;
  bool usagePermissionCompleted = false;
  bool goalCompleted = false;
  bool useDemoData = false;
  double dailyLimitMinutes = 120;
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
        onGranted: () => setState(() => usagePermissionCompleted = true),
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

    // Use fourteen completed days so today's partial data does not distort
    // completeness. First 7 days calibrate personal baseline; last 7 are the
    // current evaluation window.
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final days = <DailyFeatureSnapshot>[];

    for (var offset = 14; offset >= 1; offset--) {
      final day = anchor.subtract(Duration(days: offset));
      days.add(
        await _usageCollector.collectDay(
          day: day,
          userDailyLimitMinutes: dailyLimitMinutes,
          trackedSocialPackages: _defaultSocialPackages,
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

    return _EvaluationBundle(result: result, recentHistory: recent, source: 'android_usage_stats');
  }

  void _openIntervention(BuildContext context, HybridRiskResult result) {
    const escapeEngine = RuleBasedEscapeWindowEngine();
    const interventionEngine = DeterministicInterventionEngine();

    final assessment = result.assessment;
    final persistenceIsSufficient = assessment.bpi >= 0.40;

    final decision = escapeEngine.evaluate(
      assessment: assessment,
      persistenceIsSufficient: persistenceIsSufficient,
      cooldownActive: false,
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterventionScreen(
          recommendation: recommendation,
          onResponse: (response) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_responseMessage(response))),
            );
          },
        ),
      ),
    );
  }

  void _resetState() {
    setState(() {
      consentCompleted = false;
      usagePermissionCompleted = false;
      goalCompleted = false;
      useDemoData = false;
      dailyLimitMinutes = 120;
      _evaluationFuture = null;
    });
  }

  String _responseMessage(InterventionResponse response) => switch (response) {
        InterventionResponse.accepted => 'Müdahale kabul edildi.',
        InterventionResponse.delayed => 'Müdahale daha sonra hatırlatılacak.',
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
