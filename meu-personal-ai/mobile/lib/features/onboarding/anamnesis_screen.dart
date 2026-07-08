import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_personal_ai/core/config/app_config.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';

// ── Estado do formulário ─────────────────────────────────────

class AnamnesisFormData {
  // Passo 1 — Objetivos
  final String goal;           // 'hypertrophy' | 'weight_loss' | 'strength' | 'health'
  final String level;          // 'beginner' | 'intermediate' | 'advanced'
  final int    weeklyFrequency;// 2 | 3 | 4 | 5

  // Passo 2 — Dados físicos
  final double weight;         // kg
  final double height;         // cm
  final int    age;
  final String sex;            // 'male' | 'female' | 'other'

  // Passo 3 — Saúde e histórico
  final List<String> injuries;     // regiões com lesão
  final List<String> medicalConds; // condições médicas relevantes
  final bool   hasCardioIssue;
  final bool   hasDoctorClearance; // médico liberou exercício

  // Passo 4 — Estilo de treino
  final String environment;        // 'gym' | 'home' | 'outdoor' | 'mixed'
  final List<String> equipment;    // equipamentos disponíveis
  final int    sessionDurationMin; // duração preferida em minutos
  final String timeOfDay;          // 'morning' | 'afternoon' | 'evening' | 'flexible'

  // Passo 5 — Preferências da IA
  final String coachTone;      // 'motivational' | 'technical' | 'friendly' | 'strict'
  final String coachPreset;    // 'personal1' | 'personal2' | 'personal3' | 'personal4'
  final String coachName;      // nome customizado do coach

  // Passo 6 — Contrato & privacidade
  final bool acceptedTerms;
  final bool acceptedHealth;
  final bool acceptedMarketing;

  const AnamnesisFormData({
    this.goal = 'hypertrophy',
    this.level = 'beginner',
    this.weeklyFrequency = 3,
    this.weight = 70,
    this.height = 170,
    this.age = 28,
    this.sex = 'male',
    this.injuries = const [],
    this.medicalConds = const [],
    this.hasCardioIssue = false,
    this.hasDoctorClearance = false,
    this.environment = 'gym',
    this.equipment = const [],
    this.sessionDurationMin = 60,
    this.timeOfDay = 'flexible',
    this.coachTone = 'motivational',
    this.coachPreset = 'personal1',
    this.coachName = AppConfig.aiCoachName,
    this.acceptedTerms = false,
    this.acceptedHealth = false,
    this.acceptedMarketing = false,
  });

  AnamnesisFormData copyWith({
    String? goal, String? level, int? weeklyFrequency,
    double? weight, double? height, int? age, String? sex,
    List<String>? injuries, List<String>? medicalConds,
    bool? hasCardioIssue, bool? hasDoctorClearance,
    String? environment, List<String>? equipment,
    int? sessionDurationMin, String? timeOfDay,
    String? coachTone, String? coachPreset, String? coachName,
    bool? acceptedTerms, bool? acceptedHealth, bool? acceptedMarketing,
  }) => AnamnesisFormData(
    goal: goal ?? this.goal,
    level: level ?? this.level,
    weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    injuries: injuries ?? this.injuries,
    medicalConds: medicalConds ?? this.medicalConds,
    hasCardioIssue: hasCardioIssue ?? this.hasCardioIssue,
    hasDoctorClearance: hasDoctorClearance ?? this.hasDoctorClearance,
    environment: environment ?? this.environment,
    equipment: equipment ?? this.equipment,
    sessionDurationMin: sessionDurationMin ?? this.sessionDurationMin,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    coachTone: coachTone ?? this.coachTone,
    coachPreset: coachPreset ?? this.coachPreset,
    coachName: coachName ?? this.coachName,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    acceptedHealth: acceptedHealth ?? this.acceptedHealth,
    acceptedMarketing: acceptedMarketing ?? this.acceptedMarketing,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal, 'level': level, 'weeklyFrequency': weeklyFrequency,
    'weight': weight, 'height': height, 'age': age, 'sex': sex,
    'injuries': injuries, 'medicalConditions': medicalConds,
    'hasCardiovascularIssue': hasCardioIssue,
    'hasDoctorClearance': hasDoctorClearance,
    'environment': environment, 'equipment': equipment,
    'sessionDurationMinutes': sessionDurationMin, 'timeOfDay': timeOfDay,
    'coachTone': coachTone, 'coachPreset': coachPreset, 'coachName': coachName,
    'acceptedTerms': acceptedTerms, 'acceptedHealthDataUsage': acceptedHealth,
    'acceptedMarketing': acceptedMarketing,
  };
}

