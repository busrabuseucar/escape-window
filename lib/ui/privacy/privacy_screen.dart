import 'package:flutter/material.dart';

import '../onboarding/app_selection_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    required this.onDeleteLocalDemoData,
    required this.interventionsEnabled,
    required this.onInterventionsChanged,
    required this.trackedPackages,
    required this.onTrackedPackagesChanged,
  });

  final Future<void> Function() onDeleteLocalDemoData;
  final bool interventionsEnabled;
  final ValueChanged<bool> onInterventionsChanged;
  final Set<String> trackedPackages;
  final ValueChanged<Set<String>> onTrackedPackagesChanged;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late bool interventionsEnabled;
  bool deleting = false;
  late Set<String> trackedPackages;

  @override
  void initState() {
    super.initState();
    interventionsEnabled = widget.interventionsEnabled;
    trackedPackages = {...widget.trackedPackages};
  }

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
              onChanged: (value) {
                setState(() => interventionsEnabled = value);
                widget.onInterventionsChanged(value);
              },
            ),
            SwitchListTile(
              title: const Text('Araştırma için anonimleştirilmiş veri paylaşımı'),
              subtitle: const Text(
                'MVP’de varsayılan kapalıdır. Gerçek paylaşım altyapısı kurulmadan veri gönderilmez.',
              ),
              value: false,
              onChanged: null,
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Takip edilen uygulamalar'),
              subtitle: Text(
                '${trackedPackages.length} uygulama değerlendirmeye dahil ediliyor.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editTrackedApps,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bu seçim değiştiğinde risk değerlendirmesi yeni uygulama kümesiyle yeniden hesaplanır. Bir uygulamayı listeden çıkarmak tek başına risk puanını yükseltmez.',
              ),
            ),
            const SizedBox(height: 10),
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
              label: const Text('Yerel kayıtları sil ve başlangıca dön'),
              onPressed: deleting ? null : _deleteLocalData,
            ),
            const SizedBox(height: 10),
            Text(
              'Müdahale tercihi bu oturumda uygulanır; yeniden açılışta varsayılana döner. Araştırma paylaşımı uygulanmadı. Yerel silme Android’in UsageStats geçmişini veya sistem iznini silmez.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLocalData() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Yerel kayıtlar silinsin mi?'),
      content: const Text('Müdahale yanıtları silinir ve başlangıca dönülür. Android kullanım geçmişi ve sistem izni korunur.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await widget.onDeleteLocalDemoData();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıtlar silinemedi. Tekrar dene.')));
    }
  }

  Future<void> _editTrackedApps() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppSelectionScreen(
          initialSelection: trackedPackages,
          onSaved: (selection) {
            setState(() => trackedPackages = {...selection});
            widget.onTrackedPackagesChanged({...selection});
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
