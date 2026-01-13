-- ============================================
-- CONFIGURACIÓN DE BUCKETS DE STORAGE
-- ============================================
-- Ejecutar este script en Supabase SQL Editor

-- Crear bucket para imágenes de productos
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Crear bucket para imágenes de servicios
INSERT INTO storage.buckets (id, name, public)
VALUES ('services', 'services', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POLÍTICAS DE ACCESO (RLS)
-- ============================================

-- Política: Todos pueden ver las imágenes de productos
CREATE POLICY "Public Access for Products Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'products');

-- Política: Solo usuarios autenticados pueden subir imágenes de productos
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'products'
  AND auth.role() = 'authenticated'
);

-- Política: Solo usuarios autenticados pueden actualizar imágenes de productos
CREATE POLICY "Authenticated users can update product images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'products'
  AND auth.role() = 'authenticated'
);

-- Política: Solo usuarios autenticados pueden eliminar imágenes de productos
CREATE POLICY "Authenticated users can delete product images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'products'
  AND auth.role() = 'authenticated'
);

-- Política: Todos pueden ver las imágenes de servicios
CREATE POLICY "Public Access for Services Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'services');

-- Política: Solo usuarios autenticados pueden subir imágenes de servicios
CREATE POLICY "Authenticated users can upload service images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'services'
  AND auth.role() = 'authenticated'
);

-- Política: Solo usuarios autenticados pueden actualizar imágenes de servicios
CREATE POLICY "Authenticated users can update service images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'services'
  AND auth.role() = 'authenticated'
);

-- Política: Solo usuarios autenticados pueden eliminar imágenes de servicios
CREATE POLICY "Authenticated users can delete service images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'services'
  AND auth.role() = 'authenticated'
);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Verificar que los buckets se crearon correctamente
SELECT * FROM storage.buckets WHERE id IN ('products', 'services');

-- Verificar las políticas creadas
SELECT * FROM pg_policies
WHERE tablename = 'objects'
AND (policyname LIKE '%product%' OR policyname LIKE '%service%');
