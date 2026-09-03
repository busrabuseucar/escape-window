import 'package:flutter/material.dart';

import '../../core/enums/risk_enums.dart';
import '../../data/models/risk_assessment.dart';

class RiskDetailScreen extends StatelessWidget {
  const RiskDetailScreen({super.key, required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk detayı')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Bu değerlendirme neden oluştu?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(assessment.explanation),
            const SizedBox(height: 22),
            ...assessment.drivers.map((driver) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: Text(_driverTitle(driver)),
                      subtitle: Text(_driverDescription(driver)),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Önemli not', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Bu ekran klinik tanı vermez. BPI, SRFI, CVL ve PBD erken-risk ve kişiselleştirme sinyalleridir; yorumları pilot ve doğrulama çalışmalarıyla sınanmalıdır.'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _driverTitle(RiskDriver driver) => switch (driver) {
        RiskDriver.behavioralPersistence => 'Davranışsal süreklilik (BPI)',
        RiskDriver.selfRegulationFailure => 'Öz-düzenleme başarısızlığı (SRFI)',
        RiskDriver.contextualVulnerability => 'Bağlamsal hassasiyet (CVL)',
        RiskDriver.personalDeviation => 'Kişisel baseline sapması (PBD)',
        RiskDriver.safetyGuardrail => 'Güvenlik katmanı',
      };

  String _driverDescription(RiskDriver driver) => switch (driver) {
        RiskDriver.behavioralPersistence => 'Risk örüntüsünün tek güne değil, zamana yayılıp yayılmadığını değerlendirir.',
        RiskDriver.selfRegulationFailure => 'Kendi belirlediğin sınırların tekrar eden biçimde aşılıp aşılmadığını değerlendirir.',
        RiskDriver.contextualVulnerability => 'Gece kullanımı gibi bağlamsal hassasiyet sinyallerini izler.',
        RiskDriver.personalDeviation => 'Mevcut kullanımın kendi olağan davranışından ne kadar saptığını gösterir.',
        RiskDriver.safetyGuardrail => 'Kişisel baseline yeterince güvenilir değilse kör noktayı azaltmak için ek koruma sağlar.',
      };
}
