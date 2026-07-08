import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { WorkoutProgram } from './workout-program.entity';
import { WorkoutSession } from './workout-session.entity';
import { SessionLog } from './session-log.entity';
import { CompletedSession } from './completed-session.entity';

@Injectable()
export class WorkoutRepository {
  constructor(
    @InjectRepository(WorkoutProgram)
    private readonly programs: Repository<WorkoutProgram>,
    @InjectRepository(WorkoutSession)
    private readonly sessions: Repository<WorkoutSession>,
    @InjectRepository(SessionLog)
    private readonly logs: Repository<SessionLog>,
    @InjectRepository(CompletedSession)
    private readonly completed: Repository<CompletedSession>,
    private readonly dataSource: DataSource,
  ) {}

  async getActiveProgram(userId: string): Promise<WorkoutProgram | null> {
    return this.programs.findOne({
      where: { userId, isActive: true },
      relations: ['sessions', 'sessions.exercises', 'sessions.exercises.exercise'],
      order: { createdAt: 'DESC' },
    });
  }

  async createProgram(data: Partial<WorkoutProgram>): Promise<WorkoutProgram> {
    await this.programs.update({ userId: data.userId, isActive: true }, { isActive: false });
    return this.programs.save(this.programs.create(data));
  }

  async getProgramStatus(userId: string): Promise<{ status: 'generating' | 'ready' | 'none' }> {
    const program = await this.programs.findOne({
      where: { userId, isActive: true },
      select: ['id', 'generatedAt'],
    });
    if (!program) return { status: 'none' };
    if (!program.generatedAt) return { status: 'generating' };
    return { status: 'ready' };
  }

  async getTodaySession(userId: string): Promise<WorkoutSession | null> {
    const dayOfWeek = new Date().getDay() || 7;
    const program   = await this.getActiveProgram(userId);
    if (!program) return null;
    return program.sessions.find(s => s.dayOfWeek === dayOfWeek) ?? program.sessions[0] ?? null;
  }

  async saveLog(data: Partial<SessionLog>): Promise<SessionLog> {
    return this.logs.save(this.logs.create(data));
  }

  async completeSession(data: Partial<CompletedSession>): Promise<CompletedSession> {
    return this.completed.save(this.completed.create(data));
  }

  async getCompletedSession(id: string): Promise<CompletedSession | null> {
    return this.completed.findOne({ where: { id } });
  }

  async saveFeedback(sessionId: string, feedback: string): Promise<void> {
    await this.completed.update(sessionId, {
      aiFeedback: feedback,
      feedbackGeneratedAt: new Date(),
    });
  }

  async getUserProfile(userId: string) {
    const row = await this.dataSource.query(
      `SELECT level, injuries, medical_conditions, environment, equipment,
              session_duration_min, weekly_frequency, coach_name, coach_tone
       FROM user_profiles WHERE user_id = $1 LIMIT 1`,
      [userId],
    );
    return row[0] ?? {};
  }

  async getRecentMusclesWorked(userId: string, days: number): Promise<string[]> {
    const since = new Date();
    since.setDate(since.getDate() - days);
    const rows = await this.dataSource.query(
      `SELECT DISTINCT e.muscle_group
       FROM session_logs sl
       JOIN exercises e ON e.id = sl.exercise_id
       WHERE sl.user_id = $1 AND sl.logged_at >= $2`,
      [userId, since],
    );
    return rows.map((r: any) => r.muscle_group);
  }

  async logExpressWorkoutGenerated(userId: string, dto: Record<string, any>): Promise<void> {
    await this.dataSource.query(
      `INSERT INTO analytics_events (user_id, event, properties)
       VALUES ($1, 'express_workout_generated', $2)`,
      [userId, JSON.stringify(dto)],
    );
  }
}
