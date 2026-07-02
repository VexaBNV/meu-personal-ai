import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../lib/features/exercises/data/exercise_repository.dart';
import '../lib/features/exercises/presentation/exercise_library_screen.dart';
import 'exercises_test.mocks.dart';

@GenerateMocks([ExerciseRepository])
void main() {
  // ── Modelo ───────────────────────────────────────────────
  group('Exercise.fromJson', () {
    test('parsing básico', () {
      final e = Exercise.fromJson({
        'id': '1', 'name': 'Supino Reto', 'muscleGroup': 'Peito',
        'difficulty': 'intermediate', 'type': 'compound',
        'equipment': ['barbell', 'bench'],
      });
      expect(e.id, '1');
      expect(e.name, 'Supino Reto');
      expect(e.muscleGroup, 'Peito');
      expect(e.difficulty, 'intermediate');
      expect(e.equipment, ['barbell', 'bench']);
    });

    test('aceita muscle_group em snake_case', () {
      final e = Exercise.fromJson({
        'id': '2', 'name': 'Agachamento',
        'muscle_group': 'Pernas', 'difficulty': 'beginner',
      });
      expect(e.muscleGroup, 'Pernas');
      expect(e.equipment, isEmpty);
    });

    test('toJson → fromJson roundtrip', () {
      const original = Exercise(
        id: '42', name: 'Rosca Direta', muscleGroup: 'Bíceps',
        difficulty: 'beginner', type: 'isolation',
        equipment: ['barbell'],
        instructions: ['Segure a barra', 'Flexione'],
        coachingCues: ['Cotovelo fixo'],
      );
      final restored = Exercise.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.equipment, original.equipment);
      expect(restored.instructions, original.instructions);
      expect(restored.coachingCues, original.coachingCues);
    });
  });

  // ── filteredExercisesProvider ────────────────────────────
  group('filteredExercisesProvider', () {
    final exercises = [
      const Exercise(id:'1', name:'Supino Reto',   muscleGroup:'Peito',   difficulty:'intermediate', type:'compound'),
      const Exercise(id:'2', name:'Agachamento',   muscleGroup:'Pernas',  difficulty:'intermediate', type:'compound'),
      const Exercise(id:'3', name:'Rosca Direta',  muscleGroup:'Bíceps',  difficulty:'beginner',     type:'isolation'),
      const Exercise(id:'4', name:'Crucifixo',     muscleGroup:'Peito',   difficulty:'intermediate', type:'isolation'),
      const Exercise(id:'5', name:'Puxada Frontal',muscleGroup:'Costas',  difficulty:'beginner',     type:'compound'),
    ];

    ProviderContainer _container({String q='', String? muscle, String? type}) =>
      ProviderContainer(overrides: [
        exerciseLibraryProvider.overrideWith((_) async => exercises),
        exerciseSearchProvider.overrideWith((_) => q),
        exerciseMuscleFilterProvider.overrideWith((_) => muscle),
        exerciseTypeFilterProvider.overrideWith((_) => type),
      ]);

    test('sem filtros retorna todos', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      expect(c.read(filteredExercisesProvider).length, 5);
    });

    test('filtro por grupo muscular', () async {
      final c = _container(muscle: 'Peito');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final result = c.read(filteredExercisesProvider);
      expect(result.length, 2);
      expect(result.every((e) => e.muscleGroup == 'Peito'), isTrue);
    });

    test('filtro por tipo', () async {
      final c = _container(type: 'isolation');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final result = c.read(filteredExercisesProvider);
      expect(result.length, 2);
      expect(result.every((e) => e.type == 'isolation'), isTrue);
    });

    test('busca por nome case-insensitive', () async {
      final c = _container(q: 'supino');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final result = c.read(filteredExercisesProvider);
      expect(result.length, 1);
      expect(result.first.name, 'Supino Reto');
    });

    test('busca por músculo', () async {
      final c = _container(q: 'costas');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final result = c.read(filteredExercisesProvider);
      expect(result.length, 1);
      expect(result.first.name, 'Puxada Frontal');
    });

    test('filtro + busca combinados', () async {
      final c = _container(muscle: 'Peito', type: 'isolation');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final result = c.read(filteredExercisesProvider);
      expect(result.length, 1);
      expect(result.first.name, 'Crucifixo');
    });

    test('sem resultado retorna lista vazia', () async {
      final c = _container(q: 'xpto');
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      expect(c.read(filteredExercisesProvider), isEmpty);
    });
  });

  // ── muscleGroupsProvider ─────────────────────────────────
  group('muscleGroupsProvider', () {
    test('retorna grupos únicos e ordenados', () async {
      final exercises = [
        const Exercise(id:'1', name:'A', muscleGroup:'Peito',   difficulty:'beginner'),
        const Exercise(id:'2', name:'B', muscleGroup:'Costas',  difficulty:'beginner'),
        const Exercise(id:'3', name:'C', muscleGroup:'Peito',   difficulty:'beginner'),
        const Exercise(id:'4', name:'D', muscleGroup:'Bíceps',  difficulty:'beginner'),
      ];
      final c = ProviderContainer(overrides: [
        exerciseLibraryProvider.overrideWith((_) async => exercises),
      ]);
      addTearDown(c.dispose);
      await c.read(exerciseLibraryProvider.future);
      final groups = c.read(muscleGroupsProvider);
      expect(groups, ['Bíceps', 'Costas', 'Peito']); // ordenado
      expect(groups.length, 3); // sem duplicata
    });
  });

  // ── Widget: ExerciseLibraryScreen ────────────────────────
  group('ExerciseLibraryScreen', () {
    final mockExercises = [
      const Exercise(id:'1', name:'Supino Reto', muscleGroup:'Peito',
        difficulty:'intermediate', type:'compound', equipment:['barbell']),
      const Exercise(id:'2', name:'Agachamento', muscleGroup:'Pernas',
        difficulty:'intermediate', type:'compound', equipment:['barbell']),
    ];

    testWidgets('exibe skeleton durante loading', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith(
            (_) => Future.delayed(const Duration(seconds: 1), () => mockExercises)),
        ],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ));
      // Skeleton deve estar visível antes do Future resolver
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('exibe exercícios após carregar', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith((_) async => mockExercises),
        ],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Supino Reto'), findsOneWidget);
      expect(find.text('Agachamento'), findsOneWidget);
    });

    testWidgets('campo de busca filtra exercícios', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith((_) async => mockExercises),
        ],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'supino');
      await tester.pumpAndSettle();
      expect(find.text('Supino Reto'), findsOneWidget);
      expect(find.text('Agachamento'), findsNothing);
    });
  });
}
