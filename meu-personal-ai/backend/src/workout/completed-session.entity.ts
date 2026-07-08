import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('completed_sessions')
export class CompletedSession {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'session_id', nullable: true }) sessionId?: string;
  @Column({ name: 'started_at' }) startedAt: Date;
  @Column({ name: 'finished_at', nullable: true }) finishedAt?: Date;
  @Column({ name: 'duration_seconds', nullable: true }) durationSeconds?: number;
  @Column({ name: 'exercises_done', default: 0 }) exercisesDone: number;
  @Column({ name: 'sets_done', default: 0 }) setsDone: number;
  @Column({ name: 'ai_feedback', nullable: true }) aiFeedback?: string;
  @Column({ name: 'feedback_generated_at', nullable: true }) feedbackGeneratedAt?: Date;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
