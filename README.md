<p align="center">
  <img src="assets/images/logo.png" alt="Cashi Gasto Logo" width="180"/>
</p>

<h1 align="center">Cashi Gasto</h1>

<p align="center">
  <strong>Tu asistente personal de finanzas con deteccion automatica</strong>
</p>

<p align="center">
  <a href="#caracteristicas">Caracteristicas</a> •
  <a href="#deteccion-automatica">Deteccion Automatica</a> •
  <a href="#ocr">OCR</a> •
  <a href="#instalacion">Instalacion</a> •
  <a href="#arquitectura">Arquitectura</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey" alt="Platform">
</p>

---

## Acerca del Proyecto

**Cashi Gasto** es una aplicacion de finanzas personales que te ayuda a registrar tus gastos e ingresos de forma inteligente. Detecta automaticamente tus transacciones bancarias desde las notificaciones de Yape, BCP y otros bancos peruanos, y puede escanear boletas y facturas con OCR.

### Mascota

Conoce a **Cashito**, el gatito que cuida tu alcancia y te acompana en tu camino hacia la libertad financiera.

---

## Caracteristicas

### Gestion de Transacciones
- Registro de ingresos y gastos
- Categorias personalizables con iconos
- Multiples fondos/cuentas (efectivo, banco, tarjetas, Yape)
- Historial con filtros por fecha, categoria y tipo
- Transferencias entre fondos

### Presupuestos
- Presupuestos mensuales por categoria
- Barra de progreso visual
- Alertas al acercarte al limite

### Metas Financieras
- Establece objetivos de ahorro
- Seguimiento de progreso
- Fecha limite opcional

### Reportes
- Graficos de gastos por categoria
- Comparativas mensuales
- Exportacion a PDF

---

## Deteccion Automatica

La app puede detectar automaticamente tus transacciones escuchando las notificaciones de apps bancarias.

### Apps Soportadas

| App | Banco | Funcionalidad |
|-----|-------|---------------|
| **Yape** | BCP | Pagos enviados y recibidos |
| **BCP App** | BCP | Consumos, transferencias |
| **Interbank App** | Interbank | Compras, depositos |
| **BBVA Peru** | BBVA | Pagos, transferencias |
| **Scotiabank** | Scotiabank | Transacciones |
| **Banco de la Nacion** | BN | Operaciones |
| **SMS Bancarios** | Varios | Alertas de consumo |

### Como Funciona

```
Notificacion llega → Filtro de apps bancarias → Parser extrae datos
                                                      ↓
                                          Monto, tipo, descripcion
                                                      ↓
                              ┌─────────────────────────────────────┐
                              │  Modo Automatico    Modo Manual     │
                              │  Registra directo   Muestra para    │
                              │  en la app          confirmar       │
                              └─────────────────────────────────────┘
```

### Configuracion

Accede desde: **Mas opciones > Deteccion automatica**

1. Activa la deteccion
2. Concede permiso de notificaciones
3. Elige modo automatico o confirmacion manual
4. Selecciona tu cuenta por defecto
5. Habilita/deshabilita apps especificas

---

## OCR

Escanea boletas, facturas y recibos para extraer los datos automaticamente.

### Formatos Soportados

| Formato | Metodo |
|---------|--------|
| **PDF con texto** | Extraccion directa (Syncfusion) |
| **PDF escaneado** | OCR con ML Kit |
| **Imagen (camara)** | OCR con ML Kit |
| **Imagen (galeria)** | OCR con ML Kit |

### Deteccion Inteligente

- Detecta el monto total (numero mas grande con decimales)
- Filtra automaticamente RUC, DNI, direcciones y fechas
- Sugiere categoria basada en palabras clave del comercio
- Extrae nombre del establecimiento

### Ejemplo

```
SUPERMERCADO METRO
Av. Javier Prado 1234
RUC: 20100070970

Arroz x2          S/. 12.80
Aceite            S/. 15.50
Leche x3          S/. 10.20

TOTAL             S/. 45.43
                      ↑
              Detecta este monto
```

---

## Instalacion

### Requisitos

- Flutter SDK 3.9.2+
- Cuenta en Supabase

### Pasos

