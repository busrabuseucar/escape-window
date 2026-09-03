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
                    Text('Son değerlendirme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(assessment.explanation),
                    const SizedBox(height: 10),
                    Text('Bu ekran davranış eğilimini gösterir; klinik tanı veya nedensellik iddiası üretmez.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Henüz görüntülenecek günlük kullanım verisi yok.')))
            else
              ...sorted.reversed.map((day) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${day.date.day.toString().padLeft(2, '0')}.${day.date.month.toString().padLeft(2, '0')}.${day.date.year}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          _row('Toplam ekran', '${day.totalScreenTimeMinutes.round()} dk'),
                          _row('Sosyal medya', '${day.socialMediaTimeMinutes.round()} dk'),
                          _row('Gece kullanımı', '${day.nightUsageMinutes.round()} dk'),
                          _row('Oturum sayısı', '${day.sessionCount}'),
                          _row('Hedef aşımı', '${day.limitExceedanceCount} kez'),
                          _row('Veri bütünlüğü', '%${(day.dataCompleteness * 100).round()}'),
                          if (day.rawEventCount > 0) ...[
                            const Divider(height: 24),
                            Text('UsageStats tanılama', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            _row('Ham event', '${day.rawEventCount}'),
                            _row('Eşleşen interval', '${day.pairedIntervalCount}'),
                            _row('Takip intervali', '${day.trackedRawIntervalCount}'),
                            _row('Açık kalan FG', '${day.unmatchedForegroundCount}'),
                            _row('Eşleşmeyen BG', '${day.unmatchedBackgroundCount}'),
                            const SizedBox(height: 8),
                            Text('Aynı eventlerde eski ↔ yeni', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
                            _row('Eski toplam', '${day.legacyTotalScreenTimeMinutes.round()} dk'),
                            _row('Yeni toplam', '${day.totalScreenTimeMinutes.round()} dk'),
                            _row('Eski sosyal', '${day.legacySocialMediaTimeMinutes.round()} dk'),
                            _row('Yeni sosyal', '${day.socialMediaTimeMinutes.round()} dk'),
                            _row('Eski takip intervali', '${day.legacyTrackedIntervalCount}'),
                            if (day.trackedPackageMinutes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Takip edilen paket süreleri', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              ..._sortedPackageEntries(day).map((entry) => _row(_shortPackage(entry.key), '${entry.value.round()} dk')),
                            ],
                          ],
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _sortedPackageEntries(DailyFeatureSnapshot day) {
    final entries = day.trackedPackageMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _shortPackage(String packageName) {
    final parts = packageName.split('.');
    if (parts.length <= 2) return packageName;
    return parts.sublist(parts.length - 2).join('.');
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }
}
