<p align="center">
  <img src="assets/images/logo.png" alt="Cashi Gasto Logo" width="120" height="120">
</p>

<h1 align="center">Cashi Gasto</h1>

<p align="center">
  <strong>Tu asistente personal de finanzas inteligente</strong>
</p>

<p align="center">
  <a href="#caracteristicas">Caracteristicas</a> •
  <a href="#capturas">Capturas</a> •
  <a href="#instalacion">Instalacion</a> •
  <a href="#configuracion">Configuracion</a> •
  <a href="#arquitectura">Arquitectura</a> •
  <a href="#contribuir">Contribuir</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

---

## Acerca del Proyecto

**Cashi Gasto** es una aplicacion movil de gestion de finanzas personales desarrollada con Flutter, disenada para ayudar a diferentes segmentos de usuarios a tomar control de su economia de manera inteligente y personalizada.

### Segmentos de Usuario

| Segmento | Descripcion | Funcionalidades Clave |
|----------|-------------|----------------------|
| **Jovenes (18+)** | Educacion financiera y establecimiento de metas | Chatbot IA, consejos personalizados, gamificacion |
| **Pequenos negocios** | Control de gastos e ingresos empresariales | OCR de recibos, automatizacion SMS, alertas predictivas |
| **Apoyo a adicciones** | Herramientas para ludopatia | Tracker de abstinencia, bloqueo de apps, recursos de ayuda |

### Mascota

Conoce a **Cashito**, nuestra mascota amigable que te acompana en tu camino hacia la libertad financiera.

---

## Caracteristicas

### Gestion Financiera
- Registro de ingresos y gastos con categorizacion
- Multiples fondos/cuentas (efectivo, banco, ahorros)
- Visualizacion de transacciones con filtros avanzados
- Graficos y reportes interactivos

### Presupuestos y Metas
- Creacion de presupuestos semanales, mensuales o anuales
- Metas financieras con seguimiento de progreso
- Alertas cuando te acercas al limite

### Prestamos
- Registro de prestamos dados y recibidos
- Recordatorios de fechas de pago
- Historial de pagos

### Herramientas Inteligentes
- **OCR**: Escanea recibos y extrae datos automaticamente
- **SMS**: Detecta transacciones bancarias automaticamente
- **Notificaciones**: Alertas predictivas basadas en tus habitos

### Modo de Apoyo (Adicciones)
- Tracker de dias de abstinencia
- Bloqueo de aplicaciones de apuestas
- Bloqueo de dominios web relacionados
- Recursos y contactos de especialistas

---

## Capturas

<p align="center">
  <i>Proximamente...</i>
</p>

---

## Instalacion

