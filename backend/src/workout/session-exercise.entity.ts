import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { WorkoutSession } from './workout-session.entity';
import { Exercise } from '../exercises/exercise.entity';

@Entity('session_exercises')
export class SessionExercise {
  @PrimaryGeneratedColumn('uuid') id: string;
  @ManyToOne(() => WorkoutSession, s => s.exercises, { onDelete: 'CASCADE' })
  session: WorkoutSession;
  @ManyToOne(() => Exercise) exercise: Exercise;
  @Column({ default: 3 }) sets: number;
  @Column({ name: 'reps_min', default: 8 }) repsMin: number;
  @Column({ name: 'reps_max', default: 12 }) repsMax: number;
  @Column({ name: 'load_kg', type: 'numeric', nullable: true }) loadKg?: number;
  @Column({ name: 'rest_seconds', default: 90 }) restSeconds: number;
  @Column({ name: 'rpe_target', type: 'numeric', nullable: true }) rpeTarget?: number;
  @Column({ nullable: true }) notes?: string;
  @Column({ name: 'sort_order', default: 0 }) sortOrder: number;
}
