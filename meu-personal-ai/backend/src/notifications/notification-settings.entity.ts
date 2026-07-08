// notifications/notification-settings.entity.ts
import { Entity, PrimaryColumn, Column, UpdateDateColumn } from 'typeorm';

@Entity('notification_settings')
export class NotificationSettings {
  @PrimaryColumn({ name: 'user_id' }) userId: string;
  @Column({ name: 'daily_reminder', default: true }) dailyReminder: boolean;
  @Column({ name: 'daily_reminder_time', type: 'time', default: '07:00' }) dailyReminderTime: string;
  @Column({ name: 'streak_alerts', default: true }) streakAlerts: boolean;
  @Column({ name: 'weekly_report', default: true }) weeklyReport: boolean;
  @Column({ name: 'workout_complete', default: true }) workoutComplete: boolean;
  @Column({ default: false }) marketing: boolean;
  @Column({ name: 'fcm_token', nullable: true }) fcmToken?: string;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
