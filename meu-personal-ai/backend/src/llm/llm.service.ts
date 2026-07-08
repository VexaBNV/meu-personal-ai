import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';

@Injectable()
export class LlmService {
  private readonly client: Anthropic;
  private readonly logger = new Logger(LlmService.name);

  constructor(private readonly cfg: ConfigService) {
    this.client = new Anthropic({ apiKey: cfg.get('LLM_API_KEY') });
  }

  async complete(prompt: string, system?: string): Promise<string> {
    const msg = await this.client.messages.create({
      model:      this.cfg.get('LLM_MODEL_FAST', 'claude-haiku-4-5-20251001'),
      max_tokens: 1024,
      system:     system ?? 'Você é um personal trainer especialista.',
      messages:   [{ role: 'user', content: prompt }],
    });
    return (msg.content[0] as any).text ?? '';
  }

  async chat(
    messages: { role: 'user' | 'assistant'; content: string }[],
    system?: string,
  ): Promise<string> {
    const msg = await this.client.messages.create({
      model:      this.cfg.get('LLM_MODEL_CHAT', 'claude-sonnet-4-6'),
      max_tokens: 2048,
      system:     system ?? 'Você é um personal trainer especialista e motivador.',
      messages,
    });
    return (msg.content[0] as any).text ?? '';
  }

  async completeJSON<T>(
    prompt: string,
    options: { maxTokens?: number; system?: string } = {},
  ): Promise<T> {
    const { maxTokens = 1024, system } = options;
    const msg = await this.client.messages.create({
      model:      this.cfg.get('LLM_MODEL_FAST', 'claude-haiku-4-5-20251001'),
      max_tokens: maxTokens,
      system:     (system ?? 'Você é um personal trainer especialista.') +
                  ' Responda APENAS com JSON válido, sem markdown, sem texto adicional.',
      messages:   [{ role: 'user', content: prompt }],
    });
    const raw   = (msg.content[0] as any).text ?? '';
    const clean = raw.replace(/```json|```/g, '').trim();
    try {
      return JSON.parse(clean) as T;
    } catch (e) {
      this.logger.error('completeJSON — parse falhou', { raw: clean });
      throw new Error('IA retornou JSON inválido. Tente novamente.');
    }
  }

  async generateWorkoutProgram(profile: Record<string, any>): Promise<any> {
    const prompt = `Gere um programa de treino personalizado em JSON para o perfil:\n${JSON.stringify(profile, null, 2)}\n\nRetorne APENAS JSON válido com a estrutura:\n{"name":"string","sessions":[{"name":"string","focus":"string","dayOfWeek":1,"estimatedDuration":60,"exercises":[{"exerciseName":"string","sets":4,"repsMin":8,"repsMax":12,"restSeconds":90,"rpeTarget":8}]}]}`;
    return this.completeJSON(prompt, {
      system: 'Você é um personal trainer especialista. Responda APENAS com JSON válido.',
    });
  }

  async generateWorkoutFeedback(sessionData: Record<string, any>): Promise<string> {
    return this.complete(
      `O usuário completou o treino:\n${JSON.stringify(sessionData, null, 2)}\n\nGere um feedback motivador em 2-3 frases.`
    );
  }
}
