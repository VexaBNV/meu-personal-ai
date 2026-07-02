import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PlansModule } from '../plans/plans.module';

@Module({
  imports: [PlansModule],
  controllers: [PaymentsController],
})
export class PaymentsModule {}
