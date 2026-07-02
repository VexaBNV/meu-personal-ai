import {
  Controller, Get, Post, Body, Req,
  UseGuards, BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlansService } from './plans.service';
import { ConfigService } from '@nestjs/config';

@Controller('plans')
@UseGuards(JwtAuthGuard)
export class PlansController {
  constructor(
    private readonly plans: PlansService,
    private readonly config: ConfigService,
  ) {}

  /** GET /plans/status — status do plano do usuário logado */
  @Get('status')
  status(@Req() req: any) {
    return this.plans.getPlanStatus(req.user.sub);
  }

  /** POST /plans/trial — inicia os 7 dias grátis do Pro */
  @Post('trial')
  async startTrial(@Req() req: any) {
    try {
      await this.plans.startTrial(req.user.sub);
      return { success: true };
    } catch (e: any) {
      throw new BadRequestException(e.message);
    }
  }

  /** POST /plans/portal — retorna URL do portal Stripe */
  @Post('portal')
  async portal(@Req() req: any, @Body() body: { returnUrl?: string }) {
    const url = await this.plans.getCustomerPortalUrl(
      req.user.sub,
      body.returnUrl ?? this.config.get('APP_DEEP_LINK_BASE', 'meupersonalai://profile'),
    );
    return { url };
  }
}