final _formProvider = StateProvider((_) => const AnamnesisFormData());

// ── Tela principal ────────────────────────────────────────────

class AnamnesisScreen extends ConsumerStatefulWidget {
  const AnamnesisScreen({super.key});
  @override
  createState() => _AnamnesisScreenState();
}

class _AnamnesisScreenState extends ConsumerState<AnamnesisScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _submitting = false;
  static const _totalSteps = 6;

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_formProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(child: Column(children: [
        // ── Header com progresso ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            Row(children: [
              if (_step > 0)
                GestureDetector(
                  onTap: _back,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: context.textColor),
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Passo ${_step + 1} de $_totalSteps',
                    style: TextStyle(fontSize: 11, color: context.textSecColor)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 5,
                      backgroundColor: context.divColor,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(_stepTitle(_step),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: context.textColor)),
            ),
          ]),
        ),

        // ── Conteúdo dos passos ───────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Step1Objetivos(form: form, onChanged: _update),
              _Step2DadosFisicos(form: form, onChanged: _update),
              _Step3Saude(form: form, onChanged: _update),
              _Step4Estilo(form: form, onChanged: _update),
              _Step5Coach(form: form, onChanged: _update),
              _Step6Termos(form: form, onChanged: _update),
            ],
          ),
        ),

        // ── Botão avançar / finalizar ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ElevatedButton(
            onPressed: _canAdvance(form) ? (_submitting ? null : _advance) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: context.divColor,
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _step < _totalSteps - 1 ? 'Continuar' : 'Criar meu programa',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ])),
    );
  }

  String _stepTitle(int s) => [
    'Qual é seu objetivo?',
    'Dados físicos',
    'Saúde e histórico',
    'Estilo de treino',
    'Seu coach de IA',
    'Quase lá!',
  ][s];

  bool _canAdvance(AnamnesisFormData f) {
    if (_step == 5) return f.acceptedTerms && f.acceptedHealth;
    if (_step == 2 && f.hasCardioIssue) return f.hasDoctorClearance;
    return true;
  }

  void _update(AnamnesisFormData updated) {
    ref.read(_formProvider.notifier).state = updated;
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _advance() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Passo final — submeter
    setState(() => _submitting = true);
    try {
      final form = ref.read(_formProvider);
      final api  = ref.read(apiClientProvider);
      await api.dio.post('/users/anamnesis', data: form.toJson());

      if (mounted) {
        // Polling até o programa estar pronto
        await _pollForProgram();
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e. Tente novamente.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pollForProgram() async {
    final api = ref.read(apiClientProvider);
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final res = await api.dio.get('/workout/program/status');
        if (res.data['status'] == 'ready') return;
      } catch (_) {}
    }
  }
}

// ══════════════════════════════════════════════════════════════
// PASSO 1 — OBJETIVOS
// ══════════════════════════════════════════════════════════════

