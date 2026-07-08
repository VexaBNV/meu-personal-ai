import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import 'package:meu_personal_ai/features/exercises/data/exercise_repository.dart';

// ── Provider ─────────────────────────────────────────────────

final _substitutesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, exerciseId) {
  return ref.read(exerciseRepositoryProvider).getSubstitutes(exerciseId);
});

// ── Sheet ─────────────────────────────────────────────────────

/// Bottom sheet para trocar exercício durante a execução.
/// Exibe substitutos com compatibilidade de músculo/equipamento.
///
/// Uso:
///   final chosen = await ExerciseSubstitutionSheet.show(
///     context, ref,
///     exerciseId: exercise.id,
///     exerciseName: exercise.name,
///   );
///   if (chosen != null) substituteExercise(chosen);
class ExerciseSubstitutionSheet extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseSubstitutionSheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  static Future<Exercise?> show(
    BuildContext context,
    WidgetRef ref, {
    required String exerciseId,
    required String exerciseName,
  }) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseSubstitutionSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(_substitutesProvider(exerciseId));

    return DraggableScrollableSheet(
      initialChildSize: .65,
      minChildSize: .4,
      maxChildSize: .92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: context.divColor,
              borderRadius: BorderRadius.circular(2)),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trocar exercício', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: context.textColor)),
              const SizedBox(height: 4),
              Text('Substitutos para $exerciseName',
                style: TextStyle(fontSize: 13, color: context.textSecColor)),
            ]),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.divColor),

          // Lista
          Expanded(
            child: subsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_rounded, size: 40, color: context.divColor),
                  const SizedBox(height: 12),
                  Text('Não foi possível carregar',
                    style: TextStyle(color: context.textSecColor)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(_substitutesProvider(exerciseId)),
                    child: const Text('Tentar novamente')),
                ]),
              ),
              data: (subs) {
                if (subs.isEmpty) return _EmptyState(exerciseName: exerciseName);
                return ListView.separated(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _SubstituteCard(
                    exercise: subs[i],
                    onTap: () => Navigator.pop(ctx, subs[i]),
                  ),
                );
              },
            ),
          ),

          // Botão cancelar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Manter exercício atual'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Card de substituto ────────────────────────────────────────

class _SubstituteCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  const _SubstituteCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divColor),
      ),
      child: Row(children: [
        // Ícone de músculo
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(
            _muscleEmoji(exercise.muscleGroup),
            style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: context.textColor)),
            const SizedBox(height: 3),
            Wrap(spacing: 6, children: [
              _Tag(exercise.muscleGroup, context),
              if (exercise.equipment.isNotEmpty)
                _Tag(exercise.equipment.first, context),
              _DiffTag(exercise.difficulty),
            ]),
          ],
        )),
        // CTA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(8)),
          child: const Text('Usar', style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );

  String _muscleEmoji(String m) => const {
    'Peito': '💪', 'Costas': '🏋️', 'Pernas': '🦵',
    'Ombros': '🤸', 'Core': '🎯', 'Glúteos': '🏃',
  }[m] ?? '🏋️';
}

class _Tag extends StatelessWidget {
  final String text;
  final BuildContext ctx;
  const _Tag(this.text, this.ctx);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: ctx.cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ctx.divColor)),
    child: Text(text, style: TextStyle(
      fontSize: 10, color: ctx.textSecColor)),
  );
}

class _DiffTag extends StatelessWidget {
  final String difficulty;
  const _DiffTag(this.difficulty);
  @override
  Widget build(BuildContext context) {
    final (label, tc, bg) = switch (difficulty) {
      'beginner' => ('Iniciante', const Color(0xFF3B6D11), const Color(0xFFEAF3DE)),
      'advanced' => ('Avançado',  const Color(0xFFA32D2D), const Color(0xFFFCEBEB)),
      _          => ('Inter.',    const Color(0xFF854F0B), const Color(0xFFFAEEDA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600, color: tc)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String exerciseName;
  const _EmptyState({required this.exerciseName});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.swap_horiz_rounded, size: 48, color: context.divColor),
      const SizedBox(height: 12),
      Text('Nenhum substituto cadastrado',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: context.textColor)),
      const SizedBox(height: 4),
      Text('O coach pode sugerir alternativas no chat.',
        style: TextStyle(fontSize: 13, color: context.textSecColor)),
    ],
  ));
}
