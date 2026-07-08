import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { WorkoutSession } from './workout-session.entity';

@Entity('workout_programs')
export class WorkoutProgram {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column() name: string;
  @Column({ name: 'weekly_frequency' }) weeklyFrequency: number;
  @Column({ name: 'is_active', default: true }) isActive: boolean;
  @Column({ name: 'ai_prompt_used', nullable: true }) aiPromptUsed?: string;
  @Column({ name: 'generated_at', nullable: true }) generatedAt?: Date;
  @OneToMany(() => WorkoutSession, s => s.program, { cascade: true })
  sessions: WorkoutSession[];
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
