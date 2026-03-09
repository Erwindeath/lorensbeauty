# Configuración de Storage para Imágenes

## Pasos para Configurar Storage en Supabase

### 1. Ejecutar el Script SQL

1. Ve a tu proyecto en Supabase Dashboard
2. Navega a **SQL Editor**
3. Abre el archivo `storage_buckets_setup.sql`
4. Copia y pega el contenido completo
5. Haz clic en **Run** para ejecutar el script

Esto creará:
- ✅ Bucket `products` para imágenes de productos
- ✅ Bucket `services` para imágenes de servicios
- ✅ Políticas de acceso público (lectura)
- ✅ Políticas de autenticación (escritura)

### 2. Verificar la Configuración

#### En Supabase Dashboard:
1. Ve a **Storage** en el menú lateral
2. Deberías ver dos buckets:
   - `products`
   - `services`
3. Ambos deben tener el icono de "público" (ojo abierto)

#### Verificar Políticas:
```sql
-- Ejecutar en SQL Editor para verificar
SELECT * FROM storage.buckets WHERE id IN ('products', 'services');

SELECT * FROM pg_policies
WHERE tablename = 'objects'
AND (policyname LIKE '%product%' OR policyname LIKE '%service%');
```

### 3. Instalar Dependencias en Flutter

Ejecuta en la terminal del proyecto:

```bash
flutter pub get
```

Esto instalará:
- `image_picker: ^1.0.7` - Para seleccionar imágenes
- `image_cropper: ^5.0.1` - Para recortar imágenes

### 4. Configuración Adicional (Opcional)

#### Android (android/app/src/main/AndroidManifest.xml)
Ya debería estar configurado, pero verifica que tengas:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS (ios/Runner/Info.plist)
Ya debería estar configurado, pero verifica que tengas:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos de productos/servicios</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a la galería para seleccionar fotos</string>
```

## Cómo Usar la Funcionalidad

### Subir Imágenes a Productos

1. Ve a **Admin → Productos**
2. **Crear** un nuevo producto o **Editar** uno existente
3. Guarda el producto primero
4. Verás la sección "Fotos del Producto"
5. Toca el botón **"Agregar Foto"**
6. Selecciona **Galería** o **Cámara**
7. Recorta la imagen como desees
8. La imagen se subirá automáticamente

### Subir Imágenes a Servicios

1. Ve a **Admin → Servicios**
2. **Crear** un nuevo servicio o **Editar** uno existente
3. Guarda el servicio primero
4. Verás la sección "Fotos del Servicio"
5. Toca el botón **"Agregar Foto"**
6. Selecciona **Galería** o **Cámara**
7. Recorta la imagen como desees
8. La imagen se subirá automáticamente

## Características Implementadas

✅ **Selección de Fuente**
- Galería
- Cámara

✅ **Recorte de Imagen**
- Múltiples relaciones de aspecto (cuadrado, 3:2, 4:3, 16:9)
- Interfaz personalizada con colores de la app

✅ **Optimización**
- Compresión automática (85% calidad)
- Tamaño máximo: 1920x1920px
- Caché de imágenes en memoria y disco

✅ **Gestión**
- Ver todas las fotos de un producto/servicio
- Eliminar fotos
- Múltiples fotos por producto/servicio

## Estructura de URLs

Las imágenes se guardarán con este formato:

### Productos:
```
https://[tu-proyecto].supabase.co/storage/v1/object/public/products/product_[ID]_[timestamp].jpg
```

### Servicios:
```
https://[tu-proyecto].supabase.co/storage/v1/object/public/services/service_[ID]_[timestamp].jpg
```

## Solución de Problemas

### Error: "Unable to upload image"
- Verifica que ejecutaste el script SQL
- Verifica que los buckets existan en Storage
- Verifica que estés autenticado

### Error: "Permission denied"
- Verifica las políticas de Storage
- Verifica que el usuario tenga un token válido

### La imagen no se muestra
- Verifica que la URL esté correcta
- Verifica que el bucket sea público
- Limpia el caché: `flutter clean && flutter pub get`

## Mantenimiento

### Limpiar Imágenes Huérfanas
Si eliminas productos/servicios, las imágenes quedarán en Storage. Para limpiar:

```sql
-- Listar archivos en products bucket
SELECT * FROM storage.objects WHERE bucket_id = 'products';

-- Listar archivos en services bucket
SELECT * FROM storage.objects WHERE bucket_id = 'services';

-- Eliminar archivo específico (ejecutar desde SQL Editor)
SELECT storage.objects.delete('products', 'nombre_archivo.jpg');
```

### Límites de Storage
- **Free tier**: 1 GB
- **Pro**: 100 GB
- Verifica tu uso en Supabase Dashboard → Settings → Usage
