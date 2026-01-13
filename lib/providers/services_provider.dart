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
final serviceCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async{
  try {
    // Simular retardo para demostración
    await Future.delayed(const Duration(milliseconds: 500));
 
  final categories = await Supabase.instance.client
        .from('service_categories')
        .select()
        .eq('is_active', true)
        .order('display_order');
  List<ServiceCategory> categoriesWithCount = [];
    for (var categoryJson in categories) {
      final productsResponse = await Supabase.instance.client
          .from('services')
          .select()
          .eq('category_id', categoryJson['id'])
          .eq('is_active', true);

      categoryJson['services_count'] = productsResponse.length;
      categoriesWithCount.add(ServiceCategory.fromJson(categoryJson));
    }
  return categoriesWithCount;
}
  catch (e) {
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

/// Provider para obtener un servicio específico por ID (con fotos)
final serviceByIdProvider = FutureProvider.family<Service?, int>((ref, serviceId) async {
  try {
    final response = await Supabase.instance.client
        .from('services')
        .select('''
          *,
          service_categories(name)
        ''')
        .eq('id', serviceId)
        .single();

    // Obtener fotos del servicio
    final photos = await Supabase.instance.client
        .from('services_photos')
        .select()
        .eq('service_id', serviceId)
        .order('uploaded_at');

    // Agregar nombre de categoría si existe
    if (response['service_categories'] != null) {
      response['category_name'] = response['service_categories']['name'];
    }
    response['photos'] = photos;

    return Service.fromJson(response);
  } catch (e) {
    print('Error fetching service by ID: $e');
    return null;
  }
});

// ============================================
// MÉTODOS CRUD
// ============================================

/// Crear un nuevo servicio
Future<Service?> createService({
  required String name,
  required double price,
  required int durationMinutes,
  required int categoryId,
  String? description,
}) async {
  try {
    final response = await Supabase.instance.client
        .from('services')
        .insert({
          'name': name,
          'price': price,
          'duration_minutes': durationMinutes,
          'category_id': categoryId,
          'description': description,
          'is_active': true,
        })
        .select()
        .single();

    return Service.fromJson(response);
  } catch (e) {
    print('Error creating service: $e');
    return null;
  }
}

/// Actualizar un servicio existente
Future<bool> updateService({
  required int serviceId,
  String? name,
  double? price,
  int? durationMinutes,
  int? categoryId,
  String? description,
  bool? isActive,
}) async {
  try {
    final Map<String, dynamic> updates = {};

    if (name != null) updates['name'] = name;
    if (price != null) updates['price'] = price;
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (description != null) updates['description'] = description;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return false;

    await Supabase.instance.client
        .from('services')
        .update(updates)
        .eq('id', serviceId);

    return true;
  } catch (e) {
    print('Error updating service: $e');
    return false;
  }
}

/// Agregar una foto a un servicio
Future<bool> addServicePhoto({
  required int serviceId,
  required String photoUrl,
  String? caption,
}) async {
  try {
    await Supabase.instance.client.from('services_photos').insert({
      'service_id': serviceId,
      'photo_url': photoUrl,
      'caption': caption,
    });
    return true;
  } catch (e) {
    print('Error adding service photo: $e');
    return false;
  }
}

/// Eliminar una foto de un servicio
Future<bool> deleteServicePhoto(int photoId) async {
  try {
    await Supabase.instance.client
        .from('services_photos')
        .delete()
        .eq('id', photoId);

    return true;
  } catch (e) {
    print('Error deleting service photo: $e');
    return false;
  }
}

/// Eliminar un servicio
Future<bool> deleteService(int serviceId) async {
  try {
    await Supabase.instance.client
        .from('services')
        .delete()
        .eq('id', serviceId);

    return true;
  } catch (e) {
    print('Error deleting service: $e');
    return false;
  }
}
