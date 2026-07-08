import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:health/health.dart';
import 'health_service.dart';

// ── Chaves Hive ──────────────────────────────────────────────
const _kSyncWorkouts = 'health_sync_workouts';
const _kSyncWeight   = 'health_sync_weight';
const _kReadSteps    = 'health_read_steps';
const _kAuthorized   = 'health_authorized';
const _kLastSync     = 'health_last_sync';

// ── Estado ───────────────────────────────────────────────────
class HealthState {
  final bool authorized;
  final bool syncWorkouts;
  final bool syncWeight;
  final bool readSteps;
  final DateTime? lastSync;
  final int? todaySteps;
  final double? latestWeight;

  const HealthState({
    this.authorized    = false,
    this.syncWorkouts  = false,
    this.syncWeight    = false,
    this.readSteps     = false,
    this.lastSync,
    this.todaySteps,
    this.latestWeight,
  });

  HealthState copyWith({
    bool? authorized, bool? syncWorkouts, bool? syncWeight,
    bool? readSteps, DateTime? lastSync,
    int? todaySteps, double? latestWeight,
  }) => HealthState(
    authorized:   authorized   ?? this.authorized,
    syncWorkouts: syncWorkouts ?? this.syncWorkouts,
    syncWeight:   syncWeight   ?? this.syncWeight,
    readSteps:    readSteps    ?? this.readSteps,
    lastSync:     lastSync     ?? this.lastSync,
    todaySteps:   todaySteps   ?? this.todaySteps,
    latestWeight: latestWeight ?? this.latestWeight,
  );
}

// ── Notifier ─────────────────────────────────────────────────
class HealthNotifier extends AsyncNotifier<HealthState> {
  late HealthService _svc;
  late Box _box;

  @override
  Future<HealthState> build() async {
    _svc = ref.read(healthServiceProvider);
    _box = Hive.box('user_cache');

    final authorized = _box.get(_kAuthorized, defaultValue: false) as bool;
    final lastSyncMs = _box.get(_kLastSync) as int?;

    var state = HealthState(
      authorized:   authorized,
      syncWorkouts: _box.get(_kSyncWorkouts, defaultValue: false),
      syncWeight:   _box.get(_kSyncWeight,   defaultValue: false),
      readSteps:    _box.get(_kReadSteps,    defaultValue: false),
      lastSync:     lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
          : null,
    );

    // Se já autorizado, busca dados frescos em background
    if (authorized && state.readSteps) {
      state = await _fetchData(state);
    }

    return state;
  }

  // ── Permissões ───────────────────────────────────────────

  Future<bool> requestPermissions() async {
    final granted = await _svc.requestPermissions();
    _box.put(_kAuthorized, granted);
    if (granted) {
      final newState = await _fetchData(state.value!.copyWith(authorized: true));
      state = AsyncData(newState);
    } else {
      state = AsyncData(state.value!.copyWith(authorized: false));
    }
    return granted;
  }

  // ── Toggles de configuração ──────────────────────────────

  void toggleSyncWorkouts(bool v) {
    _box.put(_kSyncWorkouts, v);
    state = AsyncData(state.value!.copyWith(syncWorkouts: v));
  }

  void toggleSyncWeight(bool v) {
    _box.put(_kSyncWeight, v);
    state = AsyncData(state.value!.copyWith(syncWeight: v));
  }

  void toggleReadSteps(bool v) {
    _box.put(_kReadSteps, v);
    state = AsyncData(state.value!.copyWith(readSteps: v));
  }

  // ── Sincronização manual ─────────────────────────────────

  Future<void> syncNow() async {
    if (state.value?.authorized != true) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const HealthState();
      final updated = await _fetchData(current);
      final now = DateTime.now();
      _box.put(_kLastSync, now.millisecondsSinceEpoch);
      return updated.copyWith(lastSync: now);
    });
  }

  // ── Salvar treino concluído ──────────────────────────────
  /// Chamado pela WorkoutCompleteScreen após completar sessão.
  Future<void> saveCompletedWorkout({
    required DateTime start,
    required DateTime end,
    required String sessionName,
    double? estimatedCalories,
  }) async {
    if (state.value?.authorized != true) return;
    if (state.value?.syncWorkouts != true) return;

    await _svc.saveWorkout(
      start:              start,
      end:                end,
      activityType:       HealthService.mapWorkoutType(sessionName),
      totalEnergyBurned:  estimatedCalories ?? 300,
    );
  }

  /// Chamado quando o usuário atualiza o peso no EditProfileScreen.
  Future<void> saveWeight(double kg) async {
    if (state.value?.authorized != true) return;
    if (state.value?.syncWeight != true) return;
    await _svc.saveWeight(kg);
  }

  // ── Interno ──────────────────────────────────────────────

  Future<HealthState> _fetchData(HealthState current) async {
    int? steps;
    double? weight;

    if (current.readSteps) {
      steps = await _svc.getTodaySteps();
    }
    if (current.syncWeight) {
      weight = await _svc.getLatestWeight();
    }

    return current.copyWith(
      todaySteps:   steps,
      latestWeight: weight,
    );
  }
}

// ── Providers públicos ───────────────────────────────────────

final healthProvider =
    AsyncNotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);

/// Passos de hoje — null se não autorizado ou sem permissão de leitura
final todayStepsProvider = Provider<int?>((ref) {
  return ref.watch(healthProvider).valueOrNull?.todaySteps;
});

/// Peso mais recente do Health — null se não disponível
final healthWeightProvider = Provider<double?>((ref) {
  return ref.watch(healthProvider).valueOrNull?.latestWeight;
});

/// true se Health está conectado e pelo menos um toggle ativo
final healthActiveProvider = Provider<bool>((ref) {
  final s = ref.watch(healthProvider).valueOrNull;
  if (s == null || !s.authorized) return false;
  return s.syncWorkouts || s.syncWeight || s.readSteps;
});
