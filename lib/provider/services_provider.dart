import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para obtener la lista de servicios desde Supabase

final servicesOnceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('services')
      .select('id, name, services_photos(photo_url)');

  final services = List<Map<String, dynamic>>.from(response as List);

  for (final serv in services) {
    final photos = serv['services_photos'];
    if (photos != null && photos is List && photos.isNotEmpty) {
      serv['img'] = photos[0]['photo_url'];
    } else {
      serv['img'] = null;
    }
    serv.remove('services_photos');
  }

  return services;
});

// StateProvider para el índice del servicio seleccionado
final selectedServiceIndexProvider = StateProvider<int>((ref) => -1);

// StateProvider para el índice del horario seleccionado
final selectedTimeIndexProvider = StateProvider<int>((ref) => -1);

// Provider para la fecha seleccionada
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
