import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { User } from '../users/user.entity';
import { RefreshToken } from './refresh-token.entity';

@Injectable()
export class AuthService {

  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
    @InjectRepository(RefreshToken) private readonly tokens: Repository<RefreshToken>,
    private readonly jwt: JwtService,
    private readonly cfg: ConfigService,
  ) {}

  async loginWithFirebase(firebaseUser: { uid: string; email: string; name: string }) {
    let user = await this.users.findOne({ where: { firebaseUid: firebaseUser.uid } });

    if (!user) {
      user = this.users.create({
        firebaseUid: firebaseUser.uid,
        email:       firebaseUser.email,
        name:        firebaseUser.name || firebaseUser.email.split('@')[0],
      });
      await this.users.save(user);
    }

    return this.issueTokenPair(user);
  }

  async refreshAccessToken(rawToken: string) {
    const hash = this.hashToken(rawToken);
    const stored = await this.tokens.findOne({
      where: { tokenHash: hash },
      relations: ['user'],
    });

    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token inválido ou expirado');
    }

    const accessToken = this.signAccess(stored.user);
    return { accessToken };
  }

  async logout(rawToken: string) {
    const hash = this.hashToken(rawToken);
    await this.tokens.update({ tokenHash: hash }, { revokedAt: new Date() });
  }

  private async issueTokenPair(user: User) {
    const accessToken  = this.signAccess(user);
    const refreshToken = crypto.randomBytes(48).toString('hex');

    const expiresIn = this.cfg.get('JWT_REFRESH_EXPIRES_IN', '30d');
    const days = parseInt(expiresIn);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + days);

    await this.tokens.save(this.tokens.create({
      user,
      tokenHash: this.hashToken(refreshToken),
      expiresAt,
    }));

    return {
      accessToken,
      refreshToken,
      user: {
        id:                 user.id,
        name:               user.name,
        email:              user.email,
        plan:               user.plan,
        anamnesisCompleted: user.anamnesisCompleted,
      },
    };
  }

  private signAccess(user: User) {
    return this.jwt.sign({ sub: user.id, plan: user.plan });
  }

  private hashToken(raw: string) {
    return crypto.createHash('sha256').update(raw).digest('hex');
  }
}
