import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tipos de dado que lemos/escrevemos
const _readTypes = [
  HealthDataType.WEIGHT,
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.WORKOUT,
];

const _writeTypes = [
  HealthDataType.WEIGHT,
  HealthDataType.WORKOUT,
];

class HealthService {
  final _health = Health();
  bool _authorized = false;

  /// Solicita permissões — chamar quando usuário habilitar nas configurações
  Future<bool> requestPermissions() async {
    await _health.configure();
    _authorized = await _health.requestAuthorization(_readTypes, permissions: [
      ..._readTypes.map((_) => HealthDataAccess.READ),
      ..._writeTypes.map((_) => HealthDataAccess.READ_WRITE),
    ]);
    return _authorized;
  }

  /// Verifica se já tem autorização
  Future<bool> hasAuthorization() async {
    _authorized = await _health.hasPermissions(_readTypes) ?? false;
    return _authorized;
  }

  // ── Escrita ──────────────────────────────────────────────

  /// Salva sessão concluída no Apple Health / Google Fit
  Future<bool> saveWorkout({
    required DateTime start,
    required DateTime end,
    required HealthWorkoutActivityType activityType,
    required double totalEnergyBurned, // kcal
    double? distance, // km, opcional
  }) async {
    if (!_authorized) return false;
    try {
      return await _health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: end,
        totalEnergyBurned: totalEnergyBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        totalDistance: distance != null ? distance * 1000 : null, // m
        totalDistanceUnit: distance != null ? HealthDataUnit.METER : null,
      );
    } catch (_) {
      return false;
    }
  }

  /// Salva peso (kg)
  Future<bool> saveWeight(double kg, {DateTime? at}) async {
    if (!_authorized) return false;
    try {
      return await _health.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: at ?? DateTime.now(),
        endTime: at ?? DateTime.now(),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Leitura ──────────────────────────────────────────────

  /// Lê peso mais recente
  Future<double?> getLatestWeight() async {
    if (!_authorized) return null;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: DateTime.now().subtract(const Duration(days: 30)),
        endTime: DateTime.now(),
        types: [HealthDataType.WEIGHT],
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      return (data.first.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  /// Lê passos do dia
  Future<int?> getTodaySteps() async {
    if (!_authorized) return null;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      return steps;
    } catch (_) {
      return null;
    }
  }

  /// Mapeia tipo de treino do app → HealthWorkoutActivityType
  static HealthWorkoutActivityType mapWorkoutType(String sessionType) {
    final lower = sessionType.toLowerCase();
    if (lower.contains('peito') || lower.contains('costas') ||
        lower.contains('ombro') || lower.contains('bícep') ||
        lower.contains('trícep') || lower.contains('perna') ||
        lower.contains('força')) {
      return HealthWorkoutActivityType.STRENGTH_TRAINING;
    }
    if (lower.contains('cardio') || lower.contains('corrida')) {
      return HealthWorkoutActivityType.RUNNING;
    }
    if (lower.contains('yoga') || lower.contains('mobilidade')) {
      return HealthWorkoutActivityType.YOGA;
    }
    return HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING;
  }
}

// ── Providers ────────────────────────────────────────────────

final healthServiceProvider = Provider((_) => HealthService());

final healthAuthProvider = FutureProvider<bool>((ref) {
  return ref.read(healthServiceProvider).hasAuthorization();
});

// ── Integração com WorkoutCompleteScreen ────────────────────
// Chamar após completeSession() com sucesso:
//
// final health = ref.read(healthServiceProvider);
// await health.saveWorkout(
//   start: session.startedAt,
//   end: session.completedAt!,
//   activityType: HealthService.mapWorkoutType(session.name),
//   totalEnergyBurned: session.estimatedCalories ?? 300,
// );
// // Se o usuário atualizou o peso na anamnese:
// if (profileUpdate.weight != null) {
//   await health.saveWeight(profileUpdate.weight!);
// }
