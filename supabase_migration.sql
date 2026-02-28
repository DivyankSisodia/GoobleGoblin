-- ============================================================
-- GoobleGoblin - Supabase Database Migration
-- Run this SQL in your Supabase SQL Editor to set up the remote tables
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  label TEXT NOT NULL,
  icon TEXT,
  asset_path TEXT,
  is_predefined BOOLEAN DEFAULT TRUE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_uuid ON categories(uuid);
CREATE INDEX idx_categories_updated_at ON categories(updated_at);

-- ============================================================
-- CARDS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS cards (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  bank_name TEXT NOT NULL,
  balance DOUBLE PRECISION NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  account_type TEXT DEFAULT 'DEBIT',
  credit_limit DOUBLE PRECISION DEFAULT 0,
  used_amount DOUBLE PRECISION DEFAULT 0,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cards_uuid ON cards(uuid);
CREATE INDEX idx_cards_updated_at ON cards(updated_at);
CREATE INDEX idx_cards_account_type ON cards(account_type);

-- ============================================================
-- PAYMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  amount DOUBLE PRECISION NOT NULL,
  date TEXT NOT NULL,
  card_uuid UUID REFERENCES cards(uuid) ON DELETE SET NULL,
  category_uuid UUID REFERENCES categories(uuid) ON DELETE SET NULL,
  is_recurring BOOLEAN DEFAULT FALSE,
  frequency TEXT,
  reminder_notification BOOLEAN DEFAULT FALSE,
  note TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_uuid ON payments(uuid);
CREATE INDEX idx_payments_updated_at ON payments(updated_at);
CREATE INDEX idx_payments_card_uuid ON payments(card_uuid);
CREATE INDEX idx_payments_category_uuid ON payments(category_uuid);
CREATE INDEX idx_payments_date ON payments(date);

-- ============================================================
-- WISHLIST TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS wishlist (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  url TEXT NOT NULL,
  title TEXT,
  image_url TEXT,
  price DOUBLE PRECISION,
  notes TEXT,
  date_added TEXT NOT NULL,
  is_purchased BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wishlist_uuid ON wishlist(uuid);
CREATE INDEX idx_wishlist_updated_at ON wishlist(updated_at);

-- ============================================================
-- APP SETTINGS TABLE  
-- ============================================================
CREATE TABLE IF NOT EXISTS app_settings (
  id BIGSERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cards_updated_at
  BEFORE UPDATE ON cards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishlist_updated_at
  BEFORE UPDATE ON wishlist
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at
  BEFORE UPDATE ON app_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ROW LEVEL SECURITY (Optional - enable if using Supabase Auth)
-- Uncomment below if you want per-user data isolation
-- ============================================================

-- ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (requires adding a user_id column to each table):
-- CREATE POLICY "Users can view own categories" ON categories
--   FOR SELECT USING (auth.uid() = user_id);
-- CREATE POLICY "Users can insert own categories" ON categories
--   FOR INSERT WITH CHECK (auth.uid() = user_id);
-- CREATE POLICY "Users can update own categories" ON categories
--   FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================
-- REALTIME (Optional - enable for live sync)
-- ============================================================

-- Enable realtime for tables
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE cards;
ALTER PUBLICATION supabase_realtime ADD TABLE payments;
ALTER PUBLICATION supabase_realtime ADD TABLE wishlist;
