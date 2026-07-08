// src/payments/payments.controller.ts
import {
  Controller, Post, Headers, RawBodyRequest,
  Req, HttpCode, BadRequestException, Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { PlansService } from '../plans/plans.service';
import { PlanId } from '../plans/plans.config';

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

  // ── Stripe ──────────────────────────────────────────────
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
        if (userId) await this.plans.setPlan(userId, PlanId.FREE);
        break;
      }

      case 'invoice.payment_failed': {
        const inv = event.data.object as Stripe.Invoice;
        const sub = await this.stripe.subscriptions.retrieve(inv.subscription as string);
        const userId = sub.metadata?.userId;
        if (userId) {
          this.logger.warn(`Payment failed for user ${userId}`);
          // Não downgrade imediato — Stripe tenta novamente por 7 dias (retry_schedule)
          // O downgrade ocorre no customer.subscription.deleted
        }
        break;
      }
    }

    return { received: true };
  }

  // ── RevenueCat ──────────────────────────────────────────
  @Post('revenuecat')
  @HttpCode(200)
  async revenueCatWebhook(
    @Headers('authorization') auth: string,
    @Req() req: Request,
  ) {
    const expected = `Bearer ${process.env.REVENUECAT_WEBHOOK_SECRET}`;
    if (auth !== expected) throw new BadRequestException('Invalid auth');

    const body = (req as any).body;
    const { event } = body;
    const appUserId: string = event?.app_user_id;
    const entitlements: string[] = Object.keys(event?.subscriber?.entitlements ?? {});

    this.logger.log(`RevenueCat event: ${event?.type} for user ${appUserId}`);

    if (!appUserId) return { received: true };

    // Mapeia entitlements → plano
    let plan = PlanId.FREE;
    if (entitlements.includes('elite')) plan = PlanId.ELITE;
    else if (entitlements.includes('pro')) plan = PlanId.PRO;

    switch (event?.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE':
        await this.plans.setPlan(appUserId, plan);
        break;

      case 'CANCELLATION':
      case 'EXPIRATION':
        // Só faz downgrade na expiração real, não no cancelamento
        if (event?.type === 'EXPIRATION') {
          await this.plans.setPlan(appUserId, PlanId.FREE);
        }
        break;

      case 'TRIAL_STARTED':
        await this.plans.startTrial(appUserId);
        break;
    }

    return { received: true };
  }

  // ── Helpers ─────────────────────────────────────────────
  private async _handleSubscriptionChange(sub: Stripe.Subscription) {
    const userId = sub.metadata?.userId;
    if (!userId) {
      this.logger.warn('Stripe subscription without userId metadata');
      return;
    }

    const priceId = sub.items.data[0]?.price.id;
    const elitePrices = [
      process.env.STRIPE_PRICE_ELITE_MONTHLY,
      process.env.STRIPE_PRICE_ELITE_ANNUAL,
    ];
    const proPrices = [
      process.env.STRIPE_PRICE_PRO_MONTHLY,
      process.env.STRIPE_PRICE_PRO_ANNUAL,
    ];

    let plan = PlanId.FREE;
    if (elitePrices.includes(priceId)) plan = PlanId.ELITE;
    else if (proPrices.includes(priceId)) plan = PlanId.PRO;

    if (sub.status === 'active' || sub.status === 'trialing') {
      await this.plans.setPlan(userId, plan);
    } else if (sub.status === 'past_due' || sub.status === 'canceled') {
      await this.plans.setPlan(userId, PlanId.FREE);
    }
  }
}