class _Step1Objetivos extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step1Objetivos({required this.form, required this.onChanged});

  static const _goals = {
    'hypertrophy': ('Hipertrofia', '💪', 'Ganhar massa muscular'),
    'weight_loss':  ('Emagrecimento','🔥', 'Perder gordura corporal'),
    'strength':     ('Força',       '🏋️', 'Ficar mais forte'),
    'health':       ('Saúde geral', '❤️', 'Melhorar bem-estar'),
  };

  static const _levels = {
    'beginner':     ('Iniciante',       '< 1 ano de treino'),
    'intermediate': ('Intermediário',   '1–3 anos de treino'),
    'advanced':     ('Avançado',        '> 3 anos de treino'),
  };

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    children: [
      _SectionLabel('Qual é seu principal objetivo?', context),
      const SizedBox(height: 10),
      ..._goals.entries.map((e) => _OptionCard(
        leading: Text(e.value.$2, style: const TextStyle(fontSize: 26)),
        title: e.value.$1,
        subtitle: e.value.$3,
        selected: form.goal == e.key,
        onTap: () => onChanged(form.copyWith(goal: e.key)),
      )),
      const SizedBox(height: 20),
      _SectionLabel('Qual é seu nível de experiência?', context),
      const SizedBox(height: 10),
      ..._levels.entries.map((e) => _OptionCard(
        title: e.value.$1,
        subtitle: e.value.$2,
        selected: form.level == e.key,
        onTap: () => onChanged(form.copyWith(level: e.key)),
      )),
      const SizedBox(height: 20),
      _SectionLabel('Quantos dias por semana você pode treinar?', context),
      const SizedBox(height: 10),
      Row(children: [2, 3, 4, 5].map((d) => Expanded(child: GestureDetector(
        onTap: () => onChanged(form.copyWith(weeklyFrequency: d)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: form.weeklyFrequency == d
                ? AppColors.black : context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: form.weeklyFrequency == d
                  ? AppColors.black : context.divColor),
          ),
          child: Column(children: [
            Text('$d', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: form.weeklyFrequency == d ? Colors.white : context.textColor)),
            Text('dias', style: TextStyle(fontSize: 10,
              color: form.weeklyFrequency == d
                  ? Colors.white70 : context.textSecColor)),
          ]),
        ),
      ))).toList()),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// PASSO 2 — DADOS FÍSICOS
// ══════════════════════════════════════════════════════════════

class _Step2DadosFisicos extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step2DadosFisicos({required this.form, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    children: [
      // Peso + Altura
      Row(children: [
        Expanded(child: _NumericField(
          label: 'Peso (kg)', value: form.weight,
          min: 40, max: 200, step: 0.5,
          onChanged: (v) => onChanged(form.copyWith(weight: v)),
        )),
        const SizedBox(width: 12),
        Expanded(child: _NumericField(
          label: 'Altura (cm)', value: form.height,
          min: 140, max: 220, step: 1,
          onChanged: (v) => onChanged(form.copyWith(height: v)),
        )),
      ]),
      const SizedBox(height: 16),

      // Idade
      _NumericField(
        label: 'Idade', value: form.age.toDouble(),
        min: 16, max: 80, step: 1,
        onChanged: (v) => onChanged(form.copyWith(age: v.toInt())),
        wide: true,
      ),
      const SizedBox(height: 20),

      // Sexo biológico (usado para cálculos de IA)
      _SectionLabel('Sexo biológico', context),
      const SizedBox(height: 4),
      Text('Usado para personalizar recomendações de carga e nutrição.',
        style: TextStyle(fontSize: 11, color: context.textSecColor)),
      const SizedBox(height: 10),
      Row(children: [
        for (final s in ['male', 'female', 'other'])
          Expanded(child: GestureDetector(
            onTap: () => onChanged(form.copyWith(sex: s)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: s == 'other' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: form.sex == s ? AppColors.black : context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: form.sex == s ? AppColors.black : context.divColor),
              ),
              child: Text(
                s == 'male' ? 'Masculino' : s == 'female' ? 'Feminino' : 'Outro',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: form.sex == s ? Colors.white : context.textColor),
                textAlign: TextAlign.center,
              ),
            ),
          )),
      ]),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// PASSO 3 — SAÚDE E HISTÓRICO
// ══════════════════════════════════════════════════════════════

