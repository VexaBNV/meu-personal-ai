import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/theme/app_colors.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';

// ── Modelo ───────────────────────────────────────────────────
class ExpressWorkout {
  final String name, focus, intensity, coachNote;
  final int totalMinutes;
  final List<ExpressExercise> exercises;

  const ExpressWorkout({
    required this.name, required this.focus, required this.intensity,
    required this.coachNote, required this.totalMinutes, required this.exercises,
  });

  factory ExpressWorkout.fromJson(Map<String, dynamic> j) => ExpressWorkout(
    name: j['name'], focus: j['focus'], intensity: j['intensity'],
    coachNote: j['coachNote'], totalMinutes: j['totalMinutes'],
    exercises: (j['exercises'] as List).map((e) => ExpressExercise.fromJson(e)).toList(),
  );
}

class ExpressExercise {
  final String name, reps, technique;
  final int sets, restSeconds;
  const ExpressExercise({
    required this.name, required this.reps, required this.technique,
    required this.sets, required this.restSeconds,
  });
  factory ExpressExercise.fromJson(Map<String, dynamic> j) => ExpressExercise(
    name: j['name'], reps: j['reps'], technique: j['technique'],
    sets: j['sets'], restSeconds: j['restSeconds'],
  );
}

// ── Providers ────────────────────────────────────────────────
final expressWorkoutProvider = FutureProvider.family<ExpressWorkout, _ExpressParams>(
  (ref, params) async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.post('/workout/express', data: params.toJson());
    return ExpressWorkout.fromJson(res.data);
  },
);

class _ExpressParams {
  final int duration;
  final String environment, focus, intensity;
  final List<String> equipment;
  const _ExpressParams({
    required this.duration, required this.environment,
    required this.focus, required this.intensity, required this.equipment,
  });
  Map<String, dynamic> toJson() => {
    'durationMinutes': duration, 'environment': environment,
    'focus': focus, 'intensity': intensity, 'availableEquipment': equipment,
  };
  @override bool operator ==(o) => o is _ExpressParams && o.duration == duration && o.focus == focus;
  @override int get hashCode => Object.hash(duration, focus);
}

// ── Sheet de configuração ─────────────────────────────────────
class ExpressWorkoutSheet extends ConsumerStatefulWidget {
  const ExpressWorkoutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExpressWorkoutSheet(),
    );
  }

  @override createState() => _SheetState();
}

class _SheetState extends ConsumerState<ExpressWorkoutSheet> {
  int _duration = 20;
  String _environment = 'gym';
  String _focus = 'full_body';
  String _intensity = 'medium';
  bool _generating = false;
  ExpressWorkout? _result;
  String? _error;

  static const _durations = [15, 20, 30];
  static const _envs = {'gym': '🏋️ Academia', 'home': '🏠 Casa', 'outdoor': '🌳 Ao ar livre'};
  static const _focuses = {
    'full_body': 'Corpo todo', 'superior': 'Superior',
    'inferior': 'Inferior', 'core': 'Core',
  };
  static const _intensities = {'low': 'Leve', 'medium': 'Moderado', 'high': 'Intenso'};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .6,
      maxChildSize: .98,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _result != null ? _buildResult(scroll) : _buildConfig(scroll),
      ),
    );
  }

  Widget _buildConfig(ScrollController scroll) => Column(children: [
    Container(
      width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
    ),
    Expanded(child: SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Treino Express', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.bolt_rounded, color: AppColors.brandPrimary, size: 24),
        ]),
        const SizedBox(height: 4),
        Text('IA gera um treino na hora, adaptado para você',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        _Label('Duração'),
        const SizedBox(height: 8),
        Row(children: _durations.map((d) => Expanded(child: GestureDetector(
          onTap: () => setState(() => _duration = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _duration == d ? AppColors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _duration == d ? AppColors.black : AppColors.divider),
            ),
            child: Column(children: [
              Text('$d', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: _duration == d ? Colors.white : AppColors.textPrimary)),
              Text('min', style: TextStyle(
                fontSize: 11, color: _duration == d ? Colors.white70 : AppColors.textSecondary)),
            ]),
          ),
        ))).toList()),

        const SizedBox(height: 20),
        _Label('Ambiente'),
        const SizedBox(height: 8),
        _ChipGroup(_envs, _environment, (v) => setState(() => _environment = v)),

        const SizedBox(height: 20),
        _Label('Foco'),
        const SizedBox(height: 8),
        _ChipGroup(_focuses, _focus, (v) => setState(() => _focus = v)),

        const SizedBox(height: 20),
        _Label('Intensidade'),
        const SizedBox(height: 8),
        _ChipGroup(_intensities, _intensity, (v) => setState(() => _intensity = v)),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
        ],
      ]),
    )),

    Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton.icon(
        onPressed: _generating ? null : _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: _generating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        label: Text(_generating ? 'Gerando treino...' : 'Gerar treino com IA',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    ),
  ]);

  Widget _buildResult(ScrollController scroll) => Column(children: [
    Container(
      width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
    ),
    Expanded(child: SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header do resultado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.black, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(_result!.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary, borderRadius: BorderRadius.circular(20)),
                child: Text('${_result!.totalMinutes}min',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(_result!.coachNote,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 16),

        // Lista de exercícios
        ..._result!.exercises.asMap().entries.map((e) {
          final ex = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ex.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${ex.sets}×${ex.reps}  ·  ${ex.restSeconds}s descanso',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (ex.technique.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(ex.technique,
                    style: TextStyle(fontSize: 11, color: AppColors.brandPrimary, fontStyle: FontStyle.italic)),
                ],
              ])),
            ]),
          );
        }),
      ]),
    )),

    Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: navegar para ExecutionScreen com este treino express
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Começar treino',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() { _result = null; _error = null; }),
          child: Text('Gerar outro', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ]),
    ),
  ]);

  Future<void> _generate() async {
    setState(() { _generating = true; _error = null; });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/workout/express', data: {
        'durationMinutes': _duration,
        'environment': _environment,
        'focus': _focus,
        'intensity': _intensity,
        'availableEquipment': _environment == 'gym'
            ? ['barbell', 'dumbbells', 'cable', 'machine', 'bench']
            : _environment == 'home'
                ? ['dumbbells', 'bodyweight', 'resistance_band']
                : ['bodyweight'],
      });
      setState(() { _result = ExpressWorkout.fromJson(res.data); });
    } catch (e) {
      setState(() => _error = 'Erro ao gerar treino. Verifique sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
}

class _ChipGroup extends StatelessWidget {
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ChipGroup(this.options, this.selected, this.onChanged);

  @override
  Widget build(BuildContext ctx) => Wrap(
    spacing: 8, runSpacing: 8,
    children: options.entries.map((e) => GestureDetector(
      onTap: () => onChanged(e.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected == e.key ? AppColors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected == e.key ? AppColors.black : AppColors.divider),
        ),
        child: Text(e.value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: selected == e.key ? Colors.white : AppColors.textPrimary,
        )),
      ),
    )).toList(),
  );
}
