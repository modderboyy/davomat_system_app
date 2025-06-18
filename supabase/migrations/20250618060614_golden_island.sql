/*
  # Admin Panel uchun kerakli jadvallar va tuzatishlar

  1. Yangi jadvallar
    - `details` - billing ma'lumotlari uchun
    - `updates` - dastur yangilanishlari uchun
    
  2. Mavjud jadvallarni yangilash
    - `companies` jadvaliga yangi columnlar qo'shish
    - `davomat` jadvaliga kechikish ma'lumotlari
    
  3. Xavfsizlik
    - RLS yoqish
    - Kerakli policylar qo'shish
*/

-- 1. Details jadvali yaratish (billing ma'lumotlari uchun)
CREATE TABLE IF NOT EXISTS details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  balance decimal(10,2) DEFAULT 0.00,
  free_employee_limit integer DEFAULT 5,
  cost_per_extra_employee decimal(10,2) DEFAULT 10.00,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Updates jadvali yaratish (dastur yangilanishlari uchun)
CREATE TABLE IF NOT EXISTS updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version_number text NOT NULL,
  update_link text NOT NULL,
  release_notes text,
  is_mandatory boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 3. Companies jadvaliga yangi columnlar qo'shish
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS logo_url text,
ADD COLUMN IF NOT EXISTS kelish_vaqti time DEFAULT '09:00:00',
ADD COLUMN IF NOT EXISTS ketish_vaqti time DEFAULT '18:00:00',
ADD COLUMN IF NOT EXISTS hisobsiz_vaqt integer DEFAULT 15; -- minutlarda

-- 4. Davomat jadvaliga kechikish ma'lumotlari
ALTER TABLE davomat
ADD COLUMN IF NOT EXISTS kechikish_minut integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS status text DEFAULT 'kelgan' CHECK (status IN ('kelgan', 'kelmagan', 'kechikkan'));

-- 5. RLS yoqish
ALTER TABLE details ENABLE ROW LEVEL SECURITY;
ALTER TABLE updates ENABLE ROW LEVEL SECURITY;

-- 6. Details uchun policylar
CREATE POLICY "Companies can view own details"
  ON details
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage details"
  ON details
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND is_super_admin = true
    )
  );

-- 7. Updates uchun policylar
CREATE POLICY "Everyone can view updates"
  ON updates
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only super admins can manage updates"
  ON updates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND is_super_admin = true
    )
  );

-- 8. Har bir kompaniya uchun details yaratish
INSERT INTO details (company_id, balance, free_employee_limit, cost_per_extra_employee)
SELECT 
  id,
  1000.00, -- boshlang'ich balans
  5,       -- bepul xodimlar soni
  10.00    -- qo'shimcha xodim narxi
FROM companies
WHERE id NOT IN (SELECT company_id FROM details WHERE company_id IS NOT NULL)
ON CONFLICT DO NOTHING;

-- 9. Davomat statusini yangilash funksiyasi
CREATE OR REPLACE FUNCTION update_attendance_status()
RETURNS trigger AS $$
DECLARE
  company_settings record;
  arrival_time time;
  late_minutes integer;
BEGIN
  -- Kompaniya sozlamalarini olish
  SELECT kelish_vaqti, hisobsiz_vaqt 
  INTO company_settings
  FROM companies 
  WHERE id = NEW.company_id;
  
  -- Kelish vaqtini olish
  arrival_time := NEW.kelish_vaqti::time;
  
  -- Kechikish minutlarini hisoblash
  late_minutes := EXTRACT(EPOCH FROM (arrival_time - company_settings.kelish_vaqti)) / 60;
  
  -- Status va kechikish minutlarini belgilash
  IF late_minutes <= company_settings.hisobsiz_vaqt THEN
    NEW.status := 'kelgan';
    NEW.kechikish_minut := 0;
  ELSE
    NEW.status := 'kechikkan';
    NEW.kechikish_minut := late_minutes;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. Trigger yaratish
DROP TRIGGER IF EXISTS attendance_status_trigger ON davomat;
CREATE TRIGGER attendance_status_trigger
  BEFORE INSERT OR UPDATE ON davomat
  FOR EACH ROW
  EXECUTE FUNCTION update_attendance_status();

-- 11. Storage bucket yaratish (agar yo'q bo'lsa)
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- 12. Storage policy
CREATE POLICY "Company logos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = 'company_logo');

CREATE POLICY "Authenticated users can upload company logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'photos' AND (storage.foldername(name))[1] = 'company_logo');

CREATE POLICY "Users can update own company logo"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = 'company_logo');

CREATE POLICY "Users can delete own company logo"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'photos' AND (storage.foldername(name))[1] = 'company_logo');