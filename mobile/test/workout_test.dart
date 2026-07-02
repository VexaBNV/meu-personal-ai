// ══════════════════════════════════════════════════════════════
// test/workout_test.dart — Testes dos modelos de treino
// ══════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_personal_ai/features/workout/domain/models/workout_models.dart';

void main() {

  group('Exercise.fromJson', () {
    test('deserializa exercício completo', () {
      final json = {
        'id': 'ex1',
        'name': 'Agachamento Livre',
        'muscleGroup': 'Pernas',
        'primaryMuscles': ['Quadríceps', 'Glúteos'],
        'instructions': ['Pés na largura dos ombros', 'Desça controlado'],
        'coachingCues': ['Joelhos acompanham os pés'],
        'commonErrors': ['Joelhos para dentro'],
        'stimulusType': 'compound',
        'equipment': ['Barra'],
      };
      final ex = Exercise.fromJson(json);
      expect(ex.name, 'Agachamento Livre');
      expect(ex.primaryMuscles.length, 2);
      expect(ex.equipment.first, 'Barra');
    });

    test('aceita snake_case', () {
      final json = {
        'id': 'ex2', 'name': 'Supino',
        'muscle_group': 'Peito',
        'primary_muscles': ['Peitoral'],
        'coaching_cues': [], 'common_errors': [],
        'instructions': [], 'stimulus_type': 'compound',
        'equipment': [],
      };
      final ex = Exercise.fromJson(json);
      expect(ex.muscleGroup, 'Peito');
    });

    test('videoUrl é opcional', () {
      final json = {
        'id': 'ex3', 'name': 'Flexão',
        'muscleGroup': 'Peito', 'primaryMuscles': [],
        'instructions': [], 'coachingCues': [],
        'commonErrors': [], 'stimulusType': 'compound',
        'equipment': [],
      };
      final ex = Exercise.fromJson(json);
      expect(ex.videoUrl, null);
    });
  });

  group('SessionExercise.fromJson', () {
    test('deserializa com valores default para campos ausentes', () {
      final json = {
        'id': 'se1',
        'exercise': {
          'id': 'ex1', 'name': 'Rosca Direta',
          'muscleGroup': 'Bíceps', 'primaryMuscles': [],
          'instructions': [], 'coachingCues': [],
          'commonErrors': [], 'stimulusType': 'isolation',
          'equipment': ['Halter'],
        },
      };
      final se = SessionExercise.fromJson(json);
      expect(se.sets, 3);         // default
      expect(se.repsMin, 8);      // default
      expect(se.repsMax, 12);     // default
      expect(se.restSeconds, 90); // default
    });

    test('toJson inclui campos necessários', () {
      final se = SessionExercise.fromJson({
        'id': 'se1', 'sets': 4, 'repsMin': 6, 'repsMax': 8,
        'loadKg': 100.0, 'restSeconds': 120, 'rpeTarget': 8.0,
        'exercise': {
          'id': 'ex1', 'name': 'Leg Press',
          'muscleGroup': 'Pernas', 'primaryMuscles': [],
          'instructions': [], 'coachingCues': [],
          'commonErrors': [], 'stimulusType': 'compound',
          'equipment': ['Máquina'],
        },
      });
      final json = se.toJson();
      expect(json['sets'], 4);
      expect(json['loadKg'], 100.0);
    });

    test('exerciseId e name são getters do Exercise aninhado', () {
      final se = SessionExercise.fromJson({
        'id': 'se1',
        'exercise': {
          'id': 'ex99', 'name': 'Terra',
          'muscleGroup': 'Costas', 'primaryMuscles': [],
          'instructions': [], 'coachingCues': [],
          'commonErrors': [], 'stimulusType': 'compound',
          'equipment': ['Barra'],
        },
      });
      expect(se.exerciseId, 'ex99');
      expect(se.name, 'Terra');
    });
  });

  group('Session.fromJson', () {
    test('deserializa sessão com exercícios', () {
      final json = {
        'id': 's1', 'name': 'Treino A', 'focus': 'Peito e Tríceps',
        'estimatedDuration': 60, 'dayOfWeek': 1,
        'exercises': [
          {
            'id': 'se1',
            'exercise': {
              'id': 'ex1', 'name': 'Supino',
              'muscleGroup': 'Peito', 'primaryMuscles': [],
              'instructions': [], 'coachingCues': [],
              'commonErrors': [], 'stimulusType': 'compound',
              'equipment': ['Barra'],
            },
          },
        ],
      };
      final session = Session.fromJson(json);
      expect(session.name, 'Treino A');
      expect(session.exercises.length, 1);
      expect(session.exercises.first.name, 'Supino');
    });

    test('toJson serializa exercícios', () {
      final session = Session.fromJson({
        'id': 's1', 'name': 'B', 'focus': 'Costas',
        'estimatedDuration': 45, 'dayOfWeek': 3, 'exercises': [],
      });
      final json = session.toJson();
      expect(json['name'], 'B');
      expect(json['exercises'], isEmpty);
    });
  });

  group('SessionLog.fromJson', () {
    test('deserializa SessionLog corretamente', () {
      final json = {
        'exerciseId': 'ex1',
        'setNumber': 2,
        'loadKg': 80.0,
        'repsDone': 10,
        'outcome': 'success',
        'loggedAt': '2026-04-22T10:00:00Z',
        'painReported': false,
      };
      final log = SessionLog.fromJson(json);
      expect(log.setNumber, 2);
      expect(log.outcome, SetOutcome.success);
      expect(log.painReported, false);
    });

    test('outcome desconhecido cai em success', () {
      final json = {
        'exerciseId': 'ex1', 'setNumber': 1, 'loadKg': 50.0,
        'repsDone': 8, 'outcome': 'unknown_value',
        'loggedAt': '2026-04-22T10:00:00Z',
      };
      final log = SessionLog.fromJson(json);
      expect(log.outcome, SetOutcome.success);
    });

    test('todos os SetOutcome são mapeados', () {
      for (final outcome in SetOutcome.values) {
        final json = {
          'exerciseId': 'e', 'setNumber': 1, 'loadKg': 0.0,
          'repsDone': 0, 'outcome': outcome.name,
          'loggedAt': '2026-04-22T10:00:00Z',
        };
        expect(SessionLog.fromJson(json).outcome, outcome);
      }
    });
  });

  group('DashboardStats.fromJson', () {
    test('deserializa stats do dashboard', () {
      final json = {
        'streak': 14,
        'adherence': 87.5,
        'sessions_completed': 3,
        'sessions_planned': 4,
        'volume': 12.4,
        'weightKg': 82.0,
        'bodyFatPct': 18.0,
        'weekDays': [],
      };
      final stats = DashboardStats.fromJson(json);
      expect(stats.streakDays, 14);
      expect(stats.adherenceRate, 87.5);
      expect(stats.weeklySessionsDone, 3);
    });

    test('valores default quando campos ausentes', () {
      final stats = DashboardStats.fromJson({});
      expect(stats.streakDays, 0);
      expect(stats.adherenceRate, 0.0);
      expect(stats.weekDays, isEmpty);
    });
  });

  group('Challenge', () {
    test('progressPercent calcula corretamente', () {
      final c = Challenge.fromJson({
        'id': 'c1', 'title': 'Desafio', 'description': '',
        'type': 'weekly', 'target_count': 10, 'progress': 7,
      });
      expect(c.progressPercent, closeTo(0.7, 0.001));
    });

    test('progressPercent é 0 se targetCount é 0', () {
      final c = Challenge.fromJson({
        'id': 'c1', 'title': 'Zero', 'description': '',
        'type': 'daily', 'target_count': 0,
      });
      expect(c.progressPercent, 0.0);
    });

    test('progressPercent é clampado em 1.0', () {
      final c = Challenge.fromJson({
        'id': 'c1', 'title': 'Over', 'description': '',
        'type': 'monthly', 'target_count': 5, 'progress': 99,
      });
      expect(c.progressPercent, 1.0);
    });
  });

  group('RankingEntry', () {
    test('initials() retorna iniciais', () {
      final e = RankingEntry.fromJson({
        'id': 'r1', 'name': 'Pedro Alves',
        'streak_days': 7, 'adherence_rate': 90.0,
        'points': 500, 'rank': 1,
      });
      expect(e.initials(), 'PA');
    });

    test('isCurrentUser é false por padrão', () {
      final e = RankingEntry.fromJson({
        'id': 'r1', 'name': 'Ana',
        'streak_days': 3, 'adherence_rate': 75.0,
        'points': 200, 'rank': 5,
      });
      expect(e.isCurrentUser, false);
    });
  });
}
