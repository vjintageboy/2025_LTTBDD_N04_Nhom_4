# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

- **ALWAYS run `flutter test` and `flutter analyze` before committing/pushing** - No exceptions
- **Never push without verification** - Evidence before claims
- **Commit messages use conventional format** - `type: description` (e.g., `feat:`, `fix:`, `refactor:`, `chore:`)

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on default device
flutter test             # Run all tests (MUST pass before commit)
flutter analyze          # Lint (MUST pass before commit)
dart format lib/         # Format Dart files
dart fix --apply         # Auto-fix lint issues
flutter gen-l10n         # Regenerate localization files
```

## Architecture

**Moodiki** is a Flutter mental health platform with mood tracking, AI chatbot, meditations, and community forums. Two roles: User and Admin.

**Backend:** Supabase (PostgreSQL, Auth, Realtime). Credentials loaded from `.env` via `flutter_dotenv`.

**Schema Management:** Prisma (schema only, not for queries). See `prisma/schema.prisma`.

### Layer structure

```
views/          → Feature screens (auth, home, mood, chatbot, meditation, chat, news, profile, notification)
core/providers/ → ChangeNotifier providers (AuthProvider, MoodProvider, ChatbotProvider, LocaleProvider)
services/       → Data layer that wraps Supabase and external APIs
models/         → Plain Dart data classes
shared/widgets/ → Reusable UI components
core/constants/ → AppColors, AppConstants, AppTheme
l10n/           → ARB localization files (EN + VI)
prisma/         → PostgreSQL schema management
```

### State management

Provider pattern (`provider` package). Providers wrap services and expose computed/filtered state. Access via `context.read<XProvider>()` / `context.watch<XProvider>()`.

### Navigation

Plain `Navigator` push/pop — `go_router` is listed in pubspec but not in active use. Custom transitions use `PageRouteBuilder`.

### Services

- `supabase_service.dart` — core DB ops (users, moods, meditations, streaks)
- `ai_chatbot_service.dart` — Google Gemini streaming via `google_generative_ai`
- `chat_service.dart` — Supabase Realtime messaging
- `momo_service.dart` — MoMo payment integration (HMAC-SHA256 signature via `crypto`)
- `notification_service.dart` — In-app notifications

### Localization

`intl` + ARB files. Access strings via the `context.l10n` extension. Run `flutter gen-l10n` after editing ARB files.

### Design system

`AppColors`, `AppConstants`, and `AppTheme` (Material 3, custom fonts via `google_fonts`) live in `lib/core/constants/`. The UI uses neumorphic-style card designs throughout.

### Prisma Schema

Located at `prisma/schema.prisma`. Use for schema documentation and validation only.
```bash
cd prisma && npm run validate   # Validate schema
cd prisma && npm run generate   # Generate Prisma client
cd prisma && npm run format     # Format schema
```
