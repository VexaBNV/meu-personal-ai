import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('session_logs')
export class SessionLog {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'session_id', nullable: true }) sessionId?: string;
  @Column({ name: 'exercise_id' }) exerciseId: string;
  @Column({ name: 'set_number' }) setNumber: number;
  @Column({ name: 'load_kg', type: 'numeric', nullable: true }) loadKg?: number;
  @Column({ name: 'reps_done', nullable: true }) repsDone?: number;
  @Column({ name: 'rpe_actual', type: 'numeric', nullable: true }) rpeActual?: number;
  @Column({ default: 'success' }) outcome: string;
  @Column({ name: 'pain_reported', default: false }) painReported: boolean;
  @Column({ name: 'pain_region', nullable: true }) painRegion?: string;
  @Column({ nullable: true }) notes?: string;
  @CreateDateColumn({ name: 'logged_at' }) loggedAt: Date;
}
