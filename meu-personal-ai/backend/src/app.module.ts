import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { RedisModule } from '@nestjs-modules/ioredis';
import * as admin from 'firebase-admin';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { WorkoutModule } from './workout/workout.module';
import { ExercisesModule } from './exercises/exercises.module';
import { PlansModule } from './plans/plans.module';
import { PaymentsModule } from './payments/payments.module';
import { ProgressModule } from './progress/progress.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { LgpdModule } from './lgpd/lgpd.module';
import { LlmModule } from './llm/llm.module';
import { HealthModule } from './health/health.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    // Configuração global
    ConfigModule.forRoot({ isGlobal: true }),

    // Banco de dados
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        type: 'postgres',
        url: cfg.get('DATABASE_URL'),
        autoLoadEntities: true,
        synchronize: false, // NUNCA true em produção — usar migrations
        ssl: cfg.get('NODE_ENV') === 'production'
          ? { rejectUnauthorized: false }
          : false,
      }),
    }),

    // Filas (Bull + Redis)
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        redis: cfg.get('REDIS_URL'),
      }),
    }),

    // Cliente Redis (usado via @InjectRedis(), ex.: AppController health check)
    RedisModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        type: 'single' as const,
        url: cfg.get<string>('REDIS_URL'),
      }),
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    WorkoutModule,
    ExercisesModule,
    PlansModule,
    PaymentsModule,
    ProgressModule,
    NotificationsModule,
    AnalyticsModule,
    LgpdModule,
    LlmModule,
    HealthModule,
  ],
  controllers: [AppController],
})
export class AppModule {
  constructor(private cfg: ConfigService) {
    // Inicializa Firebase Admin
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId:    cfg.get('FIREBASE_PROJECT_ID'),
          clientEmail:  cfg.get('FIREBASE_CLIENT_EMAIL'),
          privateKey:   cfg.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
        }),
      });
    }
  }
}
