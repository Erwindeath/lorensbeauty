import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// MODELOS DE DATOS
// ============================================

class ServiceCategory {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final String colorHex;
  final int displayOrder;
  final bool isActive;
  final int servicesCount;
  ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex = '#721c80',
    this.displayOrder = 0,
    this.isActive = true,
    this.servicesCount = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String? ?? '#721c80',
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      servicesCount: json['services_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

class ServicePhoto {
  final int id;
  final int serviceId;
  final String photoUrl;
  final String? caption;
  final DateTime uploadedAt;

  ServicePhoto({
    required this.id,
    required this.serviceId,
    required this.photoUrl,
    this.caption,
    required this.uploadedAt,
  });

  factory ServicePhoto.fromJson(Map<String, dynamic> json) {
    return ServicePhoto(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      photoUrl: json['photo_url'] as String,
      caption: json['caption'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}

class Service {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String? img;
  final bool isActive;
  final String? categoryName;
  final List<ServicePhoto> photos;

  Service({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.img,
    this.isActive = true,
    this.categoryName,
    this.photos = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    List<ServicePhoto> photosList = [];
    if (json['photos'] != null) {
      photosList = (json['photos'] as List)
          .map((photoJson) => ServicePhoto.fromJson(photoJson))
          .toList();
    }

    return Service(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      img: json['img'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      categoryName: json['category_name'] as String?,
      photos: photosList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'img': img,
      'is_active': isActive,
    };
  }

  // Formatear precio para mostrar
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  // Formatear duración para mostrar
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h ${minutes}min';
  }

  // Helpers para fotos
  bool get hasPhotos => photos.isNotEmpty;
  String get firstPhotoUrl => hasPhotos ? photos.first.photoUrl : '';
}

// ============================================
// PROVIDERS
// ============================================

/// Provider para obtener todas las categorías activas
final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  try {
    final categories = await Supabase.instance.client
        .from('service_categories')
        .select()
        .eq('is_active', true)
        .order('display_order');

    final services = await Supabase.instance.client
        .from('services')
        .select('id, category_id')
        .eq('is_active', true);

    final countByCategory = <int, int>{};
    for (final service in services) {
      final categoryId = service['category_id'] as int?;
      if (categoryId == null) continue;
      countByCategory[categoryId] = (countByCategory[categoryId] ?? 0) + 1;
    }

    final categoriesWithCount = <ServiceCategory>[];
    for (var categoryJson in categories) {
      categoryJson['services_count'] = countByCategory[categoryJson['id']] ?? 0;
      categoriesWithCount.add(ServiceCategory.fromJson(categoryJson));
    }

    return categoriesWithCount;
  } catch (e) {
    print(e);
    return [];
  }
});

/// Provider para obtener todos los servicios activos
final allServicesProvider = StreamProvider<List<Service>>((ref) {
  final stream = Supabase.instance.client
      .from('services')
      .stream(primaryKey: ['id'])
      .order('name');

  return stream.map((data) {
    // Filtrar solo los activos
    return data
        .where((json) => json['is_active'] == true)
        .map((json) => Service.fromJson(json))
        .toList();
  });
});

/// Provider para obtener servicios por categoría
final servicesByCategoryProvider = StreamProvider.family<List<Service>, int>((ref, categoryId) {
  final stream = Supabase.instance.client
      .from('services')
      .stream(primaryKey: ['id'])
      .order('name');

  return stream.map((data) {
    // Filtrar por categoría y solo activos
    return data
        .where((json) => json['category_id'] == categoryId && json['is_active'] == true)
        .map((json) => Service.fromJson(json))
        .toList();
  });
});

/// State provider para la categoría seleccionada
final selectedCategoryProvider = StateProvider<ServiceCategory?>((ref) => null);

/// State provider para los servicios seleccionados (múltiples)
final selectedServicesProvider = StateProvider<List<Service>>((ref) => []);

/// Provider computado para calcular el total de servicios seleccionados
final selectedServicesTotalProvider = Provider<double>((ref) {
  final selectedServices = ref.watch(selectedServicesProvider);
  return selectedServices.fold(0.0, (sum, service) => sum + service.price);
});

/// Provider computado para calcular la duración total
final selectedServicesDurationProvider = Provider<int>((ref) {
  final selectedServices = ref.watch(selectedServicesProvider);
  return selectedServices.fold(0, (sum, service) => sum + service.durationMinutes);
});

/// Provider para formatear el total
final formattedTotalProvider = Provider<String>((ref) {
  final total = ref.watch(selectedServicesTotalProvider);
  return '\$${total.toStringAsFixed(2)}';
});

/// Provider para formatear la duración total
final formattedDurationProvider = Provider<String>((ref) {
  final totalMinutes = ref.watch(selectedServicesDurationProvider);
  if (totalMinutes < 60) {
    return '$totalMinutes min';
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours h';
  }
  return '$hours h ${minutes}min';
});

/// Foto principal por servicio (toma la primera por uploaded_at/id)
final servicePrimaryPhotosProvider = FutureProvider<Map<int, String>>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('services_photos')
        .select('service_id, photo_url, uploaded_at, id')
        .order('service_id')
        .order('uploaded_at')
        .order('id');

    final photoByService = <int, String>{};
    for (final row in rows as List) {
      final serviceId = row['service_id'] as int?;
      final photoUrl = row['photo_url'] as String?;
      if (serviceId == null || photoUrl == null || photoUrl.trim().isEmpty) {
        continue;
      }
      photoByService.putIfAbsent(serviceId, () => photoUrl);
    }
    return photoByService;
  } catch (_) {
    return {};
  }
});

// ============================================
// CRUD DE SERVICIOS
// ============================================

Future<int> createService({
  required String name,
  int? categoryId,
  String? description,
  required double price,
  required int durationMinutes,
  bool isActive = true,
}) async {
  final response = await Supabase.instance.client
      .from('services')
      .insert({
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
        'duration_minutes': durationMinutes,
        'is_active': isActive,
      })
      .select('id')
      .single();

  return response['id'] as int;
}

Future<void> updateService({
  required int serviceId,
  String? name,
  required int? categoryId,
  String? description,
  double? price,
  int? durationMinutes,
  bool? isActive,
}) async {
  final updates = <String, dynamic>{};

  if (name != null) updates['name'] = name;
  updates['category_id'] = categoryId;
  if (description != null) updates['description'] = description;
  if (price != null) updates['price'] = price;
  if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
  if (isActive != null) updates['is_active'] = isActive;

  await Supabase.instance.client.from('services').update(updates).eq('id', serviceId);
}

Future<void> deleteService(int serviceId) async {
  await Supabase.instance.client.from('services').delete().eq('id', serviceId);
}

// ============================================
// MÉTODOS HELPER
// ============================================

/// Toggle de selección de servicio
void toggleServiceSelection(WidgetRef ref, Service service) {
  final currentList = ref.read(selectedServicesProvider);
  final isSelected = currentList.any((s) => s.id == service.id);

  if (isSelected) {
    // Remover servicio
    ref.read(selectedServicesProvider.notifier).state =
        currentList.where((s) => s.id != service.id).toList();
  } else {
    // Agregar servicio
    ref.read(selectedServicesProvider.notifier).state = [...currentList, service];
  }
}

/// Verificar si un servicio está seleccionado
bool isServiceSelected(WidgetRef ref, Service service) {
  final selectedServices = ref.watch(selectedServicesProvider);
  return selectedServices.any((s) => s.id == service.id);
}

/// Limpiar selección
void clearSelectedServices(WidgetRef ref) {
  ref.read(selectedServicesProvider.notifier).state = [];
  ref.read(selectedCategoryProvider.notifier).state = null;
}

