import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import '../data/health_provider.dart';

/// Card compacto de passos do dia para a HomeScreen.
/// Visível apenas quando Health está conectado e readSteps = true.
///
/// Uso na HomeScreen:
///   if (ref.watch(healthActiveProvider)) const StepsCard(),
class StepsCard extends ConsumerWidget {
  const StepsCard({super.key});

  static const _goal = 10000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(todayStepsProvider);

    // Não renderiza se sem dados
    if (steps == null) return const SizedBox.shrink();

    final pct = (steps / _goal).clamp(0.0, 1.0);
    final reached = steps >= _goal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Row(children: [
        // Ícone
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: reached
                ? AppColors.success.withOpacity(.12)
                : AppColors.brandPrimary.withOpacity(.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(
            Icons.directions_walk_rounded,
            size: 20,
            color: reached ? AppColors.success : AppColors.brandPrimary,
          )),
        ),
        const SizedBox(width: 12),

        // Texto + barra
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_fmtSteps(steps),
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: context.textColor)),
            const SizedBox(width: 4),
            Text('passos hoje',
              style: TextStyle(fontSize: 12, color: context.textSecColor)),
          ]),
          const SizedBox(height: 6),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: context.divColor,
              color: reached ? AppColors.success : AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reached
                ? 'Meta de $_goalStr atingida! 🎉'
                : '${_fmtSteps(_goal - steps)} para a meta de $_goalStr',
            style: TextStyle(fontSize: 11, color: context.textSecColor),
          ),
        ])),
      ]),
    );
  }

  String _fmtSteps(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  static final _goalStr = '10k';
}

/// Versão inline para usar dentro de um Row ou Grid da HomeScreen.
class StepsInline extends ConsumerWidget {
  const StepsInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(todayStepsProvider);
    if (steps == null) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.directions_walk_rounded, size: 14, color: AppColors.brandPrimary),
      const SizedBox(width: 4),
      Text(
        steps >= 1000 ? '${(steps / 1000).toStringAsFixed(1)}k' : steps.toString(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 2),
      Text('passos', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
