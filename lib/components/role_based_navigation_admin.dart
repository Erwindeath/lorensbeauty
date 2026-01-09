import 'package:flutter/material.dart';
import 'package:lorensbeauty/screens/admin/products/products_management_screen.dart';
import 'package:lorensbeauty/screens/admin/products/categories_management_screen.dart';

// ============================================
// PANTALLAS DE ADMIN
// ============================================

// Dashboard con estadísticas
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Tarjetas de estadísticas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  icon: Icons.shopping_bag,
                  title: 'Productos',
                  value: '0',
                  color: Colors.blue,
                ),
                _buildStatCard(
                  icon: Icons.spa,
                  title: 'Servicios',
                  value: '0',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Icons.receipt_long,
                  title: 'Órdenes',
                  value: '0',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.people,
                  title: 'Clientes',
                  value: '0',
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Actividad Reciente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityCard(
              icon: Icons.add_circle,
              title: 'Nuevo producto agregado',
              subtitle: 'Hace 2 horas',
              color: Colors.green,
            ),
            _buildActivityCard(
              icon: Icons.shopping_cart,
              title: 'Nueva orden recibida',
              subtitle: 'Hace 5 horas',
              color: Colors.blue,
            ),
            _buildActivityCard(
              icon: Icons.person_add,
              title: 'Nuevo cliente registrado',
              subtitle: 'Hace 1 día',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// Órdenes Placeholder
class OrderManagementPlaceholder extends StatelessWidget {
  const OrderManagementPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Color(0xff721c80)),
            SizedBox(height: 20),
            Text(
              'Gestión de Órdenes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Próximamente',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Ajustes del Admin
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Administración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff721c80),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            icon: Icons.people,
            title: 'Empleados',
            subtitle: 'Gestionar empleados del salón',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          _buildSettingCard(
            context,
            icon: Icons.local_offer,
            title: 'Promociones',
            subtitle: 'Gestionar promociones y descuentos',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          const Divider(height: 32),
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff721c80),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            icon: Icons.category,
            title: 'Categorías de Productos',
            subtitle: 'Gestionar categorías de productos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesManagementScreen(),
                ),
              );
            },
          ),
          _buildSettingCard(
            context,
            icon: Icons.spa,
            title: 'Categorías de Servicios',
            subtitle: 'Gestionar categorías de servicios',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          const Divider(height: 32),
          const Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff721c80),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            icon: Icons.person,
            title: 'Mi Perfil',
            subtitle: 'Editar información personal',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          _buildSettingCard(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de la aplicación',
            color: Colors.red,
            onTap: () {
              // Aquí iría la lógica de cerrar sesión
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usar la opción de perfil para cerrar sesión')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? const Color(0xff721c80);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
