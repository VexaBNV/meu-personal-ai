// users.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User } from './user.entity';
import { UserProfile } from './user-profile.entity';
import { NotificationSettings } from '../notifications/notification-settings.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserProfile, NotificationSettings])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
