# Prisma Schema Management

This directory contains the Prisma schema for Moodiki's PostgreSQL database.

## Setup

1. Copy `.env.example` to `.env` and fill in your Supabase database credentials
2. Install dependencies: `npm install`
3. Validate schema: `npm run validate`

## Commands

```bash
# Validate schema.prisma
npm run validate

# Generate Prisma client
npm run generate

# Format schema file
npm run format

# Open Prisma Studio (visual database browser)
npm run studio
```

## Schema Sync

The `schema.prisma` file mirrors the Supabase database schema defined in `supabase_schema.sql`. When making changes:

1. Update `supabase_schema.sql` first (source of truth)
2. Update `schema.prisma` to match
3. Run `npm run validate` to verify
4. Commit both files

## Notes

- Vector columns (embedding) are not directly supported by Prisma - documented as comments
- RLS policies are Supabase-specific and not represented in Prisma schema
- Expert/appointment tables are included for schema completeness
