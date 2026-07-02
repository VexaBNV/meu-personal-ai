import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { User } from '../users/user.entity';

@Entity('refresh_tokens')
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid') id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  user: User;

  @Column({ name: 'token_hash', unique: true }) tokenHash: string;
  @Column({ name: 'device_info', nullable: true }) deviceInfo?: string;
  @Column({ name: 'expires_at' }) expiresAt: Date;
  @Column({ name: 'revoked_at', nullable: true }) revokedAt?: Date;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
