import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseStrategy extends PassportStrategy(Strategy, 'firebase') {
  async validate(req: any) {
    const token = req.headers?.authorization?.replace('Bearer ', '');
    if (!token) throw new UnauthorizedException('Token Firebase ausente');

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      return {
        uid:   decoded.uid,
        email: decoded.email ?? '',
        name:  decoded.name ?? decoded.email ?? '',
      };
    } catch {
      throw new UnauthorizedException('Token Firebase inválido');
    }
  }
}
