import {
  Controller, Post, Headers, RawBodyRequest,
  Req, HttpCode, BadRequestException, Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { PlansService } from '../plans/plans.service';

@Controller('webhooks')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);
  private readonly stripe: Stripe;
  private readonly webhookSecret: string;

  constructor(
    private readonly plans: PlansService,
    config: ConfigService,
  ) {
    this.stripe = new Stripe(config.getOrThrow('STRIPE_SECRET_KEY'));
    this.webhookSecret = config.getOrThrow('STRIPE_WEBHOOK_SECRET');
  }

  @Post('stripe')
  @HttpCode(200)
  async stripeWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') sig: string,
  ) {
    let event: Stripe.Event;
    try {
      event = this.stripe.webhooks.constructEvent(req.rawBody!, sig, this.webhookSecret);
    } catch {
      throw new BadRequestException('Invalid Stripe signature');
    }

    this.logger.log(`Stripe event: ${event.type}`);

    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        await this._handleSubscriptionChange(sub);
        break;
      }
      case 'customer.subscription.deleted': {
        const sub = event.data.object as Stripe.Subscription;
        const userId = sub.metadata?.userId;
        if (userId) await this.plans.setPlan(userId, 'free');
        break;
      }
    }

    return { received: true };
  }

  private async _handleSubscriptionChange(sub: Stripe.Subscription) {
    const userId  = sub.metadata?.userId;
    const priceId = sub.items.data[0]?.price?.id ?? '';

    const elitePrices = (process.env.STRIPE_PRICE_ELITE_MONTHLY ?? '').split(',');
    const proPrices   = (process.env.STRIPE_PRICE_PRO_MONTHLY   ?? '').split(',');

    let plan = 'free';
    if (elitePrices.includes(priceId))      plan = 'elite';
    else if (proPrices.includes(priceId))   plan = 'pro';

    if (userId) {
      await this.plans.setPlan(userId, plan, {
        status:    sub.status,
        periodEnd: new Date((sub as any).current_period_end * 1000),
      });
    }
  }

  @Post('revenuecat')
  @HttpCode(200)
  async revenuecatWebhook(
    @Req() req: any,
    @Headers('x-revenuecat-webhook-secret') secret: string,
  ) {
    if (secret !== process.env.REVENUECAT_WEBHOOK_SECRET) {
      throw new BadRequestException('Invalid RevenueCat secret');
    }

    const { event } = req.body;
    const appUserId   = event?.app_user_id;
    const entitlements: string[] = Object.keys(event?.subscriber?.entitlements ?? {});

    let plan = 'free';
    if (entitlements.includes('elite'))      plan = 'elite';
    else if (entitlements.includes('pro'))   plan = 'pro';

    if (appUserId) await this.plans.setPlan(appUserId, plan);

    return { received: true };
  }
}
