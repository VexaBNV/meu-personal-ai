import { Controller, Post, Body, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlanGuard, RequireFeature } from '../plans/plan.guard';
import { LlmService } from '../llm/llm.service';
import { WorkoutRepository } from './workout.repository';

interface ExpressWorkoutDto {
  durationMinutes: number;
  muscleGroup?:    string;
  equipment?:      string[];
}

interface ExpressWorkoutResult {
  name:      string;
  exercises: {
    name:        string;
    sets:        number;
    reps:        string;
    restSeconds: number;
    notes?:      string;
  }[];
}

@Controller('workout')
@UseGuards(JwtAuthGuard, PlanGuard)
export class ExpressWorkoutController {
  constructor(
    private readonly llm:         LlmService,
    private readonly workoutRepo: WorkoutRepository,
  ) {}

  @Post('express')
  @RequireFeature('expressWorkout')
  async generateExpress(@Req() req: any, @Body() dto: ExpressWorkoutDto) {
    const userId  = req.user.userId;
    const profile = await this.workoutRepo.getUserProfile(userId);
    const recent  = await this.workoutRepo.getRecentMusclesWorked(userId, 3);

    const prompt = `
Gere um treino express de ${dto.durationMinutes} minutos.
Perfil: nível ${profile.level ?? 'iniciante'}, ambiente ${profile.environment ?? 'academia'}.
Equipamentos: ${dto.equipment?.join(', ') || profile.equipment?.join(', ') || 'peso corporal'}.
Grupo muscular foco: ${dto.muscleGroup ?? 'corpo todo'}.
Músculos trabalhados recentemente (evitar): ${recent.join(', ') || 'nenhum'}.

Retorne JSON com: { "name": string, "exercises": [{ "name": string, "sets": number, "reps": string, "restSeconds": number, "notes": string }] }
`;

    const result = await this.llm.completeJSON<ExpressWorkoutResult>(prompt, {
      maxTokens: 1000,
      system: 'Você é um personal trainer especialista em treinos curtos e eficientes.',
    });

    await this.workoutRepo.logExpressWorkoutGenerated(userId, dto);

    return result;
  }
}
