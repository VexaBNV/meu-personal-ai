import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, CreateDateColumn } from 'typeorm';
import { WorkoutProgram } from './workout-program.entity';
import { SessionExercise } from './session-exercise.entity';

@Entity('workout_sessions')
export class WorkoutSession {
  @PrimaryGeneratedColumn('uuid') id: string;
  @ManyToOne(() => WorkoutProgram, p => p.sessions, { onDelete: 'CASCADE' })
  program: WorkoutProgram;
  @Column() name: string;
  @Column({ nullable: true }) focus?: string;
  @Column({ name: 'day_of_week', nullable: true }) dayOfWeek?: number;
  @Column({ name: 'estimated_duration', nullable: true }) estimatedDuration?: number;
  @Column({ name: 'sort_order', default: 0 }) sortOrder: number;
  @OneToMany(() => SessionExercise, e => e.session, { cascade: true })
  exercises: SessionExercise[];
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
