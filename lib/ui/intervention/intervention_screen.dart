import 'package:flutter/material.dart';

import '../../interventions/intervention_models.dart';

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({
    super.key,
    required this.recommendation,
    required this.onResponse,
  });

  final InterventionRecommendation recommendation;
  final ValueChanged<InterventionResponse> onResponse;

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  bool _responded = false;

  void _respond(InterventionResponse response) {
    if (_responded) return;
    _responded = true;
    widget.onResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_responded) {
          _respond(InterventionResponse.noResponse);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('ESCAPE Window')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Müdahale penceresi aktif'),
                ),
                const SizedBox(height: 22),
                Text(
                  recommendation.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  recommendation.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Neden şimdi?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(recommendation.reason),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () =>
                      _respond(InterventionResponse.accepted),
                  child: const Text('Şimdi uygula'),
                ),
                if (recommendation.allowDelay) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () =>
                        _respond(InterventionResponse.delayed),
                    child: const Text('Daha sonra hatırlat'),
                  ),
                ],
                if (recommendation.allowDismiss) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () =>
                        _respond(InterventionResponse.dismissed),
                    child: const Text('Şimdilik geç'),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Bir müdahaleyi ertelemek veya reddetmek risk puanını yükseltmez.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
