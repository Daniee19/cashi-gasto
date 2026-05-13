# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cashi Gasto** is a personal finance management Flutter app targeting three user segments:
- **Youth (18+)**: Financial education and goal-setting with AI chatbot guidance
- **Small businesses**: Expense tracking with OCR, SMS automation, and predictive alerts
- **Gambling addiction support**: Abstinence tracker, app blocking, and specialist resources

**Branding**: Primary color `#5F32FA`, mascot named "Cashito"

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Generate Riverpod code (after modifying providers with @riverpod annotation)
dart run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean && flutter pub get
```

## Architecture

The project follows Clean Architecture with feature-based organization:

```
lib/
├── app/                    # App configuration
│   ├── app.dart           # MaterialApp with ProviderScope
│   ├── routes.dart        # GoRouter configuration
│   └── theme.dart         # AppTheme (light/dark)
├── config/
│   └── supabase_config.dart  # Supabase credentials
├── core/
│   └── constants/         # AppColors, AppStrings
├── data/
│   ├── models/            # Data models with fromJson/toJson
│   ├── repositories/      # Repository implementations
│   └── datasources/supabase/  # Supabase client helpers
├── domain/
│   ├── usecases/          # Business logic
│   └── entities/          # Domain entities
├── presentation/
│   ├── screens/           # UI screens by feature
│   ├── widgets/           # Reusable widgets
│   └── providers/         # Riverpod providers
└── services/              # External services (OCR, SMS, notifications)
```

## Tech Stack

- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation**: GoRouter - routes defined in `lib/app/routes.dart`
- **Backend**: Supabase (Auth, PostgreSQL, Storage, Realtime)
- **Charts**: fl_chart
- **Animations**: Lottie (for Cashito mascot)

## Database

Schema is defined in `supabase_schema.sql` at project root. Key tables:
- `user_profiles` - extends Supabase auth.users
- `transactions`, `categories`, `funds` - core finance tracking
- `budgets`, `financial_goals`, `loans` - planning features
- `abstinence_tracker`, `blocked_apps`, `blocked_domains` - addiction support

All tables use UUID primary keys and Row Level Security (RLS) policies.

## Key Patterns

**Models**: Located in `lib/data/models/`, all extend Equatable with:
- `fromJson()` factory constructor
- `toJson()` method
- `copyWith()` method
- Enum types with `fromString()` static method

**Navigation**: Use `context.go()` for replacement, `context.push()` for stack navigation. Route constants in `AppRoutes`.

**Supabase**: Access client via `Supabase.instance.client` or helper in `supabase_client.dart`.

## Android Configuration

`minSdk` is set to 23. Core library desugaring is enabled for `flutter_local_notifications` compatibility.
