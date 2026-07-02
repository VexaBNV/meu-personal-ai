import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import '../data/exercise_repository.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final substitutesAsync = ref.watch(
      _substitutesProvider(exercise.id),
    );

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(exercise.name),
        backgroundColor: context.cardColor,
        foregroundColor: context.textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: context.divColor),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── Header ───────────────────────────────────────────
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _Tag(exercise.muscleGroup, context.textSecColor, context.bgColor),
            _Tag(_diffLabel(exercise.difficulty),
              _diffColor(exercise.difficulty).$1, _diffColor(exercise.difficulty).$2),
            if (exercise.type != null)
              _Tag(_typeLabel(exercise.type!),
                const Color(0xFF185FA5), const Color(0xFFE6F1FB)),
          ]),
        ])),

        const SizedBox(height: 10),

        // ── Equipamento ──────────────────────────────────────
        if (exercise.equipment.isNotEmpty)
          _InfoRow(
            icon: Icons.fitness_center_rounded,
            label: 'Equipamento',
            value: exercise.equipment.join(', '),
          ),

        const SizedBox(height: 10),

        // ── Instruções ───────────────────────────────────────
        if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Como executar', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 12),
            ...exercise.instructions!.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.black, shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: TextStyle(
                  fontSize: 13, color: context.textColor, height: 1.55))),
              ]),
            )),
          ])),

        if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
          const SizedBox(height: 10),

        // ── Dicas do coach ───────────────────────────────────
        if (exercise.coachingCues != null && exercise.coachingCues!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brandPrimary.withOpacity(.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.psychology_rounded,
                  color: AppColors.brandPrimary, size: 18),
                const SizedBox(width: 6),
                Text('Dicas do coach', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary)),
              ]),
              const SizedBox(height: 10),
              ...exercise.coachingCues!.map((cue) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('• ', style: TextStyle(
                    color: AppColors.brandPrimary, fontSize: 16,
                    fontWeight: FontWeight.w700)),
                  Expanded(child: Text(cue, style: TextStyle(
                    fontSize: 13, color: AppColors.brandPrimary.withOpacity(.85),
                    height: 1.45))),
                ]),
              )),
            ]),
          ),

        const SizedBox(height: 10),

        // ── Substitutos ──────────────────────────────────────
        substitutesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (subs) {
            if (subs.isEmpty) return const SizedBox.shrink();
            return _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Substitutos sugeridos', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: context.textColor)),
                const SizedBox(height: 10),
                ...subs.map((s) => GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exercise: s))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: context.bgColor,
                          borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(
                          _emoji(s.muscleGroup),
                          style: const TextStyle(fontSize: 16)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: context.textColor)),
                          Text(_diffLabel(s.difficulty),
                            style: TextStyle(fontSize: 11,
                              color: context.textSecColor)),
                        ],
                      )),
                      Icon(Icons.chevron_right,
                        size: 16, color: context.divColor),
                    ]),
                  ),
                )),
              ],
            ));
          },
        ),

        const SizedBox(height: 32),
      ]),
    );
  }

  String _diffLabel(String d) => switch (d) {
    'beginner' => 'Iniciante',
    'advanced' => 'Avançado',
    _          => 'Intermediário',
  };

  (Color, Color) _diffColor(String d) => switch (d) {
    'beginner' => (const Color(0xFF3B6D11), const Color(0xFFEAF3DE)),
    'advanced' => (const Color(0xFFA32D2D), const Color(0xFFFCEBEB)),
    _          => (const Color(0xFF854F0B), const Color(0xFFFAEEDA)),
  };

  String _typeLabel(String t) => switch (t) {
    'compound'  => 'Multiarticular',
    'isolation' => 'Isolado',
    'cardio'    => 'Cardio',
    'mobility'  => 'Mobilidade',
    _           => t,
  };

  String _emoji(String m) => const {
    'Peito': '💪', 'Costas': '🏋️', 'Pernas': '🦵',
    'Ombros': '🤸', 'Core': '🎯', 'Glúteos': '🏃',
  }[m] ?? '🏋️';
}

// ── Provider de substitutos ─────────────────────────────────

final _substitutesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, id) {
  return ref.read(exerciseRepositoryProvider).getSubstitutes(id);
});

// ── Sub-widgets ──────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor),
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.divColor),
    ),
    child: Row(children: [
      Icon(icon, size: 18, color: context.textSecColor),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, color: context.textSecColor)),
      const Spacer(),
      Text(value, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: context.textColor)),
    ]),
  );
}

class _Tag extends StatelessWidget {
  final String l; final Color t, b;
  const _Tag(this.l, this.t, this.b);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(20)),
    child: Text(l, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: t)));
}
