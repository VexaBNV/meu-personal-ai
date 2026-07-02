import {
  Controller, Get, Param, Query,
  UseGuards, NotFoundException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike, In } from 'typeorm';
import { Exercise } from './exercise.entity';

interface ExerciseQueryDto {
  muscle?:     string;
  difficulty?: string;
  type?:       string;
  equipment?:  string;
  q?:          string; // busca por nome
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

  /** GET /exercises — lista com filtros opcionais */
  @Get()
  async findAll(@Query() q: ExerciseQueryDto) {
    const where: any = {};

    if (q.muscle)     where.muscleGroup = q.muscle;
    if (q.difficulty) where.difficulty  = q.difficulty;
    if (q.type)       where.type        = q.type;
    if (q.q)          where.name        = ILike(`%${q.q}%`);

    const [exercises, total] = await this.repo.findAndCount({
      where,
      order: { name: 'ASC' },
      take:  q.limit  ? Number(q.limit)  : undefined,
      skip:  q.offset ? Number(q.offset) : undefined,
    });

    // Filtra por equipamento (array contains) se passado
    if (q.equipment) {
      const equip = q.equipment.split(',').map(e => e.trim());
      return exercises.filter(ex =>
        equip.some(e => ex.equipment?.includes(e)),
      );
    }

    return exercises;
  }

  /** GET /exercises/:id — detalhe com substitutos */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const exercise = await this.repo.findOne({
      where: { id },
      relations: ['substitutions'],
    });
    if (!exercise) throw new NotFoundException(`Exercise ${id} not found`);
    return exercise;
  }

  /** GET /exercises/:id/substitutes — substitutos com score */
  @Get(':id/substitutes')
  async getSubstitutes(@Param('id') id: string) {
    const exercise = await this.repo.findOne({
      where: { id },
      relations: ['substitutions'],
    });
    if (!exercise) throw new NotFoundException();

    // Se não há substitutos cadastrados, usa fallback por grupo muscular
    if (!exercise.substitutions?.length) {
      return this.repo.find({
        where: {
          muscleGroup: exercise.muscleGroup,
          type:        exercise.type,
        },
        take: 5,
        order: { name: 'ASC' },
      }).then(list => list.filter(e => e.id !== id));
    }

    return exercise.substitutions;
  }

  /** GET /exercises/muscle-groups — grupos únicos para o filtro */
  @Get('meta/muscle-groups')
  async getMuscleGroups() {
    const raw = await this.repo
      .createQueryBuilder('e')
      .select('DISTINCT e.muscleGroup', 'muscleGroup')
      .orderBy('e.muscleGroup', 'ASC')
      .getRawMany();
    return raw.map(r => r.muscleGroup);
  }
}
