import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { getLimits } from './plans.config';

export const REQUIRE_FEATURE_KEY = 'requireFeature';
export const RequireFeature = (feature: keyof ReturnType<typeof getLimits>) =>
  Reflect.metadata(REQUIRE_FEATURE_KEY, feature);

export const REQUIRE_PLAN_KEY = 'requirePlan';
export const RequirePlan = (...plans: string[]) =>
  Reflect.metadata(REQUIRE_PLAN_KEY, plans);

@Injectable()
export class PlanGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const { user } = ctx.switchToHttp().getRequest();
    const planId   = user?.plan ?? 'free';

    const feature = this.reflector.get<keyof ReturnType<typeof getLimits>>(
      REQUIRE_FEATURE_KEY, ctx.getHandler(),
    );
    if (feature) {
      const limits = getLimits(planId);
      if (!limits[feature]) {
        throw new ForbiddenException(
          `Funcionalidade "${feature}" não disponível no plano ${planId}.`
        );
      }
    }

    const requiredPlans = this.reflector.get<string[]>(
      REQUIRE_PLAN_KEY, ctx.getHandler(),
    );
    if (requiredPlans?.length && !requiredPlans.includes(planId)) {
      throw new ForbiddenException(
        `Requer plano ${requiredPlans.join(' ou ')}.`
      );
    }

    return true;
  }
}
