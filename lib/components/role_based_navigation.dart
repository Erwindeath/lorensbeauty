import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/providers/auth_provider.dart';
import 'package:lorensbeauty/screens/admin/services/services_management_screen.dart';
import 'package:lorensbeauty/screens/booking/booking_screen_new.dart';
import 'package:lorensbeauty/screens/home/home_screen_improved.dart';
import 'package:lorensbeauty/screens/orders/employee_history_screen.dart';
import 'package:lorensbeauty/screens/orders/my_orders_screen.dart';
import 'package:lorensbeauty/screens/orders/qr_scanner_screen.dart';
import 'package:lorensbeauty/screens/products/products_home_screen.dart';
import 'package:lorensbeauty/screens/admin/products/products_management_screen.dart';
import 'package:lorensbeauty/screens/profile/profile_screen.dart';
import 'package:lorensbeauty/components/role_based_navigation_admin.dart';
import 'package:lorensbeauty/screens/introduction/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget principal que determina la navegación según el rol del usuario
class RoleBasedNavigation extends ConsumerWidget {
  final int initialClientTab;

  const RoleBasedNavigation({Key? key, this.initialClientTab = 0}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return const OnBoardingScreen();
    }

    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final role = profile?['role'];
        if (role == null) {
          return const OnBoardingScreen();
        }

        // Navegación según rol
        switch (role) {
          case 'admin':
            return const AdminBottomNavigation();
          case 'employee':
            return const EmployeeBottomNavigation();
          case 'client':
          default:
            return ClientBottomNavigation(initialIndex: initialClientTab);
        }
      },
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 150),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/lorens_new.png',
                  width: MediaQuery.of(context).size.width / 0.5,
                ),
                const SizedBox(height: 15),
                const Image(
                  image: AssetImage('assets/Loren-s.gif'),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => const OnBoardingScreen(),
    );
  }
}

// ============================================
// NAVEGACIÓN PARA CLIENTES
// ============================================
class ClientBottomNavigation extends StatefulWidget {
  final int initialIndex;

  const ClientBottomNavigation({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<ClientBottomNavigation> createState() => _ClientBottomNavigationState();
}

class _ClientBottomNavigationState extends State<ClientBottomNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void navigateToBooking() {
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreenImproved(onCategorySelected: navigateToBooking),
          const BookingScreenNew(),
          const ProductsHomeScreen(),
          const MyOrdersScreen(),
          const ProfileScreen(role: 1), // role 1 = client
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff721c80),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Mis Órdenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================
// NAVEGACIÓN PARA EMPLEADOS
// ============================================
class EmployeeBottomNavigation extends StatefulWidget {
  const EmployeeBottomNavigation({Key? key}) : super(key: key);

  @override
  State<EmployeeBottomNavigation> createState() => _EmployeeBottomNavigationState();
}

class _EmployeeBottomNavigationState extends State<EmployeeBottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EmployeeHistoryScreen(), // Panel: Historial personal del empleado
    const QRScannerScreen(), // Escáner QR
    const ProfileScreen(role: 3), // Perfil empleado
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff721c80),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Mis Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================
// NAVEGACIÓN PARA ADMINISTRADORES
// ============================================
class AdminBottomNavigation extends StatefulWidget {
  const AdminBottomNavigation({Key? key}) : super(key: key);

  @override
  State<AdminBottomNavigation> createState() => _AdminBottomNavigationState();
}

class _AdminBottomNavigationState extends State<AdminBottomNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        AdminDashboardScreen(
          onNavigateToTab: (index) {
            if (!mounted) return;
            setState(() => _selectedIndex = index);
          },
        ),
        const ProductsManagementScreen(),
        const ServicesManagementScreen(),
        const AdminOrdersScreen(),
        const AdminSettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff721c80),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Órdenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
