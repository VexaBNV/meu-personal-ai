import { Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlansService } from './plans.service';

@Controller('plans')
@UseGuards(JwtAuthGuard)
export class PlansController {
  constructor(
    private readonly plans: PlansService,
  ) {}

  @Get('status')
  getStatus(@Req() req: any) {
    return this.plans.getStatus(req.user.userId);
  }

  @Post('trial')
  startTrial(@Req() req: any) {
    return this.plans.startTrial(req.user.userId);
  }

  @Post('portal')
  async getPortalUrl(@Req() req: any) {
    const url = await this.plans.getCustomerPortalUrl(req.user.userId);
    return { url };
  }
}
