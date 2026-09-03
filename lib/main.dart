import 'package:flutter/material.dart';

import 'core/enums/risk_enums.dart';
import 'data/models/risk_assessment.dart';
import 'escape/rule_based_escape_window_engine.dart';
import 'interventions/intervention_engine.dart';
import 'interventions/intervention_models.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/intervention/intervention_screen.dart';
import 'ui/onboarding/goal_setup_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
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
  bool consentCompleted = false;
  bool goalCompleted = false;
  double dailyLimitMinutes = 120;

  // UI integration fixture. It is deliberately labeled as demo data and is
  // replaced by HybridRiskEngine output when device data wiring is completed.
  final RiskAssessment demoAssessment = RiskAssessment(
    timestamp: DateTime(2026, 9, 3),
    riskLevel: RiskLevel.elevated,
    confidence: ConfidenceLevel.high,
    bpi: 0.71,
    srfi: 0.80,
    cvl: 0.66,
    pbd: 1.45,
    safetyFlag: false,
    drivers: const [
      RiskDriver.behavioralPersistence,
      RiskDriver.selfRegulationFailure,
      RiskDriver.contextualVulnerability,
      RiskDriver.personalDeviation,
    ],
    explanation:
        'Son günlerde kendi belirlediğin kullanım sınırı tekrar aşıldı; örüntü birden fazla güne yayıldı ve gece kullanımında artış görüldü.',
    dermVersion: 'derm-rule-v0.1.1-demo-ui',
  );

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
        }),
      );
    }

    return DashboardScreen(
      assessment: demoAssessment,
      dailyLimitMinutes: dailyLimitMinutes,
      onRiskDetails: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RiskDetailScreen(assessment: demoAssessment),
          ),
        );
      },
      onOpenIntervention: () => _openIntervention(context),
    );
  }

  void _openIntervention(BuildContext context) {
    const escapeEngine = RuleBasedEscapeWindowEngine();
    const interventionEngine = DeterministicInterventionEngine();

    final decision = escapeEngine.evaluate(
      assessment: demoAssessment,
      persistenceIsSufficient: true,
      cooldownActive: false,
      interventionEligible: true,
    );
    final recommendation = interventionEngine.recommend(
      windowDecision: decision,
      assessment: demoAssessment,
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

  String _responseMessage(InterventionResponse response) => switch (response) {
        InterventionResponse.accepted => 'Müdahale kabul edildi.',
        InterventionResponse.delayed => 'Müdahale daha sonra hatırlatılacak.',
        InterventionResponse.dismissed => 'Müdahale şimdilik geçildi. Risk puanın bundan dolayı artmaz.',
        InterventionResponse.noResponse => 'Yanıt kaydedilmedi.',
      };
}
