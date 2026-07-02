import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import '../data/exercise_repository.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  createState() => _State();
}

class _State extends ConsumerState<ExerciseLibraryScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered       = ref.watch(filteredExercisesProvider);
    final muscleGroups   = ref.watch(muscleGroupsProvider);
    final allAsync       = ref.watch(exerciseLibraryProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);
    final selectedType   = ref.watch(exerciseTypeFilterProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Exercícios'),
        backgroundColor: context.cardColor,
        foregroundColor: context.textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: context.divColor),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: allAsync.maybeWhen(
                data: (list) => Text('${list.length} exercícios',
                  style: TextStyle(fontSize: 12, color: context.textSecColor)),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => ref.read(exerciseSearchProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Buscar exercício ou músculo...',
              prefixIcon: Icon(Icons.search, color: context.textSecColor, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: context.textSecColor),
                      onPressed: () {
                        _ctrl.clear();
                        ref.read(exerciseSearchProvider.notifier).state = '';
                      })
                  : null,
            ),
          ),
        ),
        if (muscleGroups.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              children: [
                _Chip('Todos', selectedMuscle == null && selectedType == null, null, () {
                  ref.read(exerciseMuscleFilterProvider.notifier).state = null;
                  ref.read(exerciseTypeFilterProvider.notifier).state   = null;
                }),
                ...muscleGroups.map((m) => _Chip(
                  '${_emoji(m)} $m', selectedMuscle == m, null,
                  () => ref.read(exerciseMuscleFilterProvider.notifier).state =
                      selectedMuscle == m ? null : m,
                )),
              ],
            ),
          ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            children: [
              for (final t in ['compound', 'isolation', 'cardio', 'mobility'])
                _Chip(_typeLabel(t), selectedType == t,
                  selectedType == t ? const Color(0xFF534AB7) : null,
                  () => ref.read(exerciseTypeFilterProvider.notifier).state =
                      selectedType == t ? null : t),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: allAsync.when(
          loading: () => _Skeleton(),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(exerciseLibraryProvider)),
          data: (_) => filtered.isEmpty
              ? _EmptyView(
                  hasFilters: _ctrl.text.isNotEmpty || selectedMuscle != null || selectedType != null,
                  onClear: () {
                    _ctrl.clear();
                    ref.read(exerciseSearchProvider.notifier).state       = '';
                    ref.read(exerciseMuscleFilterProvider.notifier).state = null;
                    ref.read(exerciseTypeFilterProvider.notifier).state   = null;
                  })
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _ExCard(
                    ex: filtered[i],
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exercise: filtered[i]))),
                  ),
                ),
        )),
      ]),
    );
  }

  String _emoji(String m) => const {
    'Peito':'💪','Costas':'🏋️','Pernas':'🦵','Ombros':'🤸',
    'Bíceps':'💪','Tríceps':'💪','Core':'🎯','Glúteos':'🏃',
  }[m] ?? '🏋️';

  String _typeLabel(String t) => const {
    'compound':'Multi','isolation':'Isolado','cardio':'Cardio','mobility':'Mobilidade',
  }[t] ?? t;
}

class _Chip extends StatelessWidget {
  final String label; final bool selected; final Color? color; final VoidCallback onTap;
  const _Chip(this.label, this.selected, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : context.divColor),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected ? Colors.white : context.textColor)),
      ),
    );
  }
}

class _ExCard extends StatelessWidget {
  final Exercise ex; final VoidCallback onTap;
  const _ExCard({required this.ex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final d = _diff(ex.difficulty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.divColor)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.bgColor, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_emoji(ex.muscleGroup), style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ex.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              _Tag(ex.muscleGroup, context.textSecColor, context.bgColor),
              _Tag(d.$1, d.$2, d.$3),
              if (ex.type != null) _Tag(_tl(ex.type!), const Color(0xFF185FA5), const Color(0xFFE6F1FB)),
            ]),
            if (ex.equipment.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(ex.equipment.take(3).join(' · '),
                style: TextStyle(fontSize: 11, color: context.textSecColor.withOpacity(.7))),
            ],
          ])),
          Icon(Icons.chevron_right, color: context.divColor, size: 20),
        ]),
      ),
    );
  }

  (String,Color,Color) _diff(String d) => switch(d) {
    'beginner' => ('Iniciante', const Color(0xFF3B6D11), const Color(0xFFEAF3DE)),
    'advanced' => ('Avançado',  const Color(0xFFA32D2D), const Color(0xFFFCEBEB)),
    _          => ('Inter.',    const Color(0xFF854F0B), const Color(0xFFFAEEDA)),
  };

  String _emoji(String m) => const {'Peito':'💪','Costas':'🏋️','Pernas':'🦵','Ombros':'🤸',
    'Bíceps':'💪','Tríceps':'💪','Core':'🎯','Glúteos':'🏃'}[m] ?? '🏋️';

  String _tl(String t) => const {'compound':'Multi','isolation':'Isolado',
    'cardio':'Cardio','mobility':'Mobilidade'}[t] ?? t;
}

class _Tag extends StatelessWidget {
  final String l; final Color t, b;
  const _Tag(this.l, this.t, this.b);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(8)),
    child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t)));
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    itemCount: 8,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (ctx, _) => Container(
      height: 76,
      decoration: BoxDecoration(color: context.cardColor,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: context.divColor)),
      child: Row(children: [
        const SizedBox(width: 14),
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 12),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 13, width: 160,
            decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 7),
          Container(height: 10, width: 100,
            decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(6))),
        ])),
      ]),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final bool hasFilters; final VoidCallback onClear;
  const _EmptyView({required this.hasFilters, required this.onClear});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, size: 48, color: context.divColor),
    const SizedBox(height: 12),
    Text('Nenhum exercício encontrado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textColor)),
    const SizedBox(height: 4),
    Text(hasFilters ? 'Ajuste os filtros' : 'Tente outro termo',
      style: TextStyle(fontSize: 13, color: context.textSecColor)),
    if (hasFilters) ...[const SizedBox(height: 16), OutlinedButton(onPressed: onClear, child: const Text('Limpar filtros'))],
  ]));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.wifi_off_rounded, size: 48, color: context.divColor),
    const SizedBox(height: 12),
    const Text('Não foi possível carregar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Text('Verifique sua conexão', style: TextStyle(fontSize: 13, color: context.textSecColor)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Tentar novamente')),
  ]));
}
