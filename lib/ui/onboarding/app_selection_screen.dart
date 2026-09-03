import 'package:flutter/material.dart';

import '../../features/usage_collector/tracked_app_catalog.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({
    super.key,
    required this.initialSelection,
    required this.onSaved,
  });

  final Set<String> initialSelection;
  final ValueChanged<Set<String>> onSaved;

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  late final Set<String> selectedPackages;

  @override
  void initState() {
    super.initState();
    selectedPackages = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takip edilecek uygulamalar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Yalnızca değerlendirmeye dahil etmek istediğin uygulamaları seç.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ESCAPE uygulama içeriğini, mesajlarını veya yaptığın işlemleri okumaz. '
              'Seçim yalnızca kullanım süresi gibi davranışsal metriklerin hangi paketler için sosyal/dijital kullanım olarak sınıflandırılacağını belirler.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.privacy_tip_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MVP, tüm yüklü uygulamaları listelemek için geniş paket görünürlüğü izni istemez. '
                        'Bu ekran privacy-by-design yaklaşımıyla sınırlı bir uygulama kataloğu kullanır.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...TrackedAppCatalog.options.map((app) {
              final selected = selectedPackages.contains(app.packageName);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected,
                title: Text(app.label),
                subtitle: Text('${app.category} • ${app.packageName}'),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedPackages.add(app.packageName);
                    } else {
                      selectedPackages.remove(app.packageName);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: selectedPackages.isEmpty
                  ? null
                  : () => widget.onSaved({...selectedPackages}),
              child: Text(
                selectedPackages.isEmpty
                    ? 'En az bir uygulama seç'
                    : '${selectedPackages.length} uygulama ile devam et',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seçim daha sonra değiştirilebilir. Uygulama seçimini kaldırmak tek başına risk puanını yükseltmez.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
