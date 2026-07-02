// backend/scripts/run-migrations.ts
// Executa as migrations SQL em ordem
// Uso: npm run migration:run

import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config();

async function runMigrations() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  // Cria tabela de controle de migrations
  await client.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id        SERIAL PRIMARY KEY,
      filename  TEXT UNIQUE NOT NULL,
      ran_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  const migrationsDir = path.join(__dirname, '../migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const { rows } = await client.query(
      'SELECT id FROM _migrations WHERE filename = $1', [file]
    );
    if (rows.length > 0) {
      console.log(`⏭  Já executada: ${file}`);
      continue;
    }

    console.log(`⚡ Rodando: ${file}`);
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    await client.query(sql);
    await client.query(
      'INSERT INTO _migrations (filename) VALUES ($1)', [file]
    );
    console.log(`✅ Concluída: ${file}`);
  }

  await client.end();
  console.log('\n🎉 Todas as migrations executadas!');
}

runMigrations().catch(err => {
  console.error('❌ Erro nas migrations:', err.message);
  process.exit(1);
});
