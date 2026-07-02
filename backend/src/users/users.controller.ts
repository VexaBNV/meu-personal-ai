import { Controller, Get, Put, Patch, Body, Req, UseGuards, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getMe(@Req() req: any) {
    return this.usersService.getProfile(req.user.userId);
  }

  @Put('anamnesis')
  saveAnamnesis(@Req() req: any, @Body() dto: any) {
    return this.usersService.saveAnamnesis(req.user.userId, dto);
  }

  @Patch('me')
  updateMe(@Req() req: any, @Body() dto: any) {
    return this.usersService.updateUser(req.user.userId, dto);
  }

  @Patch('me/avatar')
  @UseInterceptors(FileInterceptor('photo'))
  uploadAvatar(@Req() req: any, @UploadedFile() file: Express.Multer.File) {
    return this.usersService.updateAvatar(req.user.userId, file);
  }

  @Get('me/notification-settings')
  getNotifSettings(@Req() req: any) {
    return this.usersService.getNotifSettings(req.user.userId);
  }

  @Patch('me/notification-settings')
  updateNotifSettings(@Req() req: any, @Body() dto: any) {
    return this.usersService.updateNotifSettings(req.user.userId, dto);
  }
}
