// ═══════════════════════════════════════════════════════════
// BACKEND — src/workout/express-workout.controller.ts
// ═══════════════════════════════════════════════════════════

import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { LlmService } from '../llm/llm.service';
import { WorkoutRepository } from './workout.repository';
import { PlanGuard, RequireFeature } from '../plans/plan.guard';

interface ExpressWorkoutDto {
  durationMinutes: 15 | 20 | 30;
  environment: 'gym' | 'home' | 'outdoor';
  availableEquipment: string[];
  focus?: string; // ex: 'pernas', 'superior', 'full_body'
  intensity?: 'low' | 'medium' | 'high';
}

@Controller('workout')
@UseGuards(JwtAuthGuard, PlanGuard)
export class ExpressWorkoutController {
  constructor(
    private readonly llm: LlmService,
    private readonly workoutRepo: WorkoutRepository,
  ) {}

  @Post('express')
  @RequireFeature('express_workout')
  async generate(@Req() req: any, @Body() dto: ExpressWorkoutDto) {
    const userId = req.user.sub;

    // Busca contexto do usuário (lesões, nível)
    const profile = await this.workoutRepo.getUserProfile(userId);
    const recentMuscles = await this.workoutRepo.getRecentMusclesWorked(userId, 3);

    const prompt = `Gere um treino express de ${dto.durationMinutes} minutos.

PERFIL:
- Nível: ${profile.level}
- Lesões ativas: ${profile.injuries?.join(', ') || 'nenhuma'}
- Grupos trabalhados recentemente (evitar): ${recentMuscles.join(', ')}
- Ambiente: ${dto.environment}
- Equipamentos disponíveis: ${dto.availableEquipment.join(', ')}
- Foco solicitado: ${dto.focus || 'balanceado'}
- Intensidade: ${dto.intensity || 'medium'}

REGRAS:
1. Máximo ${dto.durationMinutes} minutos com aquecimento e volta à calma
2. Evitar grupos musculares trabalhados nos últimos 3 dias
3. Adaptar 100% aos equipamentos disponíveis
4. Se houver lesões, excluir exercícios que as agravem
5. Inclua tempo de descanso entre séries

Responda APENAS em JSON válido sem markdown:
{
  "name": "nome do treino",
  "totalMinutes": ${dto.durationMinutes},
  "focus": "grupo muscular principal",
  "intensity": "low|medium|high",
  "coachNote": "mensagem motivacional curta do coach",
  "exercises": [
    {
      "exerciseId": "id do exercício do banco ou nome se não encontrar",
      "name": "nome do exercício",
      "sets": 3,
      "reps": "10-12 ou 30s",
      "restSeconds": 45,
      "technique": "dica rápida de execução"
    }
  ]
}`;

    const result = await this.llm.completeJSON<ExpressWorkoutResult>(prompt, {
      maxTokens: 1000,
      system: 'Você é um personal trainer especialista em treinos curtos e eficientes.',
    });

    // Log para analytics
    await this.workoutRepo.logExpressWorkoutGenerated(userId, dto);

    return result;
  }
}

interface ExpressWorkoutResult {
  name: string;
  totalMinutes: number;
  focus: string;
  intensity: string;
  coachNote: string;
  exercises: Array<{
    exerciseId: string;
    name: string;
    sets: number;
    reps: string;
    restSeconds: number;
    technique: string;
  }>;
}
