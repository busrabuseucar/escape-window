import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/risk_enums.dart';
import 'intervention_models.dart';

class InterventionOutcomeRecord {
  const InterventionOutcomeRecord({
    required this.id,
    required this.shownAt,
    required this.respondedAt,
    required this.response,
    required this.cooldownUntil,
    required this.riskLevel,
    required this.confidence,
    required this.dermVersion,
    required this.interventionType,
    required this.reason,
    required this.drivers,
  });

  final String id;
  final DateTime shownAt;
  final DateTime respondedAt;
  final InterventionResponse response;
  final DateTime cooldownUntil;
  final RiskLevel riskLevel;
  final ConfidenceLevel confidence;
  final String dermVersion;
  final InterventionType interventionType;
  final String reason;
  final List<RiskDriver> drivers;

  Map<String, Object?> toJson() => {
        'id': id,
        'shownAt': shownAt.toUtc().toIso8601String(),
        'respondedAt': respondedAt.toUtc().toIso8601String(),
        'response': response.name,
        'cooldownUntil': cooldownUntil.toUtc().toIso8601String(),
        'riskLevel': riskLevel.name,
        'confidence': confidence.name,
        'dermVersion': dermVersion,
        'interventionType': interventionType.name,
        'reason': reason,
        'drivers': drivers.map((driver) => driver.name).toList(),
      };

  static InterventionOutcomeRecord fromJson(Map<String, Object?> json) {
    T enumByName<T extends Enum>(Iterable<T> values, String name) =>
        values.firstWhere((value) => value.name == name);

    return InterventionOutcomeRecord(
      id: json['id']! as String,
      shownAt: DateTime.parse(json['shownAt']! as String).toLocal(),
      respondedAt: DateTime.parse(json['respondedAt']! as String).toLocal(),
      response: enumByName(
        InterventionResponse.values,
        json['response']! as String,
      ),
      cooldownUntil:
          DateTime.parse(json['cooldownUntil']! as String).toLocal(),
      riskLevel: enumByName(RiskLevel.values, json['riskLevel']! as String),
      confidence:
          enumByName(ConfidenceLevel.values, json['confidence']! as String),
      dermVersion: json['dermVersion']! as String,
      interventionType: enumByName(
        InterventionType.values,
        json['interventionType']! as String,
      ),
      reason: json['reason']! as String,
      drivers: (json['drivers']! as List<Object?>)
          .cast<String>()
          .map((name) => enumByName(RiskDriver.values, name))
          .toList(growable: false),
    );
  }
}

abstract interface class InterventionOutcomeStore {
  Future<void> append(InterventionOutcomeRecord record);
  Future<List<InterventionOutcomeRecord>> readAll();
  Future<DateTime?> latestCooldownUntil();
  Future<void> clear();
}

class SharedPreferencesInterventionOutcomeStore
    implements InterventionOutcomeStore {
  const SharedPreferencesInterventionOutcomeStore();

  static const _recordsKey = 'escape_intervention_outcomes_v1';

  @override
  Future<void> append(InterventionOutcomeRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_recordsKey) ?? <String>[];
    final next = <String>[...current, jsonEncode(record.toJson())];
    await prefs.setStringList(_recordsKey, next);
  }

  @override
  Future<List<InterventionOutcomeRecord>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recordsKey) ?? const <String>[];

    final parsed = <InterventionOutcomeRecord>[];
    for (final entry in raw) {
      try {
        final json = jsonDecode(entry);
        if (json is Map<String, dynamic>) {
          parsed.add(
            InterventionOutcomeRecord.fromJson(
              json.map((key, value) => MapEntry<String, Object?>(key, value)),
            ),
          );
        }
      } on FormatException {
        // Ignore malformed legacy/local rows rather than breaking the app.
      } on StateError {
        // Ignore rows containing an enum value unknown to this app version.
      } on TypeError {
        // Ignore structurally invalid rows.
      }
    }
    return parsed;
  }

  @override
  Future<DateTime?> latestCooldownUntil() async {
    final records = await readAll();
    if (records.isEmpty) return null;
    records.sort((a, b) => b.respondedAt.compareTo(a.respondedAt));
    return records.first.cooldownUntil;
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}
