import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminServicesInsightsScreen extends StatefulWidget {
  const AdminServicesInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AdminServicesInsightsScreen> createState() =>
      _AdminServicesInsightsScreenState();
}

class _AdminServicesInsightsScreenState
    extends State<AdminServicesInsightsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  int _activeServices = 0;
  int _monthBookings = 0;
  int _todayBookings = 0;
  List<_ServiceCount> _topServices = const [];

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
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final today = DateTime(now.year, now.month, now.day);

      final activeServicesResp = await _client
          .from('services')
          .select('id')
          .eq('is_active', true);
      final activeServicesCount = (activeServicesResp as List).length;

      final monthResp = await _client
          .from('order_services')
          .select('service_name, orders!inner(order_date,status)')
          .gte('orders.order_date', _dateToIso(monthStart))
          .lt('orders.order_date', _dateToIso(monthEnd))
          .neq('orders.status', 'cancelled');
      final monthRows = List<Map<String, dynamic>>.from(monthResp as List);

      final todayResp = await _client
          .from('order_services')
          .select('id, orders!inner(order_date,status)')
          .eq('orders.order_date', _dateToIso(today))
          .neq('orders.status', 'cancelled');
      final todayRows = List<Map<String, dynamic>>.from(todayResp as List);

      final counts = <String, int>{};
      for (final row in monthRows) {
        final service = (row['service_name']?.toString() ?? '').trim();
        if (service.isEmpty) continue;
        counts[service] = (counts[service] ?? 0) + 1;
      }

      final top = counts.entries
          .map((e) => _ServiceCount(name: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      if (!mounted) return;
      setState(() {
        _activeServices = activeServicesCount;
        _monthBookings = monthRows.length;
        _todayBookings = todayRows.length;
        _topServices = top.take(8).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la vista de servicios.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios - Vista admin'),
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
                    child: _metricCard(
                      label: 'Servicios activos',
                      value: '$_activeServices',
                      color: const Color(0xff10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      label: 'Turnos del mes',
                      value: '$_monthBookings',
                      color: const Color(0xff3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _metricCard(
                label: 'Turnos de hoy',
                value: '$_todayBookings',
                color: const Color(0xffF59E0B),
              ),
              const SizedBox(height: 18),
              const Text(
                'Servicios mas solicitados (mes)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 10),
              if (_topServices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Sin datos de turnos para este mes.'),
                )
              else
                ..._topServices.asMap().entries.map(
                      (entry) => _serviceTile(
                        rank: entry.key + 1,
                        name: entry.value.name,
                        count: entry.value.count,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color color,
  }) {
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
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceTile({
    required int rank,
    required String name,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xff721c80).withOpacity(0.12),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xff721c80),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xff721c80),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _ServiceCount {
  final String name;
  final int count;

  const _ServiceCount({
    required this.name,
    required this.count,
  });
}
