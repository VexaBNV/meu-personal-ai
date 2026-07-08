import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { UserProfile } from './user-profile.entity';
import { NotificationSettings } from '../notifications/notification-settings.entity';

@Injectable()
export class UsersService {

  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
    @InjectRepository(UserProfile) private readonly profiles: Repository<UserProfile>,
    @InjectRepository(NotificationSettings) private readonly notifs: Repository<NotificationSettings>,
  ) {}

  async getProfile(userId: string) {
    const user    = await this.users.findOne({ where: { id: userId } });
    const profile = await this.profiles.findOne({ where: { userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return { ...user, profile };
  }

  async saveAnamnesis(userId: string, dto: any) {
    let profile = await this.profiles.findOne({ where: { userId } });

    if (!profile) {
      profile = this.profiles.create({ userId });
    }

    Object.assign(profile, {
      primaryGoal:        dto.goal,
      level:              dto.level,
      weeklyFrequency:    dto.weeklyFrequency,
      weightKg:           dto.weight,
      heightCm:           dto.height,
      age:                dto.age,
      sex:                dto.sex,
      injuries:           dto.injuries ?? [],
      medicalConditions:  dto.medicalConditions ?? [],
      hasCardioIssue:     dto.hasCardiovascularIssue ?? false,
      hasDoctorClearance: dto.hasDoctorClearance ?? false,
      environment:        dto.environment,
      equipment:          dto.equipment ?? [],
      sessionDurationMin: dto.sessionDurationMinutes,
      timeOfDay:          dto.timeOfDay,
      coachTone:          dto.coachTone,
      coachPreset:        dto.coachPreset,
      coachName:          dto.coachName,
      acceptedTerms:      dto.acceptedTerms,
      acceptedHealthData: dto.acceptedHealthDataUsage,
      acceptedMarketing:  dto.acceptedMarketing ?? false,
      termsAcceptedAt:    new Date(),
    });

    await this.profiles.save(profile);
    await this.users.update(userId, { anamnesisCompleted: true });

    return { ok: true };
  }

  async updateUser(userId: string, dto: any) {
    await this.users.update(userId, {
      name: dto.name,
      ...(dto.avatarUrl && { avatarUrl: dto.avatarUrl }),
    });
    return this.getProfile(userId);
  }

  async updateAvatar(userId: string, file: Express.Multer.File) {
    // Upload para R2 implementado no R2Service — aqui apenas retorna placeholder
    // Em produção: injetar R2Service e fazer upload
    const avatarUrl = `/placeholder/avatar/${userId}.jpg`;
    await this.users.update(userId, { avatarUrl });
    return { avatarUrl };
  }

  async getNotifSettings(userId: string) {
    let settings = await this.notifs.findOne({ where: { userId } });
    if (!settings) {
      settings = this.notifs.create({ userId });
      await this.notifs.save(settings);
    }
    return settings;
  }

  async updateNotifSettings(userId: string, dto: any) {
    await this.notifs.upsert({ userId, ...dto }, ['userId']);
    return this.getNotifSettings(userId);
  }
}
