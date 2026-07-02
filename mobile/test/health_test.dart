import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:health/health.dart';
import '../lib/features/health/data/health_service.dart';
import '../lib/features/health/data/health_provider.dart';
import 'health_test.mocks.dart';

@GenerateMocks([HealthService])
void main() {
  // ── HealthService.mapWorkoutType ─────────────────────────
  group('HealthService.mapWorkoutType', () {
    test('peito → STRENGTH_TRAINING', () {
      expect(
        HealthService.mapWorkoutType('Peito + Tríceps'),
        HealthWorkoutActivityType.STRENGTH_TRAINING,
      );
    });

    test('pernas → STRENGTH_TRAINING', () {
      expect(
        HealthService.mapWorkoutType('Pernas'),
        HealthWorkoutActivityType.STRENGTH_TRAINING,
      );
    });

    test('cardio → RUNNING', () {
      expect(
        HealthService.mapWorkoutType('Cardio HIIT'),
        HealthWorkoutActivityType.RUNNING,
      );
    });

    test('yoga → YOGA', () {
      expect(
        HealthService.mapWorkoutType('Yoga e Mobilidade'),
        HealthWorkoutActivityType.YOGA,
      );
    });

    test('desconhecido → FUNCTIONAL_STRENGTH_TRAINING', () {
      expect(
        HealthService.mapWorkoutType('Treino misto'),
        HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      );
    });
  });

  // ── HealthState ──────────────────────────────────────────
  group('HealthState.copyWith', () {
    test('mantém valores não alterados', () {
      const base = HealthState(
        authorized:   true,
        syncWorkouts: true,
        syncWeight:   false,
        readSteps:    true,
        todaySteps:   8500,
      );

      final updated = base.copyWith(syncWeight: true);

      expect(updated.authorized,   isTrue);
      expect(updated.syncWorkouts, isTrue);
      expect(updated.syncWeight,   isTrue);  // atualizado
      expect(updated.readSteps,    isTrue);
      expect(updated.todaySteps,   8500);    // mantido
    });
  });

  // ── Providers ────────────────────────────────────────────
  group('todayStepsProvider', () {
    test('retorna null quando healthProvider não tem dados', () {
      final container = ProviderContainer(overrides: [
        healthProvider.overrideWith(() => _FakeHealthNotifier(
          const HealthState(authorized: true, todaySteps: null),
        )),
      ]);
      addTearDown(container.dispose);
      expect(container.read(todayStepsProvider), isNull);
    });

    test('retorna passos quando disponível', () {
      final container = ProviderContainer(overrides: [
        healthProvider.overrideWith(() => _FakeHealthNotifier(
          const HealthState(authorized: true, todaySteps: 7324),
        )),
      ]);
      addTearDown(container.dispose);
      expect(container.read(todayStepsProvider), 7324);
    });
  });

  group('healthActiveProvider', () {
    test('false quando não autorizado', () {
      final container = ProviderContainer(overrides: [
        healthProvider.overrideWith(() => _FakeHealthNotifier(
          const HealthState(authorized: false),
        )),
      ]);
      addTearDown(container.dispose);
      expect(container.read(healthActiveProvider), isFalse);
    });

    test('true quando autorizado e pelo menos um toggle ativo', () {
      final container = ProviderContainer(overrides: [
        healthProvider.overrideWith(() => _FakeHealthNotifier(
          const HealthState(authorized: true, syncWorkouts: true),
        )),
      ]);
      addTearDown(container.dispose);
      expect(container.read(healthActiveProvider), isTrue);
    });

    test('false quando autorizado mas nenhum toggle ativo', () {
      final container = ProviderContainer(overrides: [
        healthProvider.overrideWith(() => _FakeHealthNotifier(
          const HealthState(authorized: true),
        )),
      ]);
      addTearDown(container.dispose);
      expect(container.read(healthActiveProvider), isFalse);
    });
  });

  // ── Widget: StepsCard ─────────────────────────────────────
  group('StepsCard', () {
    testWidgets('não renderiza quando steps é null', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProvider.overrideWith(() => _FakeHealthNotifier(
            const HealthState(authorized: false),
          )),
        ],
        child: const MaterialApp(home: Scaffold(body: StepsCard())),
      ));
      expect(find.text('passos hoje'), findsNothing);
    });

    testWidgets('exibe passos quando disponível', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProvider.overrideWith(() => _FakeHealthNotifier(
            const HealthState(authorized: true, readSteps: true, todaySteps: 6200),
          )),
        ],
        child: const MaterialApp(home: Scaffold(body: StepsCard())),
      ));
      expect(find.text('passos hoje'), findsOneWidget);
      expect(find.text('6.2k'), findsOneWidget);
    });

    testWidgets('exibe mensagem de meta atingida', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProvider.overrideWith(() => _FakeHealthNotifier(
            const HealthState(authorized: true, readSteps: true, todaySteps: 10500),
          )),
        ],
        child: const MaterialApp(home: Scaffold(body: StepsCard())),
      ));
      expect(find.text('Meta de 10k atingida! 🎉'), findsOneWidget);
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────

class _FakeHealthNotifier extends AsyncNotifier<HealthState> {
  final HealthState _initial;
  _FakeHealthNotifier(this._initial);

  @override
  Future<HealthState> build() async => _initial;

  @override
  void toggleSyncWorkouts(bool v) =>
      state = AsyncData(state.value!.copyWith(syncWorkouts: v));

  @override
  void toggleSyncWeight(bool v) =>
      state = AsyncData(state.value!.copyWith(syncWeight: v));

  @override
  void toggleReadSteps(bool v) =>
      state = AsyncData(state.value!.copyWith(readSteps: v));

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> syncNow() async {}

  @override
  Future<void> saveCompletedWorkout({
    required DateTime start, required DateTime end,
    required String sessionName, double? estimatedCalories,
  }) async {}

  @override
  Future<void> saveWeight(double kg) async {}
}