class _Step3Saude extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step3Saude({required this.form, required this.onChanged});

  static const _injuryRegions = [
    'Joelho', 'Ombro', 'Lombar', 'Cervical', 'Quadril',
    'Tornozelo', 'Punho', 'Cotovelo',
  ];

  static const _medConditions = [
    'Hipertensão', 'Diabetes', 'Asma', 'Escoliose',
    'Hérnia de disco', 'Osteoporose', 'Gestante',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    children: [
      _SectionLabel('Lesões ativas ou recentes', context),
      const SizedBox(height: 4),
      Text('Selecione todas as regiões com dor ou lesão.',
        style: TextStyle(fontSize: 11, color: context.textSecColor)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8,
        children: _injuryRegions.map((r) {
          final sel = form.injuries.contains(r);
          return GestureDetector(
            onTap: () {
              final updated = sel
                  ? form.injuries.where((i) => i != r).toList()
                  : [...form.injuries, r];
              onChanged(form.copyWith(injuries: updated));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFFFCEBEB) : context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? const Color(0xFFA32D2D) : context.divColor),
              ),
              child: Text(r, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel
                    ? const Color(0xFFA32D2D) : context.textColor)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      _SectionLabel('Condições médicas relevantes', context),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8,
        children: _medConditions.map((c) {
          final sel = form.medicalConds.contains(c);
          return GestureDetector(
            onTap: () {
              final updated = sel
                  ? form.medicalConds.where((m) => m != c).toList()
                  : [...form.medicalConds, c];
              onChanged(form.copyWith(medicalConds: updated));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFFFAEEDA) : context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? const Color(0xFF854F0B) : context.divColor)),
              child: Text(c, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel
                    ? const Color(0xFF854F0B) : context.textColor)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Problema cardiovascular
      _ToggleCard(
        title: 'Histórico de problema cardiovascular',
        subtitle: 'Infarto, arritmia, sopro, pressão muito alta, etc.',
        value: form.hasCardioIssue,
        onChanged: (v) => onChanged(form.copyWith(hasCardioIssue: v)),
        context: context,
      ),

      if (form.hasCardioIssue) ...[
        const SizedBox(height: 10),
        _ToggleCard(
          title: 'Tenho liberação médica para exercícios',
          subtitle: 'Obrigatório para prosseguir com segurança.',
          value: form.hasDoctorClearance,
          onChanged: (v) => onChanged(form.copyWith(hasDoctorClearance: v)),
          context: context,
          accent: true,
        ),
        if (!form.hasDoctorClearance)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF854F0B).withOpacity(.3))),
              child: const Text(
                '⚠️  Consulte um médico antes de iniciar um programa de treinos. Por sua segurança, precisamos da sua confirmação para continuar.',
                style: TextStyle(fontSize: 12, color: Color(0xFF854F0B), height: 1.5)),
            ),
          ),
      ],
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// PASSO 4 — ESTILO DE TREINO
// ══════════════════════════════════════════════════════════════

class _Step4Estilo extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step4Estilo({required this.form, required this.onChanged});

  static const _envs = {
    'gym':     ('Academia',     '🏋️'),
    'home':    ('Casa',         '🏠'),
    'outdoor': ('Ao ar livre',  '🌳'),
    'mixed':   ('Varia',        '🔄'),
  };

  static const _durations = [30, 45, 60, 75, 90];

  static const _times = {
    'morning':   ('Manhã',   '🌅'),
    'afternoon': ('Tarde',   '☀️'),
    'evening':   ('Noite',   '🌙'),
    'flexible':  ('Flexível','🔄'),
  };

  static const _equipments = [
    'Barra', 'Halter', 'Cabo', 'Máquinas', 'Elástico',
    'Peso corporal', 'Kettlebell', 'TRX',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    children: [
      _SectionLabel('Onde você treina?', context),
      const SizedBox(height: 10),
      Row(children: _envs.entries.map((e) => Expanded(child: GestureDetector(
        onTap: () => onChanged(form.copyWith(environment: e.key)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: e.key == 'mixed' ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: form.environment == e.key
                ? AppColors.black : context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: form.environment == e.key
                  ? AppColors.black : context.divColor)),
          child: Column(children: [
            Text(e.value.$2, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(e.value.$1, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: form.environment == e.key
                  ? Colors.white : context.textColor)),
          ]),
        ),
      ))).toList()),
      const SizedBox(height: 20),

      _SectionLabel('Equipamentos disponíveis', context),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8,
        children: _equipments.map((eq) {
          final sel = form.equipment.contains(eq);
          return GestureDetector(
            onTap: () {
              final updated = sel
                  ? form.equipment.where((e) => e != eq).toList()
                  : [...form.equipment, eq];
              onChanged(form.copyWith(equipment: updated));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.black : context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.black : context.divColor)),
              child: Text(eq, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel ? Colors.white : context.textColor)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      _SectionLabel('Duração ideal da sessão (minutos)', context),
      const SizedBox(height: 10),
      Row(children: _durations.map((d) => Expanded(child: GestureDetector(
        onTap: () => onChanged(form.copyWith(sessionDurationMin: d)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: d == 90 ? 0 : 6),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: form.sessionDurationMin == d
                ? AppColors.black : context.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: form.sessionDurationMin == d
                  ? AppColors.black : context.divColor)),
          child: Text('$d', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: form.sessionDurationMin == d
                ? Colors.white : context.textColor),
            textAlign: TextAlign.center),
        ),
      ))).toList()),
      const SizedBox(height: 20),

      _SectionLabel('Horário preferido para treinar', context),
      const SizedBox(height: 10),
      Row(children: _times.entries.map((e) => Expanded(child: GestureDetector(
        onTap: () => onChanged(form.copyWith(timeOfDay: e.key)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: e.key == 'flexible' ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: form.timeOfDay == e.key
                ? AppColors.black : context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: form.timeOfDay == e.key
                  ? AppColors.black : context.divColor)),
          child: Column(children: [
            Text(e.value.$2, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(e.value.$1, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: form.timeOfDay == e.key
                  ? Colors.white : context.textColor)),
          ]),
        ),
      ))).toList()),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// PASSO 5 — COACH DE IA
