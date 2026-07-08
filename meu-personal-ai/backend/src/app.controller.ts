import { Controller, Get } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';

@Controller()
export class AppController {

  constructor(
    @InjectDataSource() private readonly db: DataSource,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  @Get('health')
  health() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  @Get('health/db')
  async healthDb() {
    try {
      await this.db.query('SELECT 1');
      return { status: 'ok', database: 'connected' };
    } catch (e) {
      return { status: 'error', database: e.message };
    }
  }

  @Get('health/redis')
  async healthRedis() {
    try {
      await this.redis.ping();
      return { status: 'ok', redis: 'connected' };
    } catch (e) {
      return { status: 'error', redis: e.message };
    }
  }
}
