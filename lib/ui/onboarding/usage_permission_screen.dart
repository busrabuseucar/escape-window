import 'package:flutter/material.dart';

import '../../features/usage_collector/android_usage_stats_collector.dart';

class UsagePermissionScreen extends StatefulWidget {
  const UsagePermissionScreen({
    super.key,
    required this.collector,
    required this.onGranted,
    required this.onDemo,
  });

  final AndroidUsageStatsCollector collector;
  final VoidCallback onGranted;
  final VoidCallback onDemo;

  @override
  State<UsagePermissionScreen> createState() => _UsagePermissionScreenState();
}

class _UsagePermissionScreenState extends State<UsagePermissionScreen> with WidgetsBindingObserver {
  bool loading = true;
  bool supported = true;
  bool granted = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await widget.collector.getAccessStatus();
      if (!mounted) return;
      setState(() {
        loading = false;
        supported = status.supported;
        granted = status.granted;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'İzin durumu okunamadı: $e';
      });
    }
  }

  Future<void> _openSettings() async {
    try {
      await widget.collector.openUsageAccessSettings();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Kullanım erişimi ayarları açılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım erişimi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Android kullanım verisi izni',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'ESCAPE, hangi uygulamanın ne kadar süre ön planda kaldığını Android UsageStats üzerinden okur. Mesaj içeriği, fotoğraf, mikrofon, tuş vuruşu veya iletişim içeriği okunmaz.',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(granted ? Icons.verified_user_outlined : Icons.admin_panel_settings_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loading
                            ? 'İzin durumu kontrol ediliyor…'
                            : !supported
                                ? 'Bu platform Android UsageStats desteklemiyor.'
                                : granted
                                    ? 'Kullanım erişimi açık.'
                                    : 'Kullanım erişimi henüz kapalı.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            if (!granted && supported)
              FilledButton.icon(
                onPressed: loading ? null : _openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Android kullanım erişimi ayarını aç'),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: loading ? null : _refresh,
              child: const Text('İzin durumunu yeniden kontrol et'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: granted ? widget.onGranted : null,
              child: const Text('Devam et'),
            ),
            TextButton(onPressed: widget.onDemo, child: const Text('İzin vermeden örnek verilerle dene')),
          ],
        ),
      ),
    );
  }
}
