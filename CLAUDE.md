# CLAUDE.md

Este archivo proporciona orientación a Claude Code (claude.ai/code) para trabajar con el código en este repositorio.

## Descripción del Proyecto

Cashi Gasto es una app móvil de finanzas personales para control de gastos/ingresos, metas financieras y un chatbot asistente. Construida con Flutter y backend en Supabase.

## Comandos Comunes

```bash
# Ejecutar la app
flutter run

# Compilar para producción
flutter build apk
flutter build ios

# Generar código de Riverpod (después de modificar providers con anotaciones)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar tests
flutter test

# Obtener dependencias
flutter pub get
```

## Arquitectura

**Feature-first + Clean Architecture Ligera**

```
lib/
├── core/           # Utilidades compartidas, tema, widgets
│   ├── constants/  # Constantes de la app (config de Supabase en app_constants.dart)
│   ├── theme/      # AppColors, AppTypography, AppSpacing, AppTheme
│   ├── utils/      # Formateadores, validadores
│   └── widgets/    # Widgets reutilizables (AppButton, AppCard, AppTextField, etc.)
├── features/       # Módulos de funcionalidades
│   └── [feature]/
│       ├── data/           # Implementaciones de repositorios
│       ├── domain/         # Estados, entidades
│       └── presentation/   # Páginas, widgets, providers
└── shared/
    └── models/     # Modelos de datos (UserModel, TransactionModel, etc.)
```

**Gestión de Estado**: Riverpod con patrón StateNotifier. Los providers están en `presentation/providers/`. La lógica de negocio no va en los widgets.

**Navegación**: Navegación inferior con `google_nav_bar` en `MainShell` (`core/widgets/main_shell.dart`). Enrutamiento basado en autenticación en `main.dart` usando switch expression sobre `AuthStatus`.

**Backend**: Supabase (Auth + PostgreSQL). Patrón repositorio - ver `AuthRepository` y `TransactionsRepository`.

## Patrones Clave

- **Flujo de auth**: `AuthNotifier` en `auth_provider.dart` maneja el estado de sesión. Estados: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`
- **Archivos barrel**: Cada módulo exporta mediante un solo archivo (ej: `auth.dart`, `theme.dart`, `widgets.dart`)
- **Config de Supabase**: Copiar `app_constants.example.dart` a `app_constants.dart` con tus credenciales

## Sistema de Diseño

- Color primario: `#5f32fa`
- Fuentes: Konkhmer Sleokchher (títulos), Aoboshi One (textos) via Google Fonts
- Spacing: sistema 4/8/16/24/32 (`AppSpacing`)
- Usar widgets existentes de `core/widgets/` antes de crear nuevos
