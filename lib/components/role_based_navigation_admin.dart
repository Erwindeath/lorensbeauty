import 'package:flutter/material.dart';
import 'package:lorensbeauty/screens/admin/products/categories_management_screen.dart';
import 'package:lorensbeauty/screens/introduction/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// DASHBOARD ADMIN CON DATOS REALES
// ============================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _productsCount = 0;
  int _servicesCount = 0;
  int _ordersCount = 0;
  int _clientsCount = 0;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('products').select('id').eq('active', true),
        client.from('services').select('id').eq('is_active', true),
        client.from('orders').select('id'),
        client.from('user_profiles').select('id').eq('role', 'client'),
        client
            .from('orders')
            .select('id, status, total_price, order_date, order_time')
            .order('created_at', ascending: false)
            .limit(5),
      ]);
      if (mounted) {
        setState(() {
          _productsCount = (results[0] as List).length;
          _servicesCount = (results[1] as List).length;
          _ordersCount = (results[2] as List).length;
          _clientsCount = (results[3] as List).length;
          _recentOrders = List<Map<String, dynamic>>.from(results[4] as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xff721c80),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color(0xffC46FA9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Loren's Beauty",
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Panel de Administración',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getGreeting(),
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _buildStatCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Productos',
                      value: '$_productsCount',
                      color: const Color(0xff3B82F6),
                    ),
                    _buildStatCard(
                      icon: Icons.spa_outlined,
                      title: 'Servicios',
                      value: '$_servicesCount',
                      color: const Color(0xff10B981),
                    ),
                    _buildStatCard(
                      icon: Icons.receipt_long_outlined,
                      title: '�rdenes',
                      value: '$_ordersCount',
                      color: const Color(0xffF59E0B),
                    ),
                    _buildStatCard(
                      icon: Icons.people_outline,
                      title: 'Clientes',
                      value: '$_clientsCount',
                      color: const Color(0xff8B5CF6),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '�rdenes Recientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff721c80),
                    ),
                  ),
                  if (!_loading)
                    TextButton(
                      onPressed: _loadStats,
                      style: TextButton.styleFrom(foregroundColor: const Color(0xff721c80)),
                      child: const Text('Actualizar'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_recentOrders.isEmpty && !_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('No hay �rdenes recientes', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recentOrders.length,
                itemBuilder: (context, index) => _buildRecentOrderCard(_recentOrders[index]),
              ),
            const SizedBox(height: 24),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final info = _statusInfo(status);
    final price = order['total_price'];
    final priceStr = price != null
        ? '\$${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}'
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (info['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: info['color'] as Color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orden #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '${order['order_date'] ?? ''} • ${order['order_time'] ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceStr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: info['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'Pendiente', 'color': Colors.orange};
      case 'confirmed':
        return {'label': 'Confirmada', 'color': Colors.green};
      case 'in_progress':
        return {'label': 'En progreso', 'color': Colors.blue};
      case 'completed':
        return {'label': 'Completada', 'color': const Color(0xff6B7280)};
      case 'cancelled':
        return {'label': 'Cancelada', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}

// ============================================
// GESTIÓN DE ÓRDENES ADMIN - REAL
// ============================================
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      var query = client
          .from('orders')
          .select('id, status, total_price, order_date, order_time, total_duration');

      if (_selectedFilter != 'all') {
        query = query.eq('status', _selectedFilter);
      }

      final response = await query.order('created_at', ascending: false).limit(50);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(dynamic orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Orden #$orderId actualizada a ${_statusInfo(newStatus)['label']}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  'Gestión de Órdenes',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildChip('Todas', 'all'),
                  const SizedBox(width: 8),
                  _buildChip('Pendientes', 'pending'),
                  const SizedBox(width: 8),
                  _buildChip('Confirmadas', 'confirmed'),
                  const SizedBox(width: 8),
                  _buildChip('En Progreso', 'in_progress'),
                  const SizedBox(width: 8),
                  _buildChip('Completadas', 'completed'),
                  const SizedBox(width: 8),
                  _buildChip('Canceladas', 'cancelled'),
                ],
              ),
            ),
          ),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xff721c80)))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No hay órdenes',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: const Color(0xff721c80),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadOrders();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff721c80) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xff721c80) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xff721c80).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final info = _statusInfo(status);
    final price = order['total_price'];
    final priceStr = price != null
        ? '\$${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}'
        : '-';
    final duration = order['total_duration'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: info['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '${order['order_date'] ?? '-'} • ${order['order_time'] ?? '-'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '$duration min',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff721c80),
                  ),
                ),
              ],
            ),

            // Acciones para pending y confirmed
            if (status == 'pending' || status == 'confirmed') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (status == 'pending') ...[
                    Expanded(
                      child: _actionBtn('Confirmar', Colors.green,
                          () => _updateStatus(order['id'], 'confirmed')),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _actionBtn('Cancelar', Colors.red,
                        () => _updateStatus(order['id'], 'cancelled')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'Pendiente', 'color': Colors.orange};
      case 'confirmed':
        return {'label': 'Confirmada', 'color': Colors.green};
      case 'in_progress':
        return {'label': 'En progreso', 'color': Colors.blue};
      case 'completed':
        return {'label': 'Completada', 'color': const Color(0xff6B7280)};
      case 'cancelled':
        return {'label': 'Cancelada', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}

// ============================================
// AJUSTES DEL ADMIN - CON LOGOUT FUNCIONAL
// ============================================
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  'Ajustes',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                _buildSection('Administración', [
                  _buildItem(context,
                      icon: Icons.people,
                      title: 'Empleados',
                      subtitle: 'Gestionar empleados del salón',
                      onTap: () => _comingSoon(context)),
                  _buildItem(context,
                      icon: Icons.local_offer,
                      title: 'Promociones',
                      subtitle: 'Gestionar promociones y descuentos',
                      onTap: () => _comingSoon(context)),
                ]),
                const SizedBox(height: 16),
                _buildSection('Categorías', [
                  _buildItem(context,
                      icon: Icons.category,
                      title: 'Categorías de Productos',
                      subtitle: 'Gestionar categorías de productos',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                          )),
                  _buildItem(context,
                      icon: Icons.spa,
                      title: 'Categorías de Servicios',
                      subtitle: 'Gestionar categorías de servicios',
                      onTap: () => _comingSoon(context)),
                ]),
                const SizedBox(height: 16),
                _buildSection('Cuenta', [
                  _buildItem(context,
                      icon: Icons.person,
                      title: 'Mi Perfil',
                      subtitle: 'Editar información personal',
                      onTap: () => _comingSoon(context)),
                  _buildItem(context,
                      icon: Icons.logout,
                      title: 'Cerrar Sesión',
                      subtitle: 'Salir de la aplicación',
                      color: Colors.red,
                      onTap: () => _confirmLogout(context)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xff721c80),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? const Color(0xff721c80);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: color ?? Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente disponible'),
        backgroundColor: Color(0xff721c80),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff721c80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final navigator = Navigator.of(context);
      await Supabase.instance.client.auth.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
        (route) => false,
      );
    }
  }
}

