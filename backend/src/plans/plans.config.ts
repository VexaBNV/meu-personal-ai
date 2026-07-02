// src/plans/plans.config.ts

export type PlanId = 'free' | 'pro' | 'elite';

export interface PlanFeatures {
  aiMessagesPerDay: number;
  maxPrograms: number;
  analytics: boolean;
  photoProgress: boolean;
  expressWorkout: boolean;
  healthSync: boolean;
  trainerPanel: boolean;
  maxProfiles: number;
}

export const PLANS: Record<PlanId, { name: string; features: PlanFeatures }> = {
  free: {
    name: 'Free',
    features: {
      aiMessagesPerDay: 5,
      maxPrograms:      1,
      analytics:        false,
      photoProgress:    false,
      expressWorkout:   false,
      healthSync:       false,
      trainerPanel:     false,
      maxProfiles:      1,
    },
  },
  pro: {
    name: 'Pro',
    features: {
      aiMessagesPerDay: Infinity,
      maxPrograms:      Infinity,
      analytics:        true,
      photoProgress:    true,
      expressWorkout:   true,
      healthSync:       false,
      trainerPanel:     false,
      maxProfiles:      1,
    },
  },
  elite: {
    name: 'Elite',
    features: {
      aiMessagesPerDay: Infinity,
      maxPrograms:      Infinity,
      analytics:        true,
      photoProgress:    true,
      expressWorkout:   true,
      healthSync:       true,
      trainerPanel:     true,
      maxProfiles:      10,
    },
  },
};

export function getLimits(planId: PlanId): PlanFeatures {
  return PLANS[planId]?.features ?? PLANS.free.features;
}