```bash
# 1. Clonar repositorio
git clone https://github.com/Daniee19/cashi-gasto.git
cd cashi-gasto

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de Supabase

# 3. Instalar dependencias
flutter pub get

# 4. Generar codigo (Riverpod, JSON)
dart run build_runner build --delete-conflicting-outputs

# 5. Generar iconos
dart run flutter_launcher_icons

# 6. Ejecutar
flutter run
```

### Variables de Entorno

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

---

## Arquitectura

Clean Architecture con organizacion por features:

```
lib/
├── app/                    # Bootstrap, rutas, tema
│   ├── app.dart           # MaterialApp + inicializacion SMS
│   ├── routes.dart        # GoRouter
│   └── theme.dart         # Tema claro/oscuro
│
├── config/                 # Configuracion Supabase
│
├── core/                   # Constantes, colores
│
├── data/
│   ├── models/            # Transaction, Category, Fund, etc.
│   ├── repositories/      # Logica de acceso a datos
│   └── datasources/       # Supabase client
│
├── presentation/
│   ├── screens/           # UI por feature
│   │   ├── auth/         # Login, registro
│   │   ├── home/         # Dashboard
│   │   ├── transactions/ # Lista, agregar, OCR
│   │   ├── funds/        # Cuentas
│   │   ├── categories/   # Categorias
│   │   ├── budgets/      # Presupuestos
│   │   ├── goals/        # Metas
│   │   ├── reports/      # Graficos
│   │   ├── alerts/       # Alertas
│   │   ├── settings/     # Config SMS
│   │   └── more/         # Menu
│   ├── widgets/          # Componentes reutilizables
│   └── providers/        # Riverpod state management
│
└── services/
    ├── ocr_service.dart                    # Escaneo de documentos
    ├── sms_parser_service.dart             # Parser de notificaciones
    └── transaction_notification_service.dart # Listener de notificaciones
```

### Stack Tecnologico

| Categoria | Tecnologia |
|-----------|------------|
| Framework | Flutter 3.9.2 |
| Estado | Riverpod + Code Generation |
| Backend | Supabase (Auth, DB, Storage) |
| Navegacion | GoRouter |
| OCR | Google ML Kit + Syncfusion PDF |
| Notificaciones | notification_listener_service |
| Graficos | fl_chart |
| Iconos | flutter_launcher_icons |

---

## Comandos Utiles

```bash
flutter pub get                              # Instalar deps
flutter run                                  # Ejecutar app
flutter test                                 # Correr tests
flutter analyze                              # Lint
dart run build_runner build                  # Generar codigo
dart run flutter_launcher_icons              # Generar iconos
flutter build apk --release                  # Build APK
flutter clean && flutter pub get             # Limpiar todo
```

---

## Tests

```bash
# Correr todos los tests
flutter test

# Test de flujo SMS
flutter test test/sms_flow_test.dart
```

### Tests de Deteccion SMS

13 casos validados:
- Yape: pagos enviados y recibidos
- BCP: consumos y transferencias
- Interbank, BBVA: compras
- SMS generico: consumos y depositos
- Filtrado de apps no bancarias
- Deduplicacion de notificaciones

---

## Base de Datos

Esquema en `supabase_schema.sql`. Tablas principales:

| Tabla | Descripcion |
|-------|-------------|
| users | Usuarios con segmento (youth, business, support) |
| categories | Categorias de transacciones |
| funds | Cuentas/fondos del usuario |
| transactions | Ingresos y gastos |
| budgets | Presupuestos mensuales |
| goals | Metas de ahorro |
| alerts | Alertas del sistema |

Todas las tablas usan Row Level Security (RLS).

---

## Roadmap

- [x] Autenticacion con Supabase
- [x] CRUD de transacciones
- [x] Categorias personalizables
- [x] Multiples fondos/cuentas
- [x] Presupuestos
- [x] Metas financieras
- [x] OCR de recibos y facturas
- [x] Deteccion automatica de notificaciones bancarias
- [x] Reportes con graficos
- [ ] Modo oscuro
- [ ] Exportar a Excel
- [ ] Chatbot con IA
- [ ] Modo de apoyo a adicciones

---

## Contribuir

1. Fork el proyecto
2. Crea tu rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit (`git commit -m 'feat: agregar funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## Licencia

Proyecto privado de uso personal.

---

<p align="center">
  Hecho con Flutter y mass cafe del necesario<br>
  <strong>Cashi Gasto</strong> - Tu gatito financiero
</p>
