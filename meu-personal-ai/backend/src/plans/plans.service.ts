import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { User } from '../users/user.entity';
import { PlanId, PLANS, getLimits } from './plans.config';

@Injectable()
export class PlansService {
  private readonly logger = new Logger(PlansService.name);
  private readonly stripe: Stripe;

  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
    private readonly dataSource: DataSource,
    config: ConfigService,
  ) {
    this.stripe = new Stripe(config.getOrThrow('STRIPE_SECRET_KEY'));
  }

  // ── Leitura ──────────────────────────────────────────────

  async getPlanStatus(userId: string) {
    const user = await this.users.findOneOrFail({ where: { id: userId } });
    const limits = getLimits(user.planId as PlanId);
    return {
      plan:                user.planId,
      status:              user.subscriptionStatus ?? 'inactive',
      periodEnd:           user.subscriptionPeriodEnd,
      hadTrial:            user.hadTrial,
      features:            PLANS[user.planId as PlanId]?.features ?? {},
      limits,
    };
  }

  // ── Mutações ─────────────────────────────────────────────

  /**
   * Define o plano de um usuário e audita o evento.
   * Chamado pelos webhooks Stripe e RevenueCat.
   */
  async setPlan(
    userId: string,
    planId: PlanId,
    opts: {
      source?: 'stripe' | 'revenuecat' | 'manual';
      eventType?: string;
      productId?: string;
      amountCents?: number;
      rawPayload?: object;
      subscriptionId?: string;
      periodEnd?: Date;
      status?: string;
    } = {},
  ) {
    await this.dataSource.transaction(async (em) => {
      await em.update(User, { id: userId }, {
        planId,
        subscriptionStatus:    opts.status ?? (planId === PlanId.FREE ? 'inactive' : 'active'),
        subscriptionPeriodEnd: opts.periodEnd,
        // subscriptionProductId removido — campo não existe na entidade
        ...(opts.subscriptionId && { stripeSubscriptionId: opts.subscriptionId }),
      });

      await em.query(
        `INSERT INTO payment_events
           (user_id, source, event_type, plan_id, product_id, amount_cents, raw_payload)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          userId,
          opts.source ?? 'manual',
          opts.eventType ?? 'plan_change',
          planId,
          opts.productId ?? null,
          opts.amountCents ?? null,
          opts.rawPayload ? JSON.stringify(opts.rawPayload) : null,
        ],
      );
    });

    this.logger.log(`User ${userId} → plan ${planId} (${opts.source ?? 'manual'})`);
  }

  /**
   * Inicia trial de 7 dias do Pro.
   * Chamado quando usuário toca "Testar 7 dias grátis".
   */
  async startTrial(userId: string): Promise<void> {
    const user = await this.users.findOneOrFail({ where: { id: userId } });

    if (user.hadTrial) {
      throw new Error('User already used trial');
    }

    const trialEnd = new Date();
    trialEnd.setDate(trialEnd.getDate() + 7);

    await this.setPlan(userId, PlanId.PRO, {
      source: 'manual',
      eventType: 'trial_started',
      status: 'trialing',
      periodEnd: trialEnd,
    });

    await this.users.update({ id: userId }, { hadTrial: true });
  }

  /**
   * Cria customer Stripe para o usuário.
   * Chamar no registro (AuthService.register).
   */
  async createStripeCustomer(userId: string, email: string, name?: string): Promise<string> {
    const user = await this.users.findOneOrFail({ where: { id: userId } });
    if (user.stripeCustomerId) return user.stripeCustomerId;

    const customer = await this.stripe.customers.create({
      email,
      name,
      metadata: { userId },
    });

    await this.users.update({ id: userId }, { stripeCustomerId: customer.id });
    this.logger.log(`Stripe customer created: ${customer.id} for user ${userId}`);
    return customer.id;
  }

  /**
   * Retorna URL do portal Stripe para o usuário gerenciar assinatura.
   * Exibir na ProfileScreen → "Gerenciar assinatura".
   */
  async getCustomerPortalUrl(userId: string, returnUrl: string): Promise<string> {
    const user = await this.users.findOneOrFail({ where: { id: userId } });
    if (!user.stripeCustomerId) {
      throw new Error('No Stripe customer for this user');
    }

    const session = await this.stripe.billingPortal.sessions.create({
      customer: user.stripeCustomerId,
      return_url: returnUrl,
    });

    return session.url;
  }

  // ── Cron: expira trials ──────────────────────────────────
  // (já implementado em TrialExpiryScheduler — só garante
  //  que o campo status seja atualizado)

  async expireTrials(): Promise<void> {
    const expired = await this.users.find({
      where: { plan: PlanId.PRO } as any,
    });

    const now = new Date();
    for (const user of expired) {
      if (
        user.subscriptionStatus === 'trialing' &&
        user.subscriptionPeriodEnd &&
        user.subscriptionPeriodEnd < now
      ) {
        await this.setPlan(user.id, PlanId.FREE, {
          source: 'manual',
          eventType: 'trial_expired',
          status: 'inactive',
        });
        this.logger.log(`Trial expired for user ${user.id}`);
      }
    }
  }
}
