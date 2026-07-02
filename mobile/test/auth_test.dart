// ══════════════════════════════════════════════════════════════
// test/auth_test.dart — Testes de autenticação
// ══════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_personal_ai/features/auth/data/auth_notifier.dart';
import 'package:meu_personal_ai/features/auth/domain/auth_state.dart';

void main() {
  group('AuthState', () {
    test('estado inicial é unauthenticated', () {
      const state = AuthState.unauthenticated();
      expect(state.isAuthenticated, false);
      expect(state.needsAnamnesis, false);
    });

    test('authenticated com needsAnamnesis=true', () {
      const state = AuthState.authenticated(
        userId: 'uid123',
        needsAnamnesis: true,
      );
      expect(state.isAuthenticated, true);
      expect(state.needsAnamnesis, true);
      expect(state.userId, 'uid123');
    });

    test('authenticated com needsAnamnesis=false', () {
      const state = AuthState.authenticated(
        userId: 'uid123',
        needsAnamnesis: false,
      );
      expect(state.isAuthenticated, true);
      expect(state.needsAnamnesis, false);
    });
  });

  group('UserProfile.fromJson', () {
    test('deserializa campos camelCase', () {
      final json = {
        'id': 'u1',
        'name': 'João Silva',
        'email': 'joao@email.com',
        'primaryGoal': 'hypertrophy',
        'level': 'intermediate',
        'environment': 'gym',
        'equipment': ['Barra', 'Halter'],
        'injuries': [],
        'weeklyFrequency': 4,
        'sessionDuration': 60,
        'weightKg': 80.0,
        'heightCm': 175.0,
        'age': 30,
        'aiName': 'Alex',
        'aiAvatar': '🤖',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.name, 'João Silva');
      expect(profile.equipment.length, 2);
      expect(profile.weeklyFrequency, 4);
    });

    test('deserializa campos snake_case', () {
      final json = {
        'id': 'u2',
        'name': 'Maria',
        'email': 'maria@email.com',
        'primary_goal': 'weight_loss',
        'level': 'beginner',
        'environment': 'home',
        'equipment': [],
        'weekly_frequency': 3,
        'session_duration': 45,
        'weight_kg': 65.0,
        'height_cm': 160.0,
        'age': 25,
        'ai_name': 'Sam',
        'ai_avatar': '🏋️',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.primaryGoal, 'weight_loss');
      expect(profile.weeklyFrequency, 3);
      expect(profile.aiName, 'Sam');
    });

    test('firstName() retorna primeiro nome', () {
      final json = _minimalProfileJson('Ana Paula Souza');
      expect(UserProfile.fromJson(json).firstName(), 'Ana');
    });

    test('initials() retorna iniciais do nome completo', () {
      final json = _minimalProfileJson('Carlos Roberto');
      expect(UserProfile.fromJson(json).initials(), 'CR');
    });

    test('initials() funciona com nome único', () {
      final json = _minimalProfileJson('Madonna');
      expect(UserProfile.fromJson(json).initials(), 'M');
    });
  });
}

Map<String, dynamic> _minimalProfileJson(String name) => {
  'id': 'u1', 'name': name, 'email': 'test@test.com',
  'primaryGoal': 'hypertrophy', 'level': 'beginner',
  'environment': 'gym', 'equipment': [], 'age': 25,
  'weightKg': 70.0, 'heightCm': 170.0,
};
