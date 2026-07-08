import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExpressWorkoutController } from './express-workout.controller';
import { WorkoutRepository } from './workout.repository';
import { WorkoutProgram } from './workout-program.entity';
import { WorkoutSession } from './workout-session.entity';
import { SessionExercise } from './session-exercise.entity';
import { SessionLog } from './session-log.entity';
import { CompletedSession } from './completed-session.entity';
import { LlmModule } from '../llm/llm.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      WorkoutProgram, WorkoutSession, SessionExercise, SessionLog, CompletedSession,
    ]),
    LlmModule,
  ],
  controllers: [ExpressWorkoutController],
  providers: [WorkoutRepository],
  exports: [WorkoutRepository],
})
export class WorkoutModule {}