// ══════════════════════════════════════════════════════════════

class _Step5Coach extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step5Coach({required this.form, required this.onChanged});

  static const _tones = {
    'motivational': ('Motivador',  '🔥', 'Energia alta, celebra cada conquista'),
    'technical':    ('Técnico',    '📊', 'Focado em forma e dados científicos'),
    'friendly':     ('Amigável',   '😊', 'Leve, encorajador, sem pressão'),
    'strict':       ('Rigoroso',   '💼', 'Direto ao ponto, sem desculpas'),
  };

  static const _presets = ['personal1', 'personal2', 'personal3', 'personal4'];

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController(text: form.coachName);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _SectionLabel('Escolha seu coach', context),
        const SizedBox(height: 10),
        Row(children: _presets.map((p) {
          final sel = form.coachPreset == p;
          final idx = _presets.indexOf(p) + 1;
          return Expanded(child: GestureDetector(
            onTap: () => onChanged(form.copyWith(coachPreset: p)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? AppColors.brandPrimary.withOpacity(.1)
                    : context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppColors.brandPrimary : context.divColor,
                  width: sel ? 2 : 0.5)),
              child: Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.brandPrimary : context.divColor,
                    shape: BoxShape.circle),
                  child: Center(child: Text('$idx',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : context.textSecColor)))),
                const SizedBox(height: 6),
                Text('Personal $idx', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500,
                  color: sel ? AppColors.brandPrimary : context.textColor)),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),

        _SectionLabel('Nome do seu coach', context),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          onChanged: (v) => onChanged(form.copyWith(coachName: v)),
          decoration: const InputDecoration(hintText: 'Ex: Alex, Sam, Jordan…'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),

        _SectionLabel('Tom de comunicação', context),
        const SizedBox(height: 10),
        ..._tones.entries.map((e) => _OptionCard(
          leading: Text(e.value.$2, style: const TextStyle(fontSize: 22)),
          title: e.value.$1,
          subtitle: e.value.$3,
          selected: form.coachTone == e.key,
          onTap: () => onChanged(form.copyWith(coachTone: e.key)),
        )),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PASSO 6 — TERMOS & PRIVACIDADE
// ══════════════════════════════════════════════════════════════

class _Step6Termos extends StatelessWidget {
  final AnamnesisFormData form;
  final ValueChanged<AnamnesisFormData> onChanged;
  const _Step6Termos({required this.form, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    children: [
      // Resumo do que será gerado
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withOpacity(.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandPrimary.withOpacity(.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome_rounded,
              color: AppColors.brandPrimary, size: 18),
            const SizedBox(width: 8),
            Text('Pronto para criar seu programa!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary)),
          ]),
          const SizedBox(height: 8),
          Text(
            'A IA vai gerar um programa de treino personalizado com base em tudo que você informou. Isso leva cerca de 30 segundos.',
            style: TextStyle(fontSize: 12, color: AppColors.brandPrimary,
              height: 1.5)),
        ]),
      ),
      const SizedBox(height: 24),

      _SectionLabel('Consentimentos obrigatórios', context),
      const SizedBox(height: 10),

