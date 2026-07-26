# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Moodiki (`n04_app`) — a Flutter mental-health app: mood tracking, guided meditation, an AI chatbot, a community news feed, and streaks. Frontend is Flutter (iOS/Android/Web); backend is Supabase (Auth, Postgres + pgvector, Realtime, Storage). Gemini powers the chatbot and RAG embeddings. Primary UI language is Vietnamese; strings are localized EN/VI.

## Commands

```bash
flutter pub get                    # install deps
flutter run                        # run app (needs .env — see below)
flutter analyze                    # lint (package:flutter_lints)
dart format lib/                   # format
flutter test                       # all tests
flutter test test/ai/tools/tool_loop_controller_test.dart   # single file
flutter test --name "substring"    # single test by name
flutter gen-l10n                   # regenerate localizations after editing lib/l10n/*.arb
```

Requires a `.env` at repo root (copy `.env.example`): `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`. `.env` is a bundled asset (see `pubspec.yaml`) — the app won't boot without it.

### Database (Prisma)

Run all Prisma commands from `prisma/` (its own npm package). Prisma Migrate is the source of truth for schema; `schema.prisma` is baselined against the live Supabase DB — **change the schema here, not in the Supabase dashboard**. Shadow DB isn't available via the Supabase pooler, so use the diff + `migrate deploy` flow documented in `prisma/README.md` rather than `migrate dev`. RLS policies live in `policy_RLS.json` and are managed in Supabase, not Prisma.

## Architecture

**State:** `provider`. Four app-wide `ChangeNotifierProvider`s wired in `main.dart`: `LocaleProvider`, `AuthProvider`, `MoodProvider`, `ChatbotProvider`. There's no router package for top-level flow — `AuthWrapper` switches between `WelcomePage` and `HomePage` off `AuthProvider.status`, and is keyed on that status to force a rebuild on auth changes. `go_router` is a dependency but navigation is mostly imperative `Navigator`.

**Layers (`lib/`):**
- `core/` — `constants/` (`app_colors.dart` = the "Organic Sanctuary" theme tokens, `app_strings.dart`), `config/` (Gemini + system prompt), `providers/`, `services/localization_service.dart`.
- `models/` — plain data classes with `fromJson`/`toJson`.
- `services/` — Supabase/API wrappers. `SupabaseService` is a singleton (`SupabaseService.instance`) and the main DB gateway. Tables use `users` (not `profiles`); note `createUserProfile`'s upsert deliberately omits `role` so re-auth doesn't demote an admin.
- `views/<feature>/` — screens grouped by feature (home, mood, meditation, news, chatbot, profile, admin, auth, streak, notification).
- `shared/widgets/` — reusable UI (buttons, cards, app bar, chatbot widget).
- `ai/` — chatbot brains (see below).
- `l10n/` — localizations generated from `lib/l10n/app_{en,vi}.arb`.

**AI chatbot / RAG:** `AIChatbotService` orchestrates Gemini (`gemini-2.5-flash`, config in `core/config/gemini_config.dart`). Flow:
- `RAGService` (`services/rag_service.dart`) builds dynamic context — generates 3072-dim embeddings with `gemini-embedding-001`, runs a Supabase RPC for meditation cosine-similarity search (threshold 0.7), and assembles user goals + 7-day mood history in parallel. User context is cached for 5 min.
- `ai/tools/` implements Gemini function-calling: `tool_definitions.dart` (schemas), `tool_dispatcher.dart` (executes calls), `tool_loop_controller.dart` (multi-turn loop, max 5 iterations, all I/O injected via a `SendMessageFn` typedef so it's unit-testable without hitting the API).
- `ai/safety_filter.dart` + `ai/disclaimer.dart` gate mental-health-sensitive content; Gemini safety settings use the strictest threshold.

**Roles:** the `UserRole` enum is `user | expert | admin`, but expert functionality is being removed (see `docs/compose/plans/`) — treat `user` and `admin` as the live roles; `admin` has its own `views/admin/` section.

## Conventions

- Follow `DESIGN.md` for all UI — the "Organic Sanctuary" system: green palette, **no 1px borders** (separate with surface-color shifts and whitespace), rounded corners everywhere, glassmorphism for nav/headers, tinted ambient shadows (not Material drop shadows). Use `AppColors.os*` tokens, never raw hex or pure black/white.
- Fonts: Plus Jakarta Sans (display/headlines), Manrope (body), via `google_fonts`.
- Tests exist for models, AI tools, RAG, safety, and pure logic — mirror `lib/` structure under `test/`. Keep the AI tool loop testable by injecting I/O rather than calling Gemini directly.
- `CLAUDE.md` and `AGENTS.md` share the same behavioral guidelines below; keep them in sync.

---

# Behavioral guidelines

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
