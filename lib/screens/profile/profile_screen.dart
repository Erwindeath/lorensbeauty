import 'package:flutter/material.dart';
import 'package:lorensbeauty/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../../controller/auth_controller.dart';
import '../../widgets/horizontal_line.dart';
import '../introduction/onboarding_screen.dart';
import '../orders/my_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  final int role; // 1: usuario normal, 2: administrador

  const ProfileScreen({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser();

    //print(user);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con gradiente
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color(0xffC46FA9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        foregroundImage: user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                        child: user?.userMetadata?['avatar_url'] == null
                            ? const Icon(Icons.person, size: 45, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.userMetadata?['full_name'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi Perfil',
                    style: TextStyle(
                      color: Color(0xff721c80),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
              // Opciones según el rol
              if (role == 1) ...[
                // Cliente: mostrar todas las opciones
                const SectionCard(
                  icon: Icons.person_outline,
                  header: "Información Personal",
                  desc: "Actualiza tu perfil y preferencias",
                ),
                SectionCard(
                  icon: Icons.receipt_long_outlined,
                  header: "Mis Reservas",
                  desc: "Historial de reservas y servicios",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SectionCard(
                  icon: Icons.favorite_border,
                  header: "Favoritos",
                  desc: "Productos y servicios guardados",
                ),
                const SectionCard(
                  icon: Icons.settings_outlined,
                  header: "Configuración",
                  desc: "Notificaciones y privacidad",
                ),
              ] else if (role == 3) ...[
                // Empleado: opciones simplificadas
                const SectionCard(
                  icon: Icons.person_outline,
                  header: "Información Personal",
                  desc: "Actualiza tu perfil",
                ),
                const SectionCard(
                  icon: Icons.settings_outlined,
                  header: "Configuración",
                  desc: "Notificaciones y privacidad",
                ),
              ] else ...[
                // Otros roles
                const SectionCard(
                  icon: Icons.person_outline,
                  header: "Información Personal",
                  desc: "Actualiza tu perfil y preferencias",
                ),
                const SectionCard(
                  icon: Icons.settings_outlined,
                  header: "Configuración",
                  desc: "Notificaciones y privacidad",
                ),
              ],
              const HorizontalLine(),
              const SizedBox(height: 20),
              // Botón de cerrar sesión mejorado
              InkWell(
                onTap: () async {
                  // Mostrar diálogo de confirmación
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text(
                          '¿Estás seguro que deseas cerrar sesión?'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff721c80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cerrar Sesión',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await Authentication.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const OnBoardingScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red.shade600, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String header;
  final String desc;
  final VoidCallback? onTap;

  const SectionCard({
    Key? key,
    required this.icon,
    required this.header,
    required this.desc,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff721c80).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xff721c80),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
        ),
      ),
    );
  }
}
