import 'package:flutter/material.dart';

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

  bool consentCompleted = false;
  bool goalCompleted = false;
  double dailyLimitMinutes = 120;
  Future<HybridRiskResult>? _hybridFuture;

  @override
  Widget build(BuildContext context) {
    if (!consentCompleted) {
      return OnboardingScreen(
        onContinue: () => setState(() => consentCompleted = true),
      );
    }

    if (!goalCompleted) {
      return GoalSetupScreen(
        onSaved: (limit) => setState(() {
          dailyLimitMinutes = limit;
          goalCompleted = true;
          _hybridFuture = _evaluateHybridRisk();
        }),
      );
    }

    _hybridFuture ??= _evaluateHybridRisk();

    return FutureBuilder<HybridRiskResult>(
      future: _hybridFuture,
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
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _hybridFuture = _evaluateHybridRisk();
                      }),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final result = snapshot.data!;
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
                  history: _demoProvider.persistentRiskScenario(),
                  assessment: assessment,
                ),
              ),
            );
          },
          onPrivacy: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrivacyScreen(
                  onDeleteLocalDemoData: _resetDemoState,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<HybridRiskResult> _evaluateHybridRisk() {
    return _hybridEngine.evaluate(
      calibrationHistory: _demoProvider.normalScenario(),
      recentFeatures: _demoProvider.persistentRiskScenario(),
      userDailyLimitMinutes: dailyLimitMinutes,
    );
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

  void _resetDemoState() {
    setState(() {
      consentCompleted = false;
      goalCompleted = false;
      dailyLimitMinutes = 120;
      _hybridFuture = null;
    });
  }

  String _responseMessage(InterventionResponse response) => switch (response) {
        InterventionResponse.accepted => 'Müdahale kabul edildi.',
        InterventionResponse.delayed => 'Müdahale daha sonra hatırlatılacak.',
        InterventionResponse.dismissed => 'Müdahale şimdilik geçildi. Risk puanın bundan dolayı artmaz.',
        InterventionResponse.noResponse => 'Yanıt kaydedilmedi.',
      };
}
