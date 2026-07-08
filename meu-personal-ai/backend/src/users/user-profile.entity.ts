import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_profiles')
export class UserProfile {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'primary_goal', default: 'hypertrophy' }) primaryGoal: string;
  @Column({ default: 'beginner' }) level: string;
  @Column({ name: 'weekly_frequency', default: 3 }) weeklyFrequency: number;
  @Column({ name: 'weight_kg', type: 'numeric', nullable: true }) weightKg?: number;
  @Column({ name: 'height_cm', type: 'numeric', nullable: true }) heightCm?: number;
  @Column({ nullable: true }) age?: number;
  @Column({ nullable: true }) sex?: string;
  @Column('text', { array: true, default: '{}' }) injuries: string[];
  @Column('text', { name: 'medical_conditions', array: true, default: '{}' }) medicalConditions: string[];
  @Column({ name: 'has_cardio_issue', default: false }) hasCardioIssue: boolean;
  @Column({ name: 'has_doctor_clearance', default: false }) hasDoctorClearance: boolean;
  @Column({ default: 'gym' }) environment: string;
  @Column('text', { array: true, default: '{}' }) equipment: string[];
  @Column({ name: 'session_duration_min', default: 60 }) sessionDurationMin: number;
  @Column({ name: 'time_of_day', default: 'flexible' }) timeOfDay: string;
  @Column({ name: 'coach_tone', default: 'motivational' }) coachTone: string;
  @Column({ name: 'coach_preset', default: 'personal1' }) coachPreset: string;
  @Column({ name: 'coach_name', default: 'Alex' }) coachName: string;
  @Column({ name: 'accepted_terms', default: false }) acceptedTerms: boolean;
  @Column({ name: 'accepted_health_data', default: false }) acceptedHealthData: boolean;
  @Column({ name: 'accepted_marketing', default: false }) acceptedMarketing: boolean;
  @Column({ name: 'terms_accepted_at', nullable: true }) termsAcceptedAt?: Date;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
