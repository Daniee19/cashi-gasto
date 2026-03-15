-- ============================================
-- CASHI GASTO - Database Schema
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. USERS (extiende auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    profile_photo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 2. FUNDS (cajones de dinero)
CREATE TABLE IF NOT EXISTS public.funds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    bank DECIMAL(12,2) DEFAULT 0 NOT NULL,
    cash DECIMAL(12,2) DEFAULT 0 NOT NULL,
    saving DECIMAL(12,2) DEFAULT 0 NOT NULL,
    UNIQUE(user_id)
);

-- 3. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    transaction_category TEXT NOT NULL CHECK (transaction_category IN ('income', 'expense'))
);

-- 4. TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    fund_id UUID NOT NULL REFERENCES public.funds(id) ON DELETE RESTRICT,
    amount DECIMAL(12,2) NOT NULL,
    transaction_method TEXT NOT NULL DEFAULT 'manual' CHECK (transaction_method IN ('manual', 'ocr', 'sms')),
    transaction_date TIMESTAMPTZ NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 5. BUDGETS
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    period TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    amount_budgeted DECIMAL(12,2) NOT NULL
);

-- 6. ALERTS
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL,
    message TEXT NOT NULL,
    alert_date TIMESTAMPTZ NOT NULL
);

-- 7. LOANS (préstamos)
CREATE TABLE IF NOT EXISTS public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    limit_date TIMESTAMPTZ NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    receiver TEXT NOT NULL,
    description TEXT,
    loan_type TEXT NOT NULL CHECK (loan_type IN ('given', 'received'))
);

-- 8. BLOCKED_DOMAINS (para ayuda con ludopatía)
CREATE TABLE IF NOT EXISTS public.blocked_domains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    url TEXT NOT NULL
);

-- 9. METRICS (agregaciones mensuales)
CREATE TABLE IF NOT EXISTS public.metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    period_date TIMESTAMPTZ NOT NULL,
    total_income DECIMAL(12,2) DEFAULT 0 NOT NULL,
    total_expense DECIMAL(12,2) DEFAULT 0 NOT NULL,
    savings DECIMAL(12,2) DEFAULT 0 NOT NULL,
    transactions_count INTEGER DEFAULT 0 NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, period_date)
);

-- ============================================
-- ÍNDICES para mejor rendimiento
-- ============================================

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_metrics_user_period ON public.metrics(user_id, period_date);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metrics ENABLE ROW LEVEL SECURITY;

-- Políticas para USERS
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Políticas para FUNDS
CREATE POLICY "Users can view own funds" ON public.funds
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own funds" ON public.funds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own funds" ON public.funds
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para CATEGORIES
CREATE POLICY "Users can manage own categories" ON public.categories
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para TRANSACTIONS
CREATE POLICY "Users can manage own transactions" ON public.transactions
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para BUDGETS
CREATE POLICY "Users can manage own budgets" ON public.budgets
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para ALERTS
CREATE POLICY "Users can manage own alerts" ON public.alerts
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para LOANS
CREATE POLICY "Users can manage own loans" ON public.loans
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para BLOCKED_DOMAINS
CREATE POLICY "Users can manage own blocked domains" ON public.blocked_domains
    FOR ALL USING (auth.uid() = user_id);

-- Políticas para METRICS
CREATE POLICY "Users can manage own metrics" ON public.metrics
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- CATEGORÍAS PREDETERMINADAS (función)
-- ============================================

-- Función para crear categorías por defecto al registrar usuario
CREATE OR REPLACE FUNCTION public.create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Categorías de ingreso
    INSERT INTO public.categories (user_id, name, description, transaction_category) VALUES
        (NEW.id, 'Salario', 'Ingresos por trabajo', 'income'),
        (NEW.id, 'Freelance', 'Trabajos independientes', 'income'),
        (NEW.id, 'Inversiones', 'Rendimientos de inversiones', 'income'),
        (NEW.id, 'Regalos', 'Dinero recibido como regalo', 'income'),
        (NEW.id, 'Otros ingresos', 'Otros tipos de ingresos', 'income');

    -- Categorías de gasto
    INSERT INTO public.categories (user_id, name, description, transaction_category) VALUES
        (NEW.id, 'Alimentación', 'Comida y bebidas', 'expense'),
        (NEW.id, 'Transporte', 'Movilidad y combustible', 'expense'),
        (NEW.id, 'Entretenimiento', 'Ocio y diversión', 'expense'),
        (NEW.id, 'Servicios', 'Agua, luz, internet, etc.', 'expense'),
        (NEW.id, 'Salud', 'Medicinas y consultas', 'expense'),
        (NEW.id, 'Educación', 'Cursos y materiales', 'expense'),
        (NEW.id, 'Ropa', 'Vestimenta y accesorios', 'expense'),
        (NEW.id, 'Hogar', 'Artículos para el hogar', 'expense'),
        (NEW.id, 'Otros gastos', 'Gastos varios', 'expense');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear categorías cuando se crea un usuario
CREATE TRIGGER on_user_created_categories
    AFTER INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.create_default_categories();

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
