import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';

// ── Modelo ───────────────────────────────────────────────────

class Exercise {
  final String  id;
  final String  name;
  final String  muscleGroup;   // 'Peito' | 'Costas' | 'Pernas' | ...
  final String  difficulty;    // 'beginner' | 'intermediate' | 'advanced'
  final String? type;          // 'compound' | 'isolation' | 'cardio' | 'mobility'
  final List<String> equipment;
  final List<String>? instructions;
  final List<String>? coachingCues;
  final List<String>? substitutions; // IDs dos substitutos

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
    this.type,
    this.equipment = const [],
    this.instructions,
    this.coachingCues,
    this.substitutions,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id:           j['id']?.toString() ?? '',
    name:         j['name']?.toString() ?? '',
    muscleGroup:  j['muscleGroup'] ?? j['muscle_group'] ?? '',
    difficulty:   j['difficulty'] ?? 'beginner',
    type:         j['type'],
    equipment:    (j['equipment'] as List?)?.map((e) => e.toString()).toList() ?? [],
    instructions: (j['instructions'] as List?)?.map((e) => e.toString()).toList(),
    coachingCues: (j['coachingCues'] ?? j['coaching_cues'] as List?)
        ?.map((e) => e.toString()).toList(),
    substitutions: (j['substitutions'] as List?)?.map((e) => e.toString()).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'muscleGroup': muscleGroup,
    'difficulty': difficulty, 'type': type, 'equipment': equipment,
    'instructions': instructions, 'coachingCues': coachingCues,
    'substitutions': substitutions,
  };
}

// ── Repositório ──────────────────────────────────────────────

class ExerciseRepository {
  final ApiClient _api;
  static const _cacheKey  = 'exercise_library';
  static const _cacheTime = 'exercise_library_ts';
  static const _ttl       = Duration(hours: 24);

  ExerciseRepository(this._api);

  Future<List<Exercise>> getAll() async {
    // 1. Tentar cache Hive
    final cached = await _fromCache();
    if (cached != null) return cached;

    // 2. Buscar da API
    final fresh = await _fromApi();
    await _toCache(fresh);
    return fresh;
  }

  Future<Exercise?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Exercise>> getSubstitutes(String exerciseId) async {
    final exercise = await getById(exerciseId);
    if (exercise == null || exercise.substitutions == null) return [];
    final all = await getAll();
    return all.where((e) => exercise.substitutions!.contains(e.id)).toList();
  }

  Future<void> invalidateCache() async {
    final box = Hive.box('workout_cache');
    await box.delete(_cacheKey);
    await box.delete(_cacheTime);
  }

  // ── Interno ──────────────────────────────────────────────

  Future<List<Exercise>?> _fromCache() async {
    try {
      final box = Hive.box('workout_cache');
      final tsMs = box.get(_cacheTime) as int?;
      if (tsMs == null) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs));
      if (age > _ttl) return null;

      final raw = box.get(_cacheKey);
      if (raw == null) return null;

      final list = (raw as List).cast<Map>();
      return list.map((m) => Exercise.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Exercise>> _fromApi() async {
    final res  = await _api.dio.get('/exercises');
    final data = res.data as List;
    return data.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _toCache(List<Exercise> exercises) async {
    final box = Hive.box('workout_cache');
    await box.put(_cacheKey, exercises.map((e) => e.toJson()).toList());
    await box.put(_cacheTime, DateTime.now().millisecondsSinceEpoch);
  }
}

// ── Providers ────────────────────────────────────────────────

final exerciseRepositoryProvider = Provider((ref) {
  return ExerciseRepository(ref.read(apiClientProvider));
});

/// Todos os exercícios — com cache de 24h
final exerciseLibraryProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.read(exerciseRepositoryProvider).getAll();
});

/// Busca + filtro em memória (sem re-fetch)
final exerciseSearchProvider       = StateProvider<String>((_) => '');
final exerciseMuscleFilterProvider = StateProvider<String?>((_) => null);
final exerciseTypeFilterProvider   = StateProvider<String?>((_) => null);

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final all    = ref.watch(exerciseLibraryProvider).valueOrNull ?? [];
  final query  = ref.watch(exerciseSearchProvider).toLowerCase().trim();
  final muscle = ref.watch(exerciseMuscleFilterProvider);
  final type   = ref.watch(exerciseTypeFilterProvider);

  return all.where((e) {
    if (query.isNotEmpty &&
        !e.name.toLowerCase().contains(query) &&
        !e.muscleGroup.toLowerCase().contains(query)) return false;
    if (muscle != null && e.muscleGroup != muscle) return false;
    if (type   != null && e.type != type)           return false;
    return true;
  }).toList();
});

/// Grupos musculares únicos presentes na biblioteca
final muscleGroupsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(exerciseLibraryProvider).valueOrNull ?? [];
  final groups = all.map((e) => e.muscleGroup).toSet().toList()..sort();
  return groups;
});
