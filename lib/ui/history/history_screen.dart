import 'package:flutter/material.dart';

import '../../data/models/daily_feature_snapshot.dart';
import '../../data/models/risk_assessment.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.history, required this.assessment});

  final List<DailyFeatureSnapshot> history;
  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş ve eğilim')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son değerlendirme',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(assessment.explanation),
                    const SizedBox(height: 10),
                    Text(
                      'Bu ekran davranış eğilimini gösterir; klinik tanı veya nedensellik iddiası üretmez.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Henüz görüntülenecek günlük kullanım verisi yok.'),
                ),
              )
            else
              ...sorted.reversed.map(
                (day) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\${day.date.day.toString().padLeft(2, '0')}.\${day.date.month.toString().padLeft(2, '0')}.\${day.date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _row('Toplam ekran', '\${day.totalScreenTimeMinutes.round()} dk'),
                        _row('Sosyal medya', '\${day.socialMediaTimeMinutes.round()} dk'),
                        _row('Gece kullanımı', '\${day.nightUsageMinutes.round()} dk'),
                        _row('Oturum sayısı', '\${day.sessionCount}'),
                        _row('Hedef aşımı', '\${day.limitExceedanceCount} kez'),
                        _row(
                          'Veri bütünlüğü',
                          '%\${(day.dataCompleteness * 100).round()}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
