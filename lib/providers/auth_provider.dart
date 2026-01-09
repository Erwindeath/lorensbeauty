import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider del estado de autenticación (stream de cambios)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Provider del usuario actual (User de Supabase)
final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((data) => data.session?.user);
});

// Provider del perfil completo del usuario con rol
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  // Esperar el estado de autenticación
  final authState = await ref.watch(authStateProvider.future);
  final user = authState.session?.user;

  if (user == null) {
    yield null;
    return;
  }

  try {
    // Obtener perfil desde user_profiles
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    yield response;
  } catch (e) {
    print('Error obteniendo perfil de usuario: $e');
    yield null;
  }
});

// Provider del rol del usuario actual
final userRoleProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (data) => data?['role'] ?? 'client',
    loading: () => 'client',
    error: (_, __) => 'client',
  );
});

// Provider para verificar si es administrador
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == 'admin';
});

// Provider para verificar si es empleado (incluye admin)
final isEmployeeProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'employee' || role == 'admin';
});

// Provider para verificar si es cliente
final isClientProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == 'client';
});
