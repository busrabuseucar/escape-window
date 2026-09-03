import 'package:flutter/material.dart';

class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key, required this.onSaved});

  final ValueChanged<double> onSaved;

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  double dailyLimitMinutes = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım hedefin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kendin için bir günlük sınır belirle.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text('Bu hedef klinik bir eşik değildir. SRFI, senin kendi belirlediğin hedefe ne kadar uyabildiğini izlemek için kullanır.'),
              const SizedBox(height: 32),
              Center(child: Text('${dailyLimitMinutes.round()} dk', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700))),
              Slider(
                min: 30,
                max: 300,
                divisions: 18,
                label: '${dailyLimitMinutes.round()} dk',
                value: dailyLimitMinutes,
                onChanged: (value) => setState(() => dailyLimitMinutes = value),
              ),
              const Spacer(),
              FilledButton(onPressed: () => widget.onSaved(dailyLimitMinutes), child: const Text('Hedefi kaydet')),
            ],
          ),
        ),
      ),
    );
  }
}
