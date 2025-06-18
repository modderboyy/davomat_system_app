-- 1. Avval users jadvalining strukturasini tekshiramiz
-- Bu kodlarni Supabase SQL editor da ishga tushiring

-- Users jadvalida mavjud ma'lumotlarni ko'rish
SELECT id, email, full_name, xodim_id, company_id 
FROM users 
LIMIT 10;

-- Auth users va users o'rtasidagi bog'lanishni tekshirish
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    u.id as user_id,
    u.email as user_email,
    u.full_name
FROM auth.users au
LEFT JOIN users u ON au.id = u.id
WHERE au.id IS NOT NULL
LIMIT 10;

-- 2. Agar users jadvalida ma'lumot yo'q bo'lsa, quyidagi trigger yaratamiz
-- Bu trigger har safar yangi auth user yaratilganda avtomatik users jadvaliga ham qo'shadi

CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at)
  VALUES (new.id, new.email, new.created_at)
  ON CONFLICT (id) DO UPDATE SET
    email = excluded.email,
    updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger yaratish
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- 3. Mavjud auth.users uchun users jadvaliga ma'lumot qo'shish
INSERT INTO users (id, email, created_at)
SELECT 
    au.id,
    au.email,
    au.created_at
FROM auth.users au
LEFT JOIN users u ON au.id = u.id
WHERE u.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 4. Users jadvaliga kerakli columnlar qo'shish (agar yo'q bo'lsa)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS position TEXT,
ADD COLUMN IF NOT EXISTS profile_image TEXT,
ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 5. Updated_at uchun trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();