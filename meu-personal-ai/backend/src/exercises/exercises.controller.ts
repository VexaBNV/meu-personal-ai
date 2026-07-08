import {
  Controller, Get, Param, Query,
  UseGuards, NotFoundException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { Exercise } from './exercise.entity';

interface ExerciseQueryDto {
  muscle?:     string;
  difficulty?: string;
  equipment?:  string;
  q?:          string;
  limit?:      number;
  offset?:     number;
}

@Controller('exercises')
@UseGuards(JwtAuthGuard)
export class ExercisesController {
  constructor(
    @InjectRepository(Exercise)
    private readonly repo: Repository<Exercise>,
  ) {}

  @Get()
  async findAll(@Query() q: ExerciseQueryDto) {
    const where: any = {};
    if (q.muscle)     where.muscleGroup = q.muscle;
    if (q.difficulty) where.difficulty  = q.difficulty;
    if (q.q)          where.name        = ILike(`%${q.q}%`);

    const exercises = await this.repo.find({
      where,
      order: { name: 'ASC' },
      take:  q.limit  ? Number(q.limit)  : undefined,
      skip:  q.offset ? Number(q.offset) : undefined,
    });

    if (q.equipment) {
      const equip = q.equipment.split(',').map(e => e.trim());
      return exercises.filter(ex =>
        equip.some(e => ex.equipment?.includes(e)),
      );
    }

    return exercises;
  }

  @Get('meta/muscle-groups')
  async getMuscleGroups() {
    const raw = await this.repo
      .createQueryBuilder('e')
      .select('DISTINCT e.muscleGroup', 'muscleGroup')
      .orderBy('e.muscleGroup', 'ASC')
      .getRawMany();
    return raw.map(r => r.muscleGroup);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const exercise = await this.repo.findOne({ where: { id } });
    if (!exercise) throw new NotFoundException(`Exercise ${id} not found`);
    return exercise;
  }

  @Get(':id/substitutes')
  async getSubstitutes(@Param('id') id: string) {
    const exercise = await this.repo.findOne({ where: { id } });
    if (!exercise) throw new NotFoundException();

    // Fallback: substitutos pelo mesmo grupo muscular
    const substitutes = await this.repo.find({
      where: { muscleGroup: exercise.muscleGroup },
      take: 6,
      order: { name: 'ASC' },
    });

    return substitutes.filter(e => e.id !== id);
  }
}