### Requisitos Previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.9 o superior
- [Dart SDK](https://dart.dev/get-dart) 3.9 o superior
- Android Studio / VS Code con extensiones de Flutter
- Cuenta en [Supabase](https://supabase.com/) (gratuita)

### Pasos

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/cashi-gasto.git
   cd cashi-gasto
   ```

2. **Instala las dependencias**
   ```bash
   flutter pub get
   ```

3. **Configura las variables de entorno**
   ```bash
   cp .env.example .env
   ```
   Edita `.env` con tus credenciales de Supabase:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu_anon_key_aqui
   ```

4. **Configura la base de datos**
   - Ve al SQL Editor de tu proyecto en Supabase
   - Ejecuta el contenido de `supabase_schema.sql`

5. **Ejecuta la aplicacion**
   ```bash
   flutter run
   ```

---

## Configuracion

### Variables de Entorno

| Variable | Descripcion | Requerido |
|----------|-------------|-----------|
| `SUPABASE_URL` | URL de tu proyecto Supabase | Si |
| `SUPABASE_ANON_KEY` | Clave anonima (publica) de Supabase | Si |

### Base de Datos

El esquema de base de datos se encuentra en `supabase_schema.sql` e incluye:

- **users** - Perfiles de usuario extendidos
- **transactions** - Registro de transacciones
- **categories** - Categorias personalizables
- **funds** - Cuentas y fondos
- **budgets** - Presupuestos
- **financial_goals** - Metas financieras
- **loans** - Prestamos
- **alerts** - Sistema de alertas
- **abstinence_tracker** - Seguimiento de abstinencia
- **blocked_apps** - Aplicaciones bloqueadas
- **blocked_domains** - Dominios bloqueados

Todas las tablas implementan **Row Level Security (RLS)** para proteger los datos de cada usuario.

---

## Arquitectura

El proyecto sigue **Clean Architecture** con organizacion basada en funcionalidades:

```
lib/
├── app/                          # Configuracion de la app
│   ├── app.dart                  # MaterialApp con ProviderScope
│   ├── routes.dart               # Configuracion de GoRouter
│   └── theme.dart                # Temas claro/oscuro
│
├── config/                       # Configuraciones
│   └── supabase_config.dart      # Constantes de Supabase
│
├── core/                         # Nucleo compartido
│   └── constants/                # Colores, strings, etc.
│
├── data/                         # Capa de datos
│   ├── models/                   # Modelos de datos
│   ├── repositories/             # Implementacion de repositorios
│   └── datasources/              # Fuentes de datos (Supabase)
│
├── domain/                       # Capa de dominio
│   ├── entities/                 # Entidades de negocio
│   └── usecases/                 # Casos de uso
│
├── presentation/                 # Capa de presentacion
│   ├── screens/                  # Pantallas por funcionalidad
│   ├── widgets/                  # Widgets reutilizables
│   └── providers/                # Providers de Riverpod
│
└── services/                     # Servicios externos
    ├── ocr_service.dart          # Servicio de OCR
    ├── sms_service.dart          # Servicio de SMS
    └── notification_service.dart # Notificaciones locales
```

### Stack Tecnologico

| Categoria | Tecnologia |
|-----------|------------|
| **Framework** | Flutter 3.9+ |
| **Estado** | Riverpod |
| **Navegacion** | GoRouter |
| **Backend** | Supabase (Auth, Database, Storage) |
| **Graficos** | fl_chart |
| **Animaciones** | Lottie |
| **Notificaciones** | flutter_local_notifications |

---

## Comandos Utiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run

# Generar codigo de Riverpod
dart run build_runner build --delete-conflicting-outputs

# Analizar codigo
flutter analyze

# Ejecutar tests
flutter test

# Limpiar y reconstruir
flutter clean && flutter pub get

# Compilar APK de release
flutter build apk --release

# Compilar App Bundle para Play Store
flutter build appbundle --release
```

---

## Contribuir

Las contribuciones son bienvenidas. Por favor, sigue estos pasos:

1. Haz fork del proyecto
2. Crea una rama para tu funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. Haz commit de tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Haz push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

### Guia de Estilo

- Sigue las [convenciones de Dart](https://dart.dev/guides/language/effective-dart/style)
- Usa nombres descriptivos en espanol para variables de negocio
- Documenta funciones publicas complejas
- Escribe tests para nuevas funcionalidades

---

## Roadmap

- [x] Autenticacion con Supabase
- [x] CRUD de transacciones
- [ ] Dashboard con graficos
- [ ] Presupuestos
- [ ] Metas financieras
- [ ] OCR de recibos
- [ ] Deteccion de SMS bancarios
- [ ] Chatbot con IA
- [ ] Modo de apoyo a adicciones
- [ ] Notificaciones predictivas
- [ ] Exportar reportes (PDF/Excel)

---

## Licencia

Este proyecto esta bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para mas detalles.

---

## Contacto

**Cashi Gasto** - [@cashigasto](https://twitter.com/cashigasto)

Link del proyecto: [https://github.com/tu-usuario/cashi-gasto](https://github.com/tu-usuario/cashi-gasto)

---

<p align="center">
  Hecho con Flutter
</p>
