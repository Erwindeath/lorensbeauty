import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEmployeeActivityScreen extends StatefulWidget {
  const AdminEmployeeActivityScreen({Key? key}) : super(key: key);

  @override
  State<AdminEmployeeActivityScreen> createState() =>
      _AdminEmployeeActivityScreenState();
}

class _AdminEmployeeActivityScreenState
    extends State<AdminEmployeeActivityScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _period = 'day'; // day | week | month
  String? _employeeFilter; // null = all
  String _search = '';

  List<_EmployeeItem> _employees = const [];
  List<_ServiceExecution> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final start = _period == 'day'
          ? DateTime(now.year, now.month, now.day)
          : _period == 'week'
              ? DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: now.weekday - 1))
              : DateTime(now.year, now.month, 1);
      final end = _period == 'day'
          ? start.add(const Duration(days: 1))
          : _period == 'week'
              ? start.add(const Duration(days: 7))
              : DateTime(now.year, now.month + 1, 1);

      final employeeRows = await _client
          .from('user_profiles')
          .select('id, full_name')
          .eq('role', 'employee')
          .order('full_name');
      final employees = (employeeRows as List)
          .map((e) => _EmployeeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final ordersRows = await _client
          .from('orders')
          .select('id, user_id, order_date, order_time, status')
          .gte('order_date', _dateToIso(start))
          .lt('order_date', _dateToIso(end))
          .order('order_date')
          .order('order_time');
      final orders =
          (ordersRows as List).map((e) => Map<String, dynamic>.from(e)).toList();
      final orderIds = orders
          .map((o) => o['id'])
          .where((id) => id != null)
          .map((id) => id as int)
          .toList();

      if (orderIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _employees = employees;
          _items = const [];
          _loading = false;
        });
        return;
      }

      final servicesRows = await _client
          .from('order_services')
          .select(
              'id, order_id, service_name, service_duration, service_price, status, employee_id, started_at, completed_at')
          .inFilter('order_id', orderIds);
      final services = (servicesRows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final userIds = orders
          .map((o) => o['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final namesByUser = <String, String>{};
      if (userIds.isNotEmpty) {
        final profilesRows = await _client
            .from('user_profiles')
            .select('id, full_name')
            .inFilter('id', userIds);
        for (final row in (profilesRows as List)) {
          final r = Map<String, dynamic>.from(row);
          final id = r['id']?.toString();
          if (id == null) continue;
          final name = r['full_name']?.toString().trim();
          namesByUser[id] = (name == null || name.isEmpty) ? 'Cliente' : name;
        }
      }

      final employeeNames = <String, String>{
        for (final e in employees) e.id: e.name,
      };
      final orderById = <int, Map<String, dynamic>>{
        for (final o in orders) (o['id'] as int): o,
      };

      final items = <_ServiceExecution>[];
      for (final s in services) {
        final orderId = s['order_id'] as int?;
        if (orderId == null) continue;
        final order = orderById[orderId];
        if (order == null) continue;
        final employeeId = s['employee_id']?.toString();

        items.add(
          _ServiceExecution(
            id: s['id'] as int,
            orderId: orderId,
            serviceName: s['service_name']?.toString() ?? 'Servicio',
            serviceDuration: s['service_duration'] as int? ?? 0,
            servicePrice:
                double.tryParse((s['service_price'] ?? 0).toString()) ?? 0,
            status: (s['status']?.toString() ?? 'pending').toLowerCase(),
            employeeId: employeeId,
            employeeName: employeeId == null
                ? null
                : (employeeNames[employeeId] ?? 'Empleado'),
            clientName: namesByUser[order['user_id']?.toString()] ?? 'Cliente',
            orderDate: DateTime.tryParse(order['order_date'].toString()) ??
                DateTime.now(),
            orderTime: (order['order_time']?.toString() ?? '00:00:00')
                .substring(0, 5),
            startedAt: s['started_at'] == null
                ? null
                : DateTime.tryParse(s['started_at'].toString()),
            completedAt: s['completed_at'] == null
                ? null
                : DateTime.tryParse(s['completed_at'].toString()),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _employees = employees;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar actividad: $e';
        _loading = false;
      });
    }
  }

  Future<void> _unassignService(_ServiceExecution item) async {
    setState(() => _saving = true);
    try {
      await _client.from('order_services').update({
        'status': 'pending',
        'employee_id': null,
        'started_at': null,
        'completed_at': null,
      }).eq('id', item.id);

      await _syncOrderStatus(item.orderId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio desasignado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo desasignar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncOrderStatus(int orderId) async {
    final rows = await _client
        .from('order_services')
        .select('status,employee_id,started_at,completed_at')
        .eq('order_id', orderId);

    final list = (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    if (list.isEmpty) return;

    final statuses = list
        .map((r) => (r['status']?.toString() ?? 'pending').toLowerCase())
        .toList();
    final allCompleted = statuses.every((s) => s == 'completed');
    final anyInProgress = statuses.any((s) => s == 'in_progress');
    final anyCompleted = statuses.any((s) => s == 'completed');

    DateTime? firstStarted;
    DateTime? lastCompleted;
    String? anyInProgressEmployee;
    for (final row in list) {
      final st = (row['status']?.toString() ?? '').toLowerCase();
      final emp = row['employee_id']?.toString();
      if (st == 'in_progress' && emp != null && anyInProgressEmployee == null) {
        anyInProgressEmployee = emp;
      }
      final startedAt = row['started_at'] == null
          ? null
          : DateTime.tryParse(row['started_at'].toString());
      if (startedAt != null &&
          (firstStarted == null || startedAt.isBefore(firstStarted))) {
        firstStarted = startedAt;
      }
      final completedAt = row['completed_at'] == null
          ? null
          : DateTime.tryParse(row['completed_at'].toString());
      if (completedAt != null &&
          (lastCompleted == null || completedAt.isAfter(lastCompleted))) {
        lastCompleted = completedAt;
      }
    }

    if (allCompleted) {
      await _client.from('orders').update({
        'status': 'completed',
        'start_time': (firstStarted ?? DateTime.now()).toIso8601String(),
        'end_time': (lastCompleted ?? DateTime.now()).toIso8601String(),
      }).eq('id', orderId);
      return;
    }

    if (anyInProgress || anyCompleted) {
      await _client.from('orders').update({
        'status': 'in_progress',
        'employee_id': anyInProgressEmployee,
        'start_time': (firstStarted ?? DateTime.now()).toIso8601String(),
        'end_time': null,
      }).eq('id', orderId);
      return;
    }

    await _client.from('orders').update({
      'status': 'confirmed',
      'employee_id': null,
      'start_time': null,
      'end_time': null,
    }).eq('id', orderId);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      if (_employeeFilter != null && i.employeeId != _employeeFilter) return false;
      if (_search.trim().isNotEmpty) {
        final q = _search.toLowerCase().trim();
        final hay = '${i.clientName} ${i.serviceName} ${i.orderId}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    final inProgress = filtered.where((i) => i.status == 'in_progress').toList();
    final completed = filtered.where((i) => i.status == 'completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operación de Empleados'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xff721c80),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsCard(inProgress.length, completed, filtered.length),
            const SizedBox(height: 12),
            _filtersCard(),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else ...[
              const Text(
                'Servicios en proceso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 8),
              if (inProgress.isEmpty)
                _empty('No hay servicios en proceso con esos filtros.')
              else
                ...inProgress.map((item) => _serviceTile(item, allowUnassign: true)),
              const SizedBox(height: 16),
              const Text(
                'Actividad del período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                _empty('Sin actividad para este filtro.')
              else
                ...filtered.map((item) => _serviceTile(item)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statsCard(int inProgress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff721c80), Color(0xffC46FA9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _statItem('En proceso', '$inProgress', Colors.white),
          _divider(),
          _statItem('Completados', '$completed', Colors.white),
          _divider(),
          _statItem('Total', '$total', Colors.white),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 42,
        color: Colors.white.withOpacity(0.25),
      );

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _periodChip('Día', 'day'),
              const SizedBox(width: 8),
              _periodChip('Semana', 'week'),
              const SizedBox(width: 8),
              _periodChip('Mes', 'month'),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: _employeeFilter,
            decoration: InputDecoration(
              labelText: 'Empleado',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos los empleados'),
              ),
              ..._employees.map(
                (e) => DropdownMenuItem<String?>(
                  value: e.id,
                  child: Text(e.name),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _employeeFilter = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar por cliente, servicio u orden...',
              prefixIcon: const Icon(Icons.search, color: Color(0xff721c80)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _period == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xff721c80),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      onSelected: (_) {
        if (_period == value) return;
        setState(() => _period = value);
        _loadData();
      },
    );
  }

  Widget _serviceTile(_ServiceExecution item, {bool allowUnassign = false}) {
    final statusInfo = _statusInfo(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusInfo['label'] as String,
                  style: TextStyle(
                    color: statusInfo['color'] as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.clientName} • Orden #${item.orderId} • ${item.orderTime}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          Text(
            '${item.employeeName ?? 'Sin asignar'} • ${item.serviceDuration} min • \$${item.servicePrice.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          if (allowUnassign && item.status == 'in_progress') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _unassignService(item),
                icon: const Icon(Icons.person_off, size: 18),
                label: const Text('Desasignar empleado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return {'label': 'En progreso', 'color': Colors.blue};
      case 'completed':
        return {'label': 'Completado', 'color': Colors.green};
      case 'pending':
      case 'confirmed':
        return {'label': 'Pendiente', 'color': Colors.orange};
      case 'cancelled':
        return {'label': 'Cancelado', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  String _dateToIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EmployeeItem {
  final String id;
  final String name;

  const _EmployeeItem({
    required this.id,
    required this.name,
  });

  factory _EmployeeItem.fromJson(Map<String, dynamic> json) {
    final name = json['full_name']?.toString().trim();
    return _EmployeeItem(
      id: json['id'].toString(),
      name: (name == null || name.isEmpty) ? 'Empleado' : name,
    );
  }
}

class _ServiceExecution {
  final int id;
  final int orderId;
  final String serviceName;
  final int serviceDuration;
  final double servicePrice;
  final String status;
  final String? employeeId;
  final String? employeeName;
  final String clientName;
  final DateTime orderDate;
  final String orderTime;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const _ServiceExecution({
    required this.id,
    required this.orderId,
    required this.serviceName,
    required this.serviceDuration,
    required this.servicePrice,
    required this.status,
    required this.employeeId,
    required this.employeeName,
    required this.clientName,
    required this.orderDate,
    required this.orderTime,
    required this.startedAt,
    required this.completedAt,
  });
}
