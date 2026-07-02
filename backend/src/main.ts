import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app    = await NestFactory.create(AppModule);
  const cfg    = app.get(ConfigService);
  const logger = new Logger('Bootstrap');
  const port   = cfg.get<number>('PORT', 3000);

  // Segurança
  app.use(helmet());
  app.enableCors({
    origin: cfg.get('CORS_ORIGINS', 'http://localhost:3000').split(','),
    credentials: true,
  });

  // Validação global de DTOs
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: false,
  }));

  // Prefixo global (vazio em produção, 'api' em dev se necessário)
  const prefix = cfg.get('API_PREFIX', '');
  if (prefix) app.setGlobalPrefix(prefix);

  await app.listen(port);
  logger.log(`Application is running on: http://localhost:${port}`);
  logger.log(`Health: http://localhost:${port}/health`);
}

bootstrap();
