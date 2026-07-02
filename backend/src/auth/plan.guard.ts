import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const REQUIRE_PLAN_KEY = 'requirePlan';
export const RequirePlan = (...plans: string[]) =>
  Reflect.metadata(REQUIRE_PLAN_KEY, plans);

@Injectable()
export class PlanGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const required = this.reflector.get<string[]>(REQUIRE_PLAN_KEY, ctx.getHandler());
    if (!required) return true;

    const { user } = ctx.switchToHttp().getRequest();
    if (required.includes(user?.plan)) return true;

    throw new ForbiddenException(
      `Esta funcionalidade requer plano ${required.join(' ou ')}.`
    );
  }
}
