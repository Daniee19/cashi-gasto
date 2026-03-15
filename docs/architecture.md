# Cashi Gasto - Architecture

## Project Overview
Cashi Gasto es una aplicación móvil financiera enfocada en el control de gastos e ingresos.

Objetivos principales:
- Control financiero personal
- Visualización clara de ingresos y gastos
- Metas financieras
- Soporte mediante chatbot financiero
- Herramientas de ayuda para personas con ludopatía

La app está optimizada principalmente para dispositivos móviles.

---

# Tech Stack

Frontend
- Flutter
- Material 3
- Riverpod (state management)

Backend
- Supabase
- PostgreSQL database
- Supabase Auth

Arquitectura
- Feature-first
- Clean Architecture ligera

---

# Design System

Primary Color
#5f32fa

Tema visual
- moderno
- minimalista
- amigable
- uso de gatitos como elemento visual y chatbot

Tipografías
- Konkhmer Sleokchher → títulos
- Aoboshi One → textos

Spacing
Usar sistema consistente de spacing:
4 / 8 / 16 / 24 / 32

---

# Navigation

La aplicación utiliza navegación inferior.

Paquete:
google_nav_bar

Pantallas principales:

- Onboarding
- Login
- Dashboard
- Registrar gasto
- Registrar ingreso
- Metas financieras
- Chatbot
- Reportes
- Configuración

---

# Folder Structure

lib/

core/
- constants
- theme
- widgets
- utils

features/

auth/
data/
domain/
presentation/

transactions/
data/
domain/
presentation/

dashboard/
goals/
chatbot/
reports/
settings/

---

# State Management

Usar Riverpod.

Separar:

providers
repositories
services

La lógica de negocio no debe ir en widgets.

---

# Backend Integration

El backend usa Supabase.

Responsabilidades:

Supabase Auth
- login
- registro
- sesión

Supabase Database
- CRUD de transacciones
- categorías
- métricas
- presupuestos

---

# Database Model

User
- id
- full_name
- email
- profile_photo
- created_at
- updated_at

Fund
- id
- user_id
- bank
- cash
- saving

Category
- id
- user_id
- name
- description
- transaction_category (income | expense)

Transaction
- id
- user_id
- category_id
- fund_id
- amount
- transaction_method (manual | OCR | SMS)
- transaction_date
- note
- created_at

Budget
- id
- user_id
- period
- date
- amount_budgeted

Alert
- id
- user_id
- alert_type
- message
- alert_date

Loan
- id
- user_id
- limit_date
- amount
- receiver
- description
- loan_type

BlockedDomain
- id
- user_id
- url

Metrics
- id
- user_id
- period_date
- total_income
- total_expense
- savings
- transactions_count
- updated_at

Metrics contiene agregaciones mensuales de Transaction.

---

# AI Chatbot

La app incluye un chatbot financiero.

Funciones:
- consejos financieros
- ayuda con metas
- apoyo para personas con ludopatía
- sugerir contactar especialistas

Puede integrarse con APIs externas como Grok.

---

# Monetization

Modelo Freemium.

Gratis
- límite de mensajes con chatbot
- máximo 3 PDFs por día
- anuncios

Premium
- eliminar anuncios
- chatbot ilimitado

---

# Code Guidelines

El código debe:

- usar widgets reutilizables
- mantener spacing consistente
- separar UI y lógica
- usar providers para estado
- evitar lógica compleja en widgets
- mantener archivos pequeños