import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// MODELOS DE DATOS
// ============================================

class OrderService {
  final int id;
  final int orderId;
  final int serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDuration; // en minutos
  final String status; // pending, in_progress, completed
  final String? employeeId;
  final DateTime? startedAt;
  final DateTime? completedAt;

  OrderService({
    required this.id,
    required this.orderId,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    this.status = 'pending',
    this.employeeId,
    this.startedAt,
    this.completedAt,
  });

  factory OrderService.fromJson(Map<String, dynamic> json) {
    return OrderService(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      servicePrice: (json['service_price'] as num).toDouble(),
      serviceDuration: json['service_duration'] as int,
      status: (json['status'] as String?) ?? 'pending',
      employeeId: json['employee_id'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'service_id': serviceId,
      'service_name': serviceName,
      'service_price': servicePrice,
      'service_duration': serviceDuration,
      'status': status,
      'employee_id': employeeId,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  String get formattedPrice => '\$${servicePrice.toStringAsFixed(2)}';

  String get formattedDuration {
    if (serviceDuration < 60) {
      return '$serviceDuration min';
    }
    final hours = serviceDuration ~/ 60;
    final minutes = serviceDuration % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h ${minutes}min';
  }
}

class Order {
  final int id;
  final String userId;
  final DateTime orderDate;
  final String orderTime; // TIME como string "HH:mm:ss"
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final double totalPrice;
  final int totalDuration; // en minutos
  final DateTime? startTime;
  final DateTime? endTime;
  final int? actualDuration; // en minutos
  final String? employeeId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderService> services;

  Order({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.orderTime,
    required this.status,
    required this.totalPrice,
    required this.totalDuration,
    this.startTime,
    this.endTime,
    this.actualDuration,
    this.employeeId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.services = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parsear servicios si vienen incluidos
    List<OrderService> servicesList = [];
    if (json['order_services'] != null) {
      servicesList = (json['order_services'] as List)
          .map((s) => OrderService.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      orderTime: json['order_time'] as String,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      totalDuration: json['total_duration'] as int,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      actualDuration: json['actual_duration'] as int?,
      employeeId: json['employee_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      services: servicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'order_time': orderTime,
      'status': status,
      'total_price': totalPrice,
      'total_duration': totalDuration,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'actual_duration': actualDuration,
      'employee_id': employeeId,
      'notes': notes,
    };
  }

  // Formateo de datos
  String get formattedPrice => '\$${totalPrice.toStringAsFixed(2)}';

  String get formattedDuration {
    if (totalDuration < 60) {
      return '$totalDuration min';
    }
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h ${minutes}min';
  }

  String get formattedDate {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

    return '${days[orderDate.weekday % 7]} ${orderDate.day} ${months[orderDate.month - 1]}';
  }

  String get formattedTime {
    // Convertir "HH:mm:ss" a "HH:mm AM/PM"
    final parts = orderTime.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }

  // Estado visual
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'pending':
        return '🟡';
      case 'confirmed':
        return '🟢';
      case 'in_progress':
        return '🔵';
      case 'completed':
        return '✅';
      case 'cancelled':
        return '❌';
      default:
        return '⚪';
    }
  }

  // QR Code data - simplemente el ID
  String get qrData => id.toString();
}

// ============================================
// PROVIDERS
// ============================================

/// Provider para obtener órdenes del usuario actual
final userOrdersProvider = StreamProvider<List<Order>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final stream = Supabase.instance.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('order_date', ascending: false)
      .order('order_time', ascending: false);

  return stream.asyncMap((data) async {
    // Para cada orden, obtener sus servicios
    List<Order> orders = [];
    for (var orderJson in data) {
      final orderId = orderJson['id'] as int;

      // Obtener servicios de esta orden
      final servicesData = await Supabase.instance.client
          .from('order_services')
          .select()
          .eq('order_id', orderId);

      orderJson['order_services'] = servicesData;
      orders.add(Order.fromJson(orderJson));
    }
    return orders;
  });
});

/// Provider para obtener una orden específica por ID
final orderByIdProvider = FutureProvider.family<Order?, int>((ref, orderId) async {
  try {
    final orderData = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    final servicesData = await Supabase.instance.client
        .from('order_services')
        .select()
        .eq('order_id', orderId);

    orderData['order_services'] = servicesData;
    return Order.fromJson(orderData);
  } catch (e) {
    return null;
  }
});

/// Provider para órdenes de empleados (todas las órdenes del día)
final employeeOrdersProvider = StreamProvider<List<Order>>((ref) {
  final today = DateTime.now();
  final todayStr = today.toIso8601String().split('T')[0];

  final stream = Supabase.instance.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .gte('order_date', todayStr)
      .order('order_time', ascending: true);

  return stream.asyncMap((data) async {
    List<Order> orders = [];
    for (var orderJson in data) {
      // Filtrar por status aquí
      final status = orderJson['status'] as String;
      if (status != 'confirmed' && status != 'in_progress') continue;

      final orderId = orderJson['id'] as int;

      final servicesData = await Supabase.instance.client
          .from('order_services')
          .select()
          .eq('order_id', orderId);

      orderJson['order_services'] = servicesData;
      orders.add(Order.fromJson(orderJson));
    }
    return orders;
  });
});

// ============================================
// FUNCIONES HELPER
// ============================================

/// Crear una nueva orden
Future<Order?> createOrder({
  required DateTime orderDate,
  required String orderTime,
  required double totalPrice,
  required int totalDuration,
  required List<Map<String, dynamic>> services,
  String? notes,
}) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // 1. Crear la orden
    final orderData = {
      'user_id': userId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      'order_time': orderTime,
      'status': 'confirmed',
      'total_price': totalPrice,
      'total_duration': totalDuration,
      if (notes != null) 'notes': notes,
    };

    final orderResponse = await Supabase.instance.client
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    final orderId = orderResponse['id'] as int;

    // 2. Insertar servicios de la orden
    final orderServicesData = services.map((service) {
      return {
        'order_id': orderId,
        'service_id': service['service_id'],
        'service_name': service['service_name'],
        'service_price': service['service_price'],
        'service_duration': service['service_duration'],
      };
    }).toList();

    await Supabase.instance.client
        .from('order_services')
        .insert(orderServicesData);

    // 3. Obtener la orden completa con servicios
    final fullOrderData = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    final servicesData = await Supabase.instance.client
        .from('order_services')
        .select()
        .eq('order_id', orderId);

    fullOrderData['order_services'] = servicesData;
    return Order.fromJson(fullOrderData);
  } catch (e) {
    print('Error creando orden: $e');
    return null;
  }
}

/// Cancelar una orden (solo si está en pending o confirmed)
Future<bool> cancelOrder(int orderId) async {
  try {
    // Primero verificar el status actual
    final order = await Supabase.instance.client
        .from('orders')
        .select('status')
        .eq('id', orderId)
        .single();

    final currentStatus = order['status'] as String;
    if (currentStatus != 'pending' && currentStatus != 'confirmed') {
      return false; // No se puede cancelar
    }

    await Supabase.instance.client
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId);
    return true;
  } catch (e) {
    print('Error cancelando orden: $e');
    return false;
  }
}

/// Iniciar servicio (empleado escanea QR)
Future<bool> startOrder(int orderId, String employeeId) async {
  try {
    await Supabase.instance.client
        .from('orders')
        .update({
          'status': 'in_progress',
          'start_time': DateTime.now().toIso8601String(),
          'employee_id': employeeId,
        })
        .eq('id', orderId);
    return true;
  } catch (e) {
    print('Error iniciando orden: $e');
    return false;
  }
}

/// Completar servicio
Future<bool> completeOrder(int orderId) async {
  try {
    await Supabase.instance.client
        .from('orders')
        .update({
          'status': 'completed',
          'end_time': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
    // El trigger calculará actual_duration automáticamente
    return true;
  } catch (e) {
    print('Error completando orden: $e');
    return false;
  }
}

/// Iniciar un servicio puntual dentro de una orden (si la tabla lo soporta)
Future<bool> startOrderService({
  required int orderId,
  required int orderServiceId,
  required String employeeId,
}) async {
  try {
    final current = await Supabase.instance.client
        .from('order_services')
        .select('status,employee_id')
        .eq('id', orderServiceId)
        .eq('order_id', orderId)
        .maybeSingle();

    if (current == null) return false;

    final status = (current['status']?.toString() ?? 'pending').toLowerCase();
    final currentEmployeeId = current['employee_id']?.toString();

    if (status == 'completed') return false;
    if (status == 'in_progress') {
      if (currentEmployeeId == null || currentEmployeeId == employeeId) {
        return true;
      }
      return false;
    }

    await Supabase.instance.client
        .from('order_services')
        .update({
          'status': 'in_progress',
          'employee_id': employeeId,
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderServiceId)
        .eq('order_id', orderId);

    await _syncOrderStatusFromServices(orderId, employeeId);
    return true;
  } catch (e) {
    print('Error iniciando servicio individual: $e');
    return false;
  }
}

/// Completar un servicio puntual dentro de una orden (si la tabla lo soporta)
Future<bool> completeOrderService({
  required int orderId,
  required int orderServiceId,
  required String employeeId,
}) async {
  try {
    final current = await Supabase.instance.client
        .from('order_services')
        .select('status,employee_id')
        .eq('id', orderServiceId)
        .eq('order_id', orderId)
        .maybeSingle();

    if (current == null) return false;

    final status = (current['status']?.toString() ?? 'pending').toLowerCase();
    final currentEmployeeId = current['employee_id']?.toString();

    if (status == 'completed') return true;
    if (status != 'in_progress') return false;
    if (currentEmployeeId != null && currentEmployeeId != employeeId) return false;

    await Supabase.instance.client
        .from('order_services')
        .update({
          'status': 'completed',
          'employee_id': employeeId,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderServiceId)
        .eq('order_id', orderId);

    await _syncOrderStatusFromServices(orderId, employeeId);
    return true;
  } catch (e) {
    print('Error completando servicio individual: $e');
    return false;
  }
}

Future<void> _syncOrderStatusFromServices(int orderId, String employeeId) async {
  try {
    final rows = await Supabase.instance.client
        .from('order_services')
        .select('status,started_at,completed_at')
        .eq('order_id', orderId);

    if ((rows as List).isEmpty) return;

    final order = await Supabase.instance.client
        .from('orders')
        .select('start_time,end_time')
        .eq('id', orderId)
        .single();

    final statuses = <String>[];
    DateTime? firstStartedAt;
    DateTime? lastCompletedAt;
    for (final row in rows) {
      final status = (row['status']?.toString() ?? 'pending').toLowerCase();
      statuses.add(status);

      final startedAtRaw = row['started_at']?.toString();
      if (startedAtRaw != null) {
        final startedAt = DateTime.tryParse(startedAtRaw);
        if (startedAt != null &&
            (firstStartedAt == null || startedAt.isBefore(firstStartedAt))) {
          firstStartedAt = startedAt;
        }
      }

      final completedAtRaw = row['completed_at']?.toString();
      if (completedAtRaw != null) {
        final completedAt = DateTime.tryParse(completedAtRaw);
        if (completedAt != null &&
            (lastCompletedAt == null || completedAt.isAfter(lastCompletedAt))) {
          lastCompletedAt = completedAt;
        }
      }
    }

    final allCompleted = statuses.every((s) => s == 'completed');
    final anyInProgress = statuses.any((s) => s == 'in_progress');
    final anyCompleted = statuses.any((s) => s == 'completed');

    final startTimeRaw = order['start_time']?.toString();
    final existingStartTime =
        startTimeRaw != null ? DateTime.tryParse(startTimeRaw) : null;

    if (allCompleted) {
      final effectiveStart = existingStartTime ?? firstStartedAt ?? DateTime.now();
      final effectiveEnd = lastCompletedAt ?? DateTime.now();
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'completed',
            'start_time': effectiveStart.toIso8601String(),
            'end_time': effectiveEnd.toIso8601String(),
          })
          .eq('id', orderId);
      return;
    }

    if (anyInProgress || anyCompleted) {
      final effectiveStart = existingStartTime ?? firstStartedAt ?? DateTime.now();
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'in_progress',
            'employee_id': employeeId,
            'start_time': effectiveStart.toIso8601String(),
            'end_time': null,
          })
          .eq('id', orderId);
    }
  } catch (e) {
    print('Error sincronizando estado de orden: $e');
  }
}