      _ConsentTile(
        title: 'Aceito os Termos de Uso e a Política de Privacidade',
        url: AppConfig.privacyPolicyUrl,
        value: form.acceptedTerms,
        onChanged: (v) => onChanged(form.copyWith(acceptedTerms: v)),
        required: true,
        context: context,
      ),
      const SizedBox(height: 8),
      _ConsentTile(
        title: 'Autorizo o uso dos meus dados de saúde para personalizar o treino',
        url: AppConfig.privacyPolicyUrl,
        value: form.acceptedHealth,
        onChanged: (v) => onChanged(form.copyWith(acceptedHealth: v)),
        required: true,
        context: context,
      ),
      const SizedBox(height: 16),

      _SectionLabel('Opcional', context),
      const SizedBox(height: 10),
      _ConsentTile(
        title: 'Aceito receber dicas e novidades por e-mail',
        value: form.acceptedMarketing,
        onChanged: (v) => onChanged(form.copyWith(acceptedMarketing: v)),
        required: false,
        context: context,
      ),
      const SizedBox(height: 20),

      // Aviso de saúde
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.divColor)),
        child: Text(
          '⚠️  O ${AppConfig.appName} não substitui um profissional de saúde. Consulte um médico antes de iniciar qualquer programa de exercícios, especialmente se tiver condições médicas preexistentes.',
          style: TextStyle(fontSize: 11, color: context.textSecColor, height: 1.5)),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
// COMPONENTES REUTILIZÁVEIS
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  final BuildContext ctx;
  const _SectionLabel(this.text, this.ctx);
  @override
  Widget build(BuildContext context) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
      color: ctx.textColor));
}

class _OptionCard extends StatelessWidget {
  final Widget? leading;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard({
    this.leading, required this.title, required this.subtitle,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.brandPrimary.withOpacity(.06) : context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.brandPrimary : context.divColor,
          width: selected ? 2 : 0.5)),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: selected ? AppColors.brandPrimary : context.textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              fontSize: 12, color: selected
                  ? AppColors.brandPrimary.withOpacity(.7)
                  : context.textSecColor)),
          ],
        )),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.brandPrimary : context.divColor,
              width: selected ? 2 : 1.5),
            color: selected ? AppColors.brandPrimary : Colors.transparent),
          child: selected
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      ]),
    ),
  );
}

class _NumericField extends StatelessWidget {
  final String label;
  final double value, min, max, step;
  final ValueChanged<double> onChanged;
  final bool wide;
  const _NumericField({
    required this.label, required this.value,
    required this.min, required this.max, required this.step,
    required this.onChanged, this.wide = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: context.textSecColor)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: () { if (value > min) onChanged(value - step); },
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: context.bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.remove_rounded, size: 16, color: context.textColor)),
        ),
        Text(value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(1),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
            color: context.textColor)),
        GestureDetector(
          onTap: () { if (value < max) onChanged(value + step); },
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.black, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded, size: 16, color: Colors.white)),
        ),
      ]),
    ]),
  );
}

class _ToggleCard extends StatelessWidget {
  final String title, subtitle;
  final bool value, accent;
  final ValueChanged<bool> onChanged;
  final BuildContext context;
  const _ToggleCard({
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
    required this.context, this.accent = false,
  });
  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent && value
          ? AppColors.brandPrimary : context.divColor,
        width: accent && value ? 2 : 0.5)),
    child: SwitchListTile.adaptive(
      title: Text(title, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: context.textColor)),
      subtitle: Text(subtitle, style: TextStyle(
        fontSize: 11, color: context.textSecColor)),
      value: value, onChanged: onChanged,
      activeColor: AppColors.brandPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    ),
  );
}

class _ConsentTile extends StatelessWidget {
  final String title;
  final String? url;
  final bool value, required;
  final ValueChanged<bool> onChanged;
  final BuildContext context;
  const _ConsentTile({
    required this.title, this.url,
    required this.value, required this.onChanged,
    required this.required, required this.context,
  });
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value
            ? AppColors.brandPrimary.withOpacity(.05) : context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.brandPrimary : context.divColor,
          width: value ? 1.5 : 0.5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22, height: 22, margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: value ? AppColors.brandPrimary : Colors.transparent,
            border: Border.all(
              color: value ? AppColors.brandPrimary : context.divColor,
              width: 1.5)),
          child: value
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12,
              color: context.textColor, height: 1.4)),
            if (required)
              const Text('Obrigatório', style: TextStyle(
                fontSize: 10, color: Color(0xFFA32D2D),
                fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    ),
  );
}
