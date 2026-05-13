-- =====================================================
-- CASHI GASTO - Schema para Supabase (Actualizado)
-- =====================================================
-- Ejecutar este script en el SQL Editor de Supabase
-- Asegurate de tener configurado Authentication antes
-- =====================================================

-- Tabla de usuarios (extiende auth.users)
CREATE TABLE "users" (
    "id" UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    "full_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "help_mode" VARCHAR(20) DEFAULT 'general', -- 'youth', 'business', 'support', 'general'
    "profile_photo" TEXT,
    "created_at" TIMESTAMPTZ DEFAULT NOW(),
    "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Categorias de transacciones
CREATE TABLE "categories" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID REFERENCES users(id) ON DELETE CASCADE,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "type" VARCHAR(20) NOT NULL, -- 'income', 'expense'
    "icon" VARCHAR(50),
    "color" VARCHAR(7), -- hex color
    "is_default" BOOLEAN DEFAULT FALSE,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Fondos/Cuentas
CREATE TABLE "funds" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "name" VARCHAR(100) NOT NULL,
    "type" VARCHAR(20) NOT NULL, -- 'bank', 'cash', 'savings'
    "balance" DECIMAL(15,2) DEFAULT 0,
    "icon" VARCHAR(50),
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Transacciones
CREATE TABLE "transactions" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "category_id" UUID REFERENCES categories(id) ON DELETE SET NULL,
    "fund_id" UUID REFERENCES funds(id) ON DELETE SET NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "type" VARCHAR(20) NOT NULL, -- 'income', 'expense', 'transfer'
    "transaction_method" VARCHAR(50), -- 'cash', 'card', 'transfer'
    "transaction_date" DATE NOT NULL,
    "note" TEXT,
    "receipt_image" VARCHAR(255),
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Presupuestos
CREATE TABLE "budgets" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "category_id" UUID REFERENCES categories(id) ON DELETE CASCADE,
    "period" VARCHAR(20) NOT NULL, -- 'weekly', 'monthly', 'yearly'
    "amount_budgeted" DECIMAL(15,2) NOT NULL,
    "start_date" DATE NOT NULL,
    "end_date" DATE NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Metas financieras
CREATE TABLE "financial_goals" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "target_amount" DECIMAL(15,2) NOT NULL,
    "current_amount" DECIMAL(15,2) DEFAULT 0,
    "deadline" DATE,
    "status" VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Prestamos
CREATE TABLE "loans" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "contact_name" VARCHAR(200) NOT NULL,
    "amount" DECIMAL(15,2) NOT NULL,
    "loan_type" VARCHAR(20) NOT NULL, -- 'lent', 'borrowed'
    "limit_date" DATE,
    "description" TEXT,
    "status" VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'overdue'
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Alertas
CREATE TABLE "alerts" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "alert_type" VARCHAR(50) NOT NULL, -- 'budget_warning', 'goal_reminder', 'loan_due'
    "title" VARCHAR(200) NOT NULL,
    "message" TEXT NOT NULL,
    "alert_date" TIMESTAMPTZ NOT NULL,
    "is_read" BOOLEAN DEFAULT FALSE,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Metricas diarias
CREATE TABLE "metrics" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "date" DATE NOT NULL,
    "total_income" DECIMAL(15,2) DEFAULT 0,
    "total_expense" DECIMAL(15,2) DEFAULT 0,
    "savings" DECIMAL(15,2) DEFAULT 0,
    "transactions_count" INTEGER DEFAULT 0,
    "updated_at" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- =====================================================
-- TABLAS PARA SOPORTE A LUDOPATAS
-- =====================================================

-- Apps bloqueadas
CREATE TABLE "blocked_apps" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "app_name" VARCHAR(200) NOT NULL,
    "package_name" VARCHAR(200) NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Dominios bloqueados
CREATE TABLE "blocked_domains" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "url" VARCHAR(500) NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT NOW()
);

-- Tracker de abstinencia
CREATE TABLE "abstinence_tracker" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "start_date" DATE NOT NULL,
    "current_streak_days" INTEGER DEFAULT 0,
    "longest_streak" INTEGER DEFAULT 0,
    "last_reset" TIMESTAMPTZ,
    "estimated_saved_amount" DECIMAL(15,2) DEFAULT 0,
    "daily_bet_average" DECIMAL(15,2) DEFAULT 0,
    "updated_at" TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =====================================================
