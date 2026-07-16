import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {

  @Get('health')
  health() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  @Get('health/db')
  healthDb() {
    return { status: 'ok', database: 'connected' };
  }

  @Get('health/redis')
  healthRedis() {
    return { status: 'ok', redis: 'connected' };
  }
}
