import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool usageConsent = false;
  bool notificationConsent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESCAPE Window AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Dijital davranışını daha erken fark et.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('ESCAPE, kullanım alışkanlıklarını kendi geçmişinle karşılaştırır; risk, güven ve neden bilgisini ayrı ayrı gösterir. Klinik tanı koymaz.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            const _InfoTile(icon: Icons.lock_outline, title: 'Privacy-by-design', body: 'Mesaj, fotoğraf, mikrofon ve özel iletişim içeriği toplanmaz.'),
            const SizedBox(height: 12),
            const _InfoTile(icon: Icons.insights_outlined, title: 'Açıklanabilir değerlendirme', body: 'Neden uyarı aldığını görebilirsin; tek bir gizemli AI skoru yoktur.'),
            const SizedBox(height: 12),
            const _InfoTile(icon: Icons.health_and_safety_outlined, title: 'Tanı sistemi değildir', body: 'Amaç erken farkındalık ve düşük yoğunluklu öz-düzenleme desteğidir.'),
            const SizedBox(height: 28),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kullanım verisi işlemeye izin veriyorum'),
              subtitle: const Text('MVP için gereklidir.'),
              value: usageConsent,
              onChanged: (value) => setState(() => usageConsent = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Müdahale bildirimlerine izin veriyorum'),
              value: notificationConsent,
              onChanged: (value) => setState(() => notificationConsent = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: usageConsent ? widget.onContinue : null,
              child: const Text('Devam et'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(body)])),
          ],
        ),
      ),
    );
  }
}
