// ══════════════════════════════════════════════════════════════
// test/progress_test.dart — Testes de progresso e utilitários
// ══════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_personal_ai/features/workout/domain/models/workout_models.dart';
import 'package:meu_personal_ai/shared/utils/formatters.dart';

void main() {

  group('ExercisePerformancePoint.fromJson', () {
    test('deserializa ponto de performance', () {
      final json = {
        'week': '2026-04-14T00:00:00Z',
        'max_load': 120.0,
        'avg_load': 105.5,
      };
      final p = ExercisePerformancePoint.fromJson(json);
      expect(p.maxLoad, 120.0);
      expect(p.avgLoad, 105.5);
      expect(p.week.year, 2026);
    });

    test('valores inteiros são convertidos para double', () {
      final json = {
        'week': '2026-01-01T00:00:00Z',
        'max_load': 100,
        'avg_load': 90,
      };
      final p = ExercisePerformancePoint.fromJson(json);
      expect(p.maxLoad, isA<double>());
      expect(p.avgLoad, isA<double>());
    });

    test('default é 0 quando campo ausente', () {
      final json = {'week': '2026-01-01T00:00:00Z'};
      final p = ExercisePerformancePoint.fromJson(json);
      expect(p.maxLoad, 0.0);
      expect(p.avgLoad, 0.0);
    });
  });

  group('WeekDay.fromJson', () {
    test('deserializa todos os status', () {
      for (final status in WeekDayStatus.values) {
        final json = {'label': 'Seg', 'status': status.name};
        expect(WeekDay.fromJson(json).status, status);
      }
    });

    test('status desconhecido cai em future', () {
      final json = {'label': 'X', 'status': 'invalid_status'};
      expect(WeekDay.fromJson(json).status, WeekDayStatus.future);
    });
  });

  group('roundToPlate', () {
    test('arredonda para múltiplo de 1.25', () {
      expect(roundToPlate(80.0), 80.0);
      expect(roundToPlate(81.0), 81.25);
      expect(roundToPlate(82.3), 82.5);
      expect(roundToPlate(82.6), 82.5);
      expect(roundToPlate(100.7), 101.25);
    });

    test('zero permanece zero', () {
      expect(roundToPlate(0.0), 0.0);
    });

    test('valores negativos (descargas) também arredondam', () {
      // Em prática não usamos negativos, mas o comportamento deve ser previsível
      expect(roundToPlate(-5.0), -5.0);
    });
  });

  group('DurationFormat extension', () {
    test('formata mm:ss corretamente', () {
      expect(const Duration(minutes: 1, seconds: 30).toMMSS(), '01:30');
      expect(const Duration(seconds: 5).toMMSS(), '00:05');
      expect(const Duration(minutes: 10).toMMSS(), '10:00');
      expect(const Duration(minutes: 90, seconds: 45).toMMSS(), '90:45');
    });
  });

  group('WeightInputFormatter', () {
    final formatter = WeightInputFormatter();

    TextEditingValue fmt(String text) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: text),
      );
    }

    test('aceita número inteiro', () {
      expect(fmt('80').text, '80');
    });

    test('aceita um ponto decimal', () {
      expect(fmt('82.5').text, '82.5');
    });

    test('rejeita dois pontos decimais', () {
      // deve retornar o valor anterior (vazio)
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '82.5'),
        const TextEditingValue(text: '82.5.'),
      );
      expect(result.text, '82.5'); // rejeita, mantém anterior
    });

    test('remove letras', () {
      expect(fmt('abc').text, '');
      expect(fmt('80kg').text, '80');
    });

    test('limita a 1 casa decimal', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '82.5'),
        const TextEditingValue(text: '82.55'),
      );
      expect(result.text, '82.5'); // rejeita segunda casa decimal
    });
  });

  group('StringExt extension', () {
    test('isNotEmpty retorna false para string vazia', () {
      expect(''.isNotEmpty(), false);
      expect('   '.isNotEmpty(), false);
    });

    test('isNotEmpty retorna true para string com conteúdo', () {
      expect('abc'.isNotEmpty(), true);
      expect(' a '.isNotEmpty(), true);
    });

    test('capitalizeFirst capitaliza a primeira letra', () {
      expect('hello'.capitalizeFirst(), 'Hello');
      expect(''.capitalizeFirst(), '');
      expect('ABC'.capitalizeFirst(), 'ABC');
    });
  });

  group('AnamnesisFormData', () {
    test('estado inicial tem valores sensatos', () {
      const form = AnamnesisFormData();
      expect(form.goal, 'hypertrophy');
      expect(form.level, 'beginner');
      expect(form.weeklyFrequency, 3);
      expect(form.acceptedTerms, false);
      expect(form.acceptedHealth, false);
    });

    test('copyWith atualiza apenas campos especificados', () {
      const form = AnamnesisFormData();
      final updated = form.copyWith(goal: 'strength', weeklyFrequency: 4);
      expect(updated.goal, 'strength');
      expect(updated.weeklyFrequency, 4);
      expect(updated.level, form.level); // não mudou
    });

    test('toJson serializa todos os campos obrigatórios', () {
      const form = AnamnesisFormData();
      final json = form.toJson();
      expect(json.containsKey('goal'), true);
      expect(json.containsKey('acceptedTerms'), true);
      expect(json.containsKey('acceptedHealthDataUsage'), true);
    });

    test('injuries e medicalConds são imutáveis com copyWith', () {
      const form = AnamnesisFormData(injuries: ['Joelho']);
      final updated = form.copyWith(goal: 'health');
      expect(updated.injuries, ['Joelho']); // preservado
    });
  });
}
