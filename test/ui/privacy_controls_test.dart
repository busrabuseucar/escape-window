import 'package:escape_window_ai/ui/privacy/privacy_screen.dart';
import 'package:escape_window_ai/ui/onboarding/usage_permission_screen.dart';
import 'package:escape_window_ai/features/usage_collector/android_usage_stats_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class UnavailableCollector extends AndroidUsageStatsCollector {
  const UnavailableCollector();
  @override
  Future<UsageAccessStatus> getAccessStatus() async => const UsageAccessStatus(supported: false, granted: false);
}
void main() {
  testWidgets('demo is accessible without usage permission', (tester) async {
    var demo = false;
    await tester.pumpWidget(MaterialApp(home: UsagePermissionScreen(
      collector: const UnavailableCollector(), onGranted: () {}, onDemo: () => demo = true,
    )));
    await tester.pumpAndSettle();
    final button = find.text('İzin vermeden örnek verilerle dene');
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(demo, isTrue);
  });
  testWidgets('intervention control reaches parent and research sharing is disabled', (tester) async {
    bool? value;
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(
      onDeleteLocalDemoData: () async {}, trackedPackages: const {'test.app'}, onTrackedPackagesChanged: (_) {},
      interventionsEnabled: true, onInterventionsChanged: (v) => value = v,
    )));
    await tester.tap(find.text('Mikro müdahaleleri etkinleştir'));
    await tester.pump();
    expect(value, isFalse);
    final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(switches[0].value, isFalse);
    expect(switches[1].onChanged, isNull);
  });
  testWidgets('deletion requires confirmation and reports failure', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: PrivacyScreen(
      onDeleteLocalDemoData: () async { attempts++; throw StateError('disk'); },
      trackedPackages: const {}, onTrackedPackagesChanged: (_) {}, interventionsEnabled: true, onInterventionsChanged: (_) {},
    )));
    final button = find.text('Yerel kayıtları sil ve başlangıca dön');
    await tester.ensureVisible(button);
    await tester.tap(button); await tester.pumpAndSettle();
    expect(attempts, 0);
    await tester.tap(find.text('Sil')); await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text('Kayıtlar silinemedi. Tekrar dene.'), findsOneWidget);
  });
}
