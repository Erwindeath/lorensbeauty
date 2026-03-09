# Memoria de trabajo (admin + cliente + empleado)

## Estado actual general
- Admin:
  - Ajustes enlazado a `Horario de Atencion` (pantalla premium de bloques por dia).
  - Ajustes enlazado a `Gestion de Empleados`.
  - Gestion de servicios toma foto principal desde `services_photos`.
- Cliente:
  - Home refactorizado (CTA reserva, proxima cita, horario de hoy, servicios y productos destacados/nuevos).
  - Productos cliente refactorizado a catalogo directo con buscador + filtros por categoria.
  - Booking usa horarios configurados por admin por dia (`store_booking_slots`) y calendario en espanol.
  - Mis Reservas con flecha blanca y boton de QR con texto/icono blanco.
- Empleado:
  - QR escaner refactorizado para seleccionar uno o varios servicios de una orden.
  - Historial empleado refactorizado con filtros (todo/semana/mes), busqueda por cliente/servicio y detalle accionable.
  - Login corregido para no volver al login con boton atras del dispositivo.

## Cambios importantes (funcionales)
- `Authentication.signOut()` ya no recibe `context` (navegacion se hace en pantalla llamadora).
- `login_screen.dart` usa `pushAndRemoveUntil(..., (route) => false)` tras login.
- `RoleBasedNavigation` manda a `OnBoardingScreen` si no hay sesion/perfil valido (sin fallback a cliente).
- `booking_screen_new.dart`:
  - elimina slots fijos,
  - carga slots desde `store_booking_slots` por `weekday`,
  - refresca slots cuando cambia la fecha seleccionada.
- `date_piceker.dart`:
  - locale `es_ES`,
  - meses abreviados en espanol.

## Flujo multi-servicio por empleado
- `orders_provider.dart` ahora contempla en `OrderService`:
  - `status`, `employeeId`, `startedAt`, `completedAt`.
- Nuevas funciones:
  - `startOrderService(...)`
  - `completeOrderService(...)`
  - `_syncOrderStatusFromServices(...)`
- Fallback implementado:
  - si falla actualizacion por servicio (por schema antiguo), cae a flujo por orden completa (`startOrder/completeOrder`).

## SQL requerido en Supabase (ya indicado)
- Se deben tener estas columnas en `order_services`:
  - `status text default 'pending'`
  - `employee_id uuid references auth.users(id)`
  - `started_at timestamptz`
  - `completed_at timestamptz`
- Usuario confirmo que esas columnas fueron creadas.

## Archivos principales tocados
- `lib/components/role_based_navigation_admin.dart`
- `lib/components/role_based_navigation.dart`
- `lib/components/date_piceker.dart`
- `lib/screens/admin/settings/store_schedule_management_screen.dart`
- `lib/screens/admin/settings/admin_employees_management_screen.dart`
- `lib/screens/admin/services/services_management_screen.dart`
- `lib/screens/home/home_screen_improved.dart`
- `lib/screens/products/products_home_screen.dart`
- `lib/screens/booking/booking_screen_new.dart`
- `lib/screens/orders/my_orders_screen.dart`
- `lib/screens/orders/qr_scanner_screen.dart`
- `lib/screens/orders/employee_history_screen.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/providers/services_provider.dart`
- `lib/providers/orders_provider.dart`
- `lib/controller/auth_controller.dart`

## Notas
- Build de prueba generado con FVM:
  - `build/app/outputs/flutter-apk/app-debug.apk`
- Si hay comportamiento inesperado en empleado con multi-servicio, revisar que `order_services.status` se actualice en DB en tiempo real.

## Actualizacion reciente (flujo empleado/admin)
- Empleado:
  - `employee_history_screen.dart` ahora recarga `order_services` al abrir detalle (evita estado viejo).
  - Estado local del modal: al `Iniciar`/`Completar` se refleja instantaneamente sin cerrar.
  - Servicios `completed` bloqueados (no interactivos).
  - Servicios en progreso tomados por otro empleado bloqueados.
  - Acciones separadas en detalle: boton `Iniciar` y boton `Completar` (sin accion mixta ambigua).
- Provider ordenes:
  - `startOrderService`/`completeOrderService` ya no dependen de `update(...).select(...)`.
  - Validan estado actual previo y sincronizan `orders` por servicios.
  - `orders.start_time` se mantiene por primer inicio real y `orders.end_time` por ultimo completado.
- Admin:
  - Nueva pantalla: `lib/screens/admin/orders/admin_employee_activity_screen.dart`.
    - Vista por periodo (dia/semana/mes), filtro por empleado y busqueda.
    - Lista de servicios en proceso y actividad del periodo.
    - Desasignacion de servicios y resincronizacion de estado de la orden.
  - `AdminSettingsScreen` agrega acceso a `Operacion empleados`.
  - `AdminOrdersScreen` ahora:
    - cards con cliente, empleado y cantidad de servicios,
    - modal de detalle al tocar card (servicios, estado por servicio, empleado por servicio, notas),
    - accion `Desasignar servicio (rapido)` para ordenes en progreso.
  - Modal de desasignar muestra nombre del empleado asignado (no solo servicio).
  - Se reemplazo accion con `TextButton` por `GestureDetector` en desasignar rapido para evitar crash de InkSparkle en emulador.

## Importante
- Se elimino el fallback ambiguo de completar/iniciar por orden cuando falla por servicio en UI de empleado.
- Error compilacion corregido: `Colors.grey.shade250` -> `Colors.grey.shade300`.
