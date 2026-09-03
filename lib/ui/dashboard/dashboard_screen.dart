import 'package:flutter/material.dart';

import '../../core/enums/risk_enums.dart';
import '../../data/models/risk_assessment.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.assessment,
    required this.dailyLimitMinutes,
    required this.onRiskDetails,
    required this.onOpenIntervention,
  });

  final RiskAssessment assessment;
  final double dailyLimitMinutes;
  final VoidCallback onRiskDetails;
  final VoidCallback onOpenIntervention;

  String get _riskLabel => switch (assessment.riskLevel) {
        RiskLevel.low => 'Düşük',
        RiskLevel.watch => 'İzleniyor',
        RiskLevel.elevated => 'Yükselmiş',
        RiskLevel.insufficientData => 'Yetersiz veri',
      };

  String get _confidenceLabel => switch (assessment.confidence) {
        ConfidenceLevel.low => 'Düşük',
        ConfidenceLevel.medium => 'Orta',
        ConfidenceLevel.high => 'Yüksek',
        ConfidenceLevel.insufficient => 'Yetersiz',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bugünkü durum')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Erken risk değerlendirmesi'),
                  const SizedBox(height: 10),
                  Text(_riskLabel, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(assessment.explanation),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Chip(label: Text('Güven: $_confidenceLabel')),
                    Chip(label: Text('Günlük hedef: ${dailyLimitMinutes.round()} dk')),
                    Chip(label: Text('DERM: ${assessment.dermVersion}')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _MetricCard(label: 'BPI', value: assessment.bpi)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'SRFI', value: assessment.srfi)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'CVL', value: assessment.cvl)),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(assessment.safetyFlag ? 'Güvenlik katmanı aktif.' : 'Güvenlik katmanı ek uyarı üretmiyor.')),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRiskDetails, child: const Text('Risk detayını gör')),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onOpenIntervention, child: const Text('ESCAPE müdahale ekranını aç')),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge)]),
      ),
    );
  }
}
