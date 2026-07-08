import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'firebase_uid', unique: true }) firebaseUid: string;
  @Column({ unique: true }) email: string;
  @Column() name: string;
  @Column({ name: 'avatar_url', nullable: true }) avatarUrl?: string;

  // Plano — usado como planId internamente
  @Column({ default: 'free' }) plan: string;
  get planId() { return this.plan; }
  set planId(v: string) { this.plan = v; }

  // Stripe
  @Column({ name: 'stripe_customer_id', nullable: true }) stripeCustomerId?: string;
  @Column({ name: 'subscription_status', nullable: true }) subscriptionStatus?: string;
  @Column({ name: 'subscription_period_end', nullable: true }) subscriptionPeriodEnd?: Date;

  // Trial
  @Column({ name: 'had_trial', default: false }) hadTrial: boolean;
  @Column({ name: 'trial_ends_at', nullable: true }) trialEndsAt?: Date;

  // RevenueCat
  @Column({ name: 'revenuecat_app_user_id', nullable: true }) revenuecatAppUserId?: string;

  @Column({ name: 'anamnesis_completed', default: false }) anamnesisCompleted: boolean;
  @Column({ name: 'deleted_at', nullable: true }) deletedAt?: Date;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
