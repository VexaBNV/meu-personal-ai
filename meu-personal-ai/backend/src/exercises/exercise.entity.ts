// src/exercises/exercise.entity.ts
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('exercises')
export class Exercise {
  @PrimaryGeneratedColumn('uuid') id: string;

  @Column() name: string;
  @Column({ name: 'muscle_group' }) muscleGroup: string;
  @Column('text', { name: 'primary_muscles', array: true, default: '{}' }) primaryMuscles: string[];
  @Column({ name: 'stimulus_type', default: 'compound' }) stimulusType: string;
  @Column('text', { array: true, default: '{}' }) equipment: string[];
  @Column({ default: 'intermediate' }) difficulty: string;
  @Column('text', { array: true, default: '{}' }) instructions: string[];
  @Column('text', { name: 'coaching_cues', array: true, default: '{}' }) coachingCues: string[];
  @Column('text', { name: 'common_errors', array: true, default: '{}' }) commonErrors: string[];
  @Column({ name: 'video_url', nullable: true }) videoUrl?: string;
  @Column({ name: 'image_url', nullable: true }) imageUrl?: string;
  @Column({ name: 'is_active', default: true }) isActive: boolean;

  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
