# Prisma Schema Management

This directory contains the Prisma schema for Moodiki's PostgreSQL database.

Prisma Migrate is the source of truth for tables/columns/indexes. `schema.prisma`
is baselined against the existing Supabase database (`migrations/0_init`), so you
change the schema here instead of editing tables in the Supabase dashboard.

## Setup

1. Copy `.env.example` to `.env` and set both connection strings from
   Supabase Dashboard > Settings > Database:
   - `DATABASE_URL` — transaction pooler (port 6543), for runtime queries
   - `DIRECT_URL` — session/direct connection (port 5432), used by Migrate/pull/studio
2. Install dependencies: `npm install`
3. Validate schema: `npm run validate`

## Commands

```bash
npm run validate   # Validate schema.prisma
npm run generate   # Generate Prisma client
npm run format     # Format schema file
npm run studio     # Open Prisma Studio (visual database browser)
```

## Making Schema Changes

To add/edit/remove a table or column:

1. Edit `schema.prisma`
2. Generate a migration from the current DB state (no shadow DB needed):
   ```bash
   npx prisma migrate diff \
     --from-migrations ./migrations \
     --to-schema-datamodel schema.prisma \
     --script > migrations/<timestamp>_<name>/migration.sql
   ```
3. Apply it to Supabase:
   ```bash
   npx prisma migrate deploy
   ```
4. Commit `schema.prisma` and the new migration folder

> Alternatively `npx prisma migrate dev` generates + applies in one step, but it
> requires a shadow database, which the Supabase pooler may not permit. The
> diff + `migrate deploy` flow above avoids that.

## Not managed by Prisma (keep in Supabase)

These are outside Prisma's model and are **not** created/updated by migrations —
manage them in Supabase directly:

- **RLS policies** — configured in the Supabase dashboard (see `../policy_RLS.json`)
- **CHECK constraints** — e.g. `mood_score` 1..5, `day_of_week` 0..6
- **`meditations.embedding` (pgvector)** — vector type is `Unsupported` in Prisma
- **`auth` schema, triggers, and the `public.users` → `auth.users` FK**

A destructive migrate/reset would drop the CHECK constraints and RLS, so avoid
`migrate reset`/`db push --force-reset` against the real database.
