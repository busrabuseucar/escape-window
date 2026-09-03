import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    required this.onDeleteLocalDemoData,
  });

  final VoidCallback onDeleteLocalDemoData;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool interventionsEnabled = true;
  bool researchSharingEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik ve veri kontrolleri')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yerel-öncelikli tasarım',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'MVP mimarisi ham kullanım verisini mümkün olduğunca cihazda tutmayı hedefler. Mesaj içeriği, fotoğraf, mikrofon, kişi listesi ve tuş vuruşları toplanmaz.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Mikro müdahaleleri etkinleştir'),
              subtitle: const Text('Kapatılırsa ESCAPE önerileri gösterilmez.'),
              value: interventionsEnabled,
              onChanged: (value) => setState(() => interventionsEnabled = value),
            ),
            SwitchListTile(
              title: const Text('Araştırma için anonimleştirilmiş veri paylaşımı'),
              subtitle: const Text(
                'MVP’de varsayılan kapalıdır. Gerçek paylaşım altyapısı kurulmadan veri gönderilmez.',
              ),
              value: researchSharingEnabled,
              onChanged: (value) => setState(() => researchSharingEnabled = value),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Toplanmayan veriler'),
              subtitle: const Text(
                'Mesaj içeriği • fotoğraf • mikrofon • kişi listesi • tuş vuruşları',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Kullanılan davranış verileri'),
              subtitle: const Text(
                'Ekran süresi • uygulama kategorisi • oturum süresi/sayısı • kullanım saati • kişisel hedef aşımı',
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Yerel demo verisini sil ve başlangıca dön'),
              onPressed: () {
                widget.onDeleteLocalDemoData();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Not: Bu ekrandaki tercihler şu aşamada MVP arayüz kontrolleridir. Kalıcı cihaz depolama ve gerçek izin yönetimi Android entegrasyonu sırasında bağlanacaktır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
