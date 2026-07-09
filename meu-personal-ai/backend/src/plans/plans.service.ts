import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { User } from '../users/user.entity';
import { getLimits } from './plans.config';

interface SetPlanOpts {
  status?:    string;
  periodEnd?: Date;
}

@Injectable()
export class PlansService {
  private readonly stripe: Stripe;

  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly dataSource: DataSource,
    private readonly cfg: ConfigService,
  ) {
    this.stripe = new Stripe(cfg.get('STRIPE_SECRET_KEY', 'sk_test_placeholder'));
  }

  async getStatus(userId: string) {
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const planId = user.plan as string;
    const limits = getLimits(planId);

    return {
      plan:      planId,
      status:    user.subscriptionStatus ?? 'inactive',
      periodEnd: user.subscriptionPeriodEnd,
      hadTrial:  user.hadTrial,
      features:  limits,
    };
  }

  async setPlan(userId: string, planId: string, opts: SetPlanOpts = {}) {
    await this.users.update({ id: userId }, {
      plan:                 planId,
      subscriptionStatus:   opts.status ?? (planId === 'free' ? 'inactive' : 'active'),
      subscriptionPeriodEnd: opts.periodEnd,
    });
  }

  async startTrial(userId: string) {
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException();

    if (user.hadTrial) {
      return { ok: false, message: 'Trial já utilizado anteriormente.' };
    }

    const trialEndsAt = new Date();
    trialEndsAt.setDate(trialEndsAt.getDate() + 7);

    await this.setPlan(userId, 'pro', { status: 'trialing' });
    await this.users.update({ id: userId }, {
      hadTrial:    true,
      trialEndsAt,
    });

    return { ok: true, trialEndsAt };
  }

  async createStripeCustomer(userId: string): Promise<string> {
    const user = await this.users.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException();

    if (user.stripeCustomerId) return user.stripeCustomerId;

    const customer = await this.stripe.customers.create({
      email:    user.email,
      name:     user.name,
      metadata: { userId },
    });

    await this.users.update({ id: userId }, { stripeCustomerId: customer.id });
    return customer.id;
  }

  async getCustomerPortalUrl(userId: string): Promise<string> {
    const customerId = await this.createStripeCustomer(userId);
    const session = await this.stripe.billingPortal.sessions.create({
      customer:   customerId,
      return_url: this.cfg.get('WEBSITE_URL', 'https://meupersonalai.com.br'),
    });
    return session.url;
  }

  async expireTrials() {
    const expired = await this.users.find({
      where: { subscriptionStatus: 'trialing' } as any,
    });

    const now = new Date();
    for (const user of expired) {
      if (user.trialEndsAt && user.trialEndsAt < now) {
        await this.setPlan(user.id, 'free', { status: 'inactive' });
      }
    }
  }
}
