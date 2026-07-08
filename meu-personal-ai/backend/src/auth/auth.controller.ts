import { Controller, Post, Body, UseGuards, Req, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {

  constructor(private readonly authService: AuthService) {}

  /** Troca o Firebase ID Token por tokens JWT próprios */
  @Post('login')
  @UseGuards(AuthGuard('firebase'))
  @HttpCode(HttpStatus.OK)
  async login(@Req() req: any) {
    return this.authService.loginWithFirebase(req.user);
  }

  /** Renova o access token usando o refresh token */
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body('refreshToken') refreshToken: string) {
    return this.authService.refreshAccessToken(refreshToken);
  }

  /** Invalida o refresh token (logout) */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body('refreshToken') refreshToken: string) {
    await this.authService.logout(refreshToken);
  }
}
