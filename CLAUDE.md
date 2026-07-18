# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Cashi Gasto — personal finance app (Flutter/Dart). Backend is Supabase (auth, database, storage). Spanish-language codebase: business variables, comments, and UI strings are in Spanish.

## Commands

```bash
flutter pub get                                          # install deps
flutter run                                              # run app
flutter test                                             # all tests
flutter test test/unit/transaction_validation_test.dart   # single test
flutter analyze                                          # lint
dart run build_runner build --delete-conflicting-outputs  # codegen (Riverpod generators, json_serializable)
flutter clean && flutter pub get                         # full rebuild
flutter build apk --release                              # release APK
```

## Architecture

Clean Architecture with feature-based organization:

- **`lib/app/`** — App bootstrap (`app.dart`), GoRouter routes (`routes.dart`), theme (`theme.dart`)
- **`lib/data/`** — Models, repositories, and Supabase datasources. Repositories are the data access layer; datasources under `datasources/supabase/` talk directly to Supabase client.
- **`lib/presentation/`** — Screens (organized by feature: `auth/`, `transactions/`, `funds/`, `goals/`, etc.), reusable widgets, and Riverpod providers.
- **`lib/services/`** — Platform services: OCR (`ocr_service.dart`), SMS parsing (`sms_parser_service.dart`), notifications (`transaction_notification_service.dart`), PDF export, image upload.
- **`lib/config/`** — Supabase config constants.

Data flow: Screen → Provider (Riverpod) → Repository → Supabase datasource.

## Key Conventions

- State management: **Riverpod** with code generation (`riverpod_annotation` + `build_runner`). After changing providers, run codegen.
- Navigation: **GoRouter**. Routes defined in `lib/app/routes.dart` via `AppRoutes` class.
- Environment: `.env` file loaded via `flutter_dotenv` at startup. Requires `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Database schema: `supabase_schema.sql` at repo root. All tables use RLS. User table extends `auth.users`.
- User segments: `help_mode` field on users — `'youth'`, `'business'`, `'support'`, `'general'` — drives feature gating.
