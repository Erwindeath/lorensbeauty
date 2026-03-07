import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminClientsInsightsScreen extends StatefulWidget {
  const AdminClientsInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AdminClientsInsightsScreen> createState() =>
      _AdminClientsInsightsScreenState();
}

class _AdminClientsInsightsScreenState extends State<AdminClientsInsightsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  int _totalClients = 0;
  int _newThisMonth = 0;
  int _inactive30 = 0;
  int _upcoming7Days = 0;
  List<_ClientStat> _topClients = const [];
  List<_UpcomingTurn> _upcomingTurns = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final today = DateTime(now.year, now.month, now.day);
      final in7Days = today.add(const Duration(days: 7));
      final cutoff30 = today.subtract(const Duration(days: 30));

      final clientsResp = await _client
          .from('user_profiles')
          .select('id, full_name, phone, created_at, is_active')
          .eq('role', 'client');
      final clients = List<Map<String, dynamic>>.from(clientsResp as List);

      final clientNameById = <String, String>{};
      final clientPhoneById = <String, String?>{};
      final clientCreatedAt = <String, DateTime?>{};
      for (final c in clients) {
        final id = c['id']?.toString();
        if (id == null) continue;
        final name = (c['full_name']?.toString() ?? '').trim();
        clientNameById[id] = name.isEmpty ? 'Cliente' : name;
        clientPhoneById[id] = c['phone']?.toString();
        clientCreatedAt[id] = _parseDateTime(c['created_at']?.toString());
      }

      final ordersResp = await _client
          .from('orders')
          .select('id, user_id, order_date, order_time, status, total_price')
          .neq('status', 'cancelled');
      final orders = List<Map<String, dynamic>>.from(ordersResp as List);

      final statsByClient = <String, _ClientAccumulator>{};
      final upcoming = <_UpcomingTurn>[];

      for (final row in orders) {
        final userId = row['user_id']?.toString();
        if (userId == null) continue;
        if (!clientNameById.containsKey(userId)) continue;

        final orderDate = _parseDate(row['order_date']?.toString());
        final orderTime = _normalizeTime(row['order_time']?.toString());
        final totalPrice = row['total_price'] == null
            ? 0.0
            : (double.tryParse(row['total_price'].toString()) ?? 0.0);

        final acc = statsByClient.putIfAbsent(userId, () => _ClientAccumulator());
        acc.orders += 1;
        acc.totalSpent += totalPrice;
        if (orderDate != null) {
          if (acc.lastOrderDate == null || orderDate.isAfter(acc.lastOrderDate!)) {
            acc.lastOrderDate = orderDate;
          }
          if (!orderDate.isBefore(today) && orderDate.isBefore(in7Days)) {
            upcoming.add(
              _UpcomingTurn(
                clientName: clientNameById[userId]!,
                date: orderDate,
                time: orderTime,
                status: row['status']?.toString() ?? 'pending',
              ),
            );
          }
        }
      }

      final allClientIds = clientNameById.keys.toList();
      int newThisMonth = 0;
      int inactive30 = 0;
      final top = <_ClientStat>[];

      for (final id in allClientIds) {
        final createdAt = clientCreatedAt[id];
        if (createdAt != null && !createdAt.isBefore(monthStart)) {
          newThisMonth += 1;
        }

        final acc = statsByClient[id];
        if (acc == null || acc.lastOrderDate == null || acc.lastOrderDate!.isBefore(cutoff30)) {
          inactive30 += 1;
        }

        if (acc != null && acc.orders > 0) {
          top.add(
            _ClientStat(
              name: clientNameById[id]!,
              phone: clientPhoneById[id],
              orders: acc.orders,
              totalSpent: acc.totalSpent,
              lastOrder: acc.lastOrderDate,
            ),
          );
        }
      }

      top.sort((a, b) {
        final byOrders = b.orders.compareTo(a.orders);
        if (byOrders != 0) return byOrders;
        return b.totalSpent.compareTo(a.totalSpent);
      });
      upcoming.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time));
      });

      if (!mounted) return;
      setState(() {
        _totalClients = allClientIds.length;
        _newThisMonth = newThisMonth;
        _inactive30 = inactive30;
        _upcoming7Days = upcoming.length;
        _topClients = top.take(8).toList();
        _upcomingTurns = upcoming.take(10).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la vista de clientes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes - Vista admin'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xff721c80),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _metricCard('Clientes', '$_totalClients', const Color(0xff8B5CF6)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('Nuevos mes', '$_newThisMonth', const Color(0xff10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricCard('Inactivos 30d', '$_inactive30', const Color(0xffF59E0B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard('Turnos 7 dias', '$_upcoming7Days', const Color(0xff3B82F6)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Top clientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 10),
              if (_topClients.isEmpty)
                _emptyCard('Sin historial de ordenes todavia.')
              else
                ..._topClients.map(_clientTile),
              const SizedBox(height: 14),
              const Text(
                'Proximos turnos (7 dias)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 10),
              if (_upcomingTurns.isEmpty)
                _emptyCard('No hay turnos proximos.')
              else
                ..._upcomingTurns.map(_upcomingTile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientTile(_ClientStat c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Color(0xff721c80)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (c.phone != null && c.phone!.isNotEmpty)
                  Text(c.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${c.orders} ord', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '\$${c.totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xff721c80), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingTile(_UpcomingTurn t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Color(0xff721c80)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.clientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${t.date.day}/${t.date.month}/${t.date.year} - ${t.time}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(
            t.status,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _normalizeTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }
}

class _ClientAccumulator {
  int orders = 0;
  double totalSpent = 0;
  DateTime? lastOrderDate;
}

class _ClientStat {
  final String name;
  final String? phone;
  final int orders;
  final double totalSpent;
  final DateTime? lastOrder;

  const _ClientStat({
    required this.name,
    required this.phone,
    required this.orders,
    required this.totalSpent,
    required this.lastOrder,
  });
}

class _UpcomingTurn {
  final String clientName;
  final DateTime date;
  final String time;
  final String status;

  const _UpcomingTurn({
    required this.clientName,
    required this.date,
    required this.time,
    required this.status,
  });
}