-- INDICES PARA MEJOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_budgets_user ON budgets(user_id);
CREATE INDEX idx_alerts_user_read ON alerts(user_id, is_read);
CREATE INDEX idx_funds_user ON funds(user_id);
CREATE INDEX idx_goals_user ON financial_goals(user_id);
CREATE INDEX idx_loans_user ON loans(user_id);
CREATE INDEX idx_metrics_user_date ON metrics(user_id, date);
CREATE INDEX idx_blocked_apps_user ON blocked_apps(user_id);
CREATE INDEX idx_blocked_domains_user ON blocked_domains(user_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE abstinence_tracker ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLICIES - Cada usuario solo ve sus datos
-- =====================================================

-- Users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories
CREATE POLICY "Users can view own categories" ON categories
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "Users can insert own categories" ON categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own categories" ON categories
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own categories" ON categories
    FOR DELETE USING (auth.uid() = user_id);

-- Funds
CREATE POLICY "Users can view own funds" ON funds
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own funds" ON funds
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own funds" ON funds
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own funds" ON funds
    FOR DELETE USING (auth.uid() = user_id);

-- Transactions
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own transactions" ON transactions
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own transactions" ON transactions
    FOR DELETE USING (auth.uid() = user_id);

-- Budgets
CREATE POLICY "Users can view own budgets" ON budgets
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budgets" ON budgets
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budgets" ON budgets
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budgets" ON budgets
    FOR DELETE USING (auth.uid() = user_id);

-- Financial Goals
CREATE POLICY "Users can view own goals" ON financial_goals
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON financial_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON financial_goals
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own goals" ON financial_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Loans
CREATE POLICY "Users can view own loans" ON loans
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own loans" ON loans
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own loans" ON loans
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own loans" ON loans
    FOR DELETE USING (auth.uid() = user_id);

-- Alerts
CREATE POLICY "Users can view own alerts" ON alerts
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own alerts" ON alerts
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own alerts" ON alerts
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own alerts" ON alerts
    FOR DELETE USING (auth.uid() = user_id);

-- Metrics
CREATE POLICY "Users can view own metrics" ON metrics
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own metrics" ON metrics
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own metrics" ON metrics
    FOR UPDATE USING (auth.uid() = user_id);

-- Blocked Apps
CREATE POLICY "Users can view own blocked apps" ON blocked_apps
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own blocked apps" ON blocked_apps
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own blocked apps" ON blocked_apps
    FOR DELETE USING (auth.uid() = user_id);

-- Blocked Domains
CREATE POLICY "Users can view own blocked domains" ON blocked_domains
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own blocked domains" ON blocked_domains
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own blocked domains" ON blocked_domains
    FOR DELETE USING (auth.uid() = user_id);

-- Abstinence Tracker
CREATE POLICY "Users can view own tracker" ON abstinence_tracker
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tracker" ON abstinence_tracker
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tracker" ON abstinence_tracker
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- CATEGORIAS POR DEFECTO
-- =====================================================

INSERT INTO categories (user_id, name, type, icon, color, is_default) VALUES
(NULL, 'Alimentacion', 'expense', 'restaurant', '#EF4444', true),
(NULL, 'Transporte', 'expense', 'directions_car', '#F59E0B', true),
(NULL, 'Entretenimiento', 'expense', 'movie', '#8B5CF6', true),
(NULL, 'Compras', 'expense', 'shopping_bag', '#EC4899', true),
(NULL, 'Salud', 'expense', 'medical_services', '#10B981', true),
(NULL, 'Educacion', 'expense', 'school', '#3B82F6', true),
(NULL, 'Servicios', 'expense', 'receipt', '#6366F1', true),
(NULL, 'Otros', 'expense', 'more_horiz', '#6B7280', true),
(NULL, 'Salario', 'income', 'payments', '#10B981', true),
(NULL, 'Inversiones', 'income', 'trending_up', '#3B82F6', true),
(NULL, 'Regalo', 'income', 'card_giftcard', '#EC4899', true),
(NULL, 'Otros ingresos', 'income', 'more_horiz', '#6B7280', true);

-- =====================================================
-- TRIGGER: Crear perfil automaticamente al registrarse
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    NEW.email,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger si existe y recrear
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- FIN DEL SCHEMA
-- =====================================================
