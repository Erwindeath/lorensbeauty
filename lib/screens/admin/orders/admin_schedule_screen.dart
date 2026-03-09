import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({Key? key}) : super(key: key);

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  String? _error;
  Map<DateTime, List<_DayOrder>> _ordersByDay = {};

  @override
  void initState() {
    super.initState();
    _loadMonth(_displayedMonth);
  }

  Future<void> _loadMonth(DateTime month) async {
    final monthKey = DateTime(month.year, month.month);
    setState(() {
      _loading = true;
      _error = null;
      _displayedMonth = monthKey;
    });

    try {
      final start = DateTime(month.year, month.month, 1);
      final endExclusive = DateTime(month.year, month.month + 1, 1);

      final ordersResponse = await _client
          .from('orders')
          .select('id, user_id, order_date, order_time, status, total_price, notes')
          .gte('order_date', _dateToIso(start))
          .lt('order_date', _dateToIso(endExclusive))
          .order('order_date')
          .order('order_time');

      final orders = List<Map<String, dynamic>>.from(ordersResponse as List);
      final userIds = orders
          .map((o) => o['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final orderIds = orders
          .map((o) => o['id'])
          .where((id) => id != null)
          .map((id) => id as int)
          .toList();

      final namesByUserId = <String, String>{};
      if (userIds.isNotEmpty) {
        final profilesResponse = await _client
            .from('user_profiles')
            .select('id, full_name')
            .inFilter('id', userIds);
        final profiles = List<Map<String, dynamic>>.from(profilesResponse as List);
        for (final profile in profiles) {
          final id = profile['id']?.toString();
          if (id == null) continue;
          final fullName = profile['full_name']?.toString().trim();
          namesByUserId[id] = (fullName == null || fullName.isEmpty) ? 'Cliente' : fullName;
        }
      }

      final servicesByOrderId = <int, List<String>>{};
      if (orderIds.isNotEmpty) {
        final servicesResponse = await _client
            .from('order_services')
            .select('order_id, service_name')
            .inFilter('order_id', orderIds);
        final services = List<Map<String, dynamic>>.from(servicesResponse as List);
        for (final row in services) {
          final rawOrderId = row['order_id'];
          final name = row['service_name']?.toString().trim();
          if (rawOrderId is! int || name == null || name.isEmpty) continue;
          servicesByOrderId.putIfAbsent(rawOrderId, () => []).add(name);
        }
      }

      final grouped = <DateTime, List<_DayOrder>>{};
      for (final row in orders) {
        final day = _parseDbDate(row['order_date']?.toString());
        if (day == null) continue;
        final key = DateTime(day.year, day.month, day.day);

        final orderId = row['id'] as int?;
        final userId = row['user_id']?.toString();
        final clientName = userId == null ? 'Cliente' : (namesByUserId[userId] ?? 'Cliente');
        final orderTime = _normalizeTime(row['order_time']?.toString());
        final services = (orderId != null) ? (servicesByOrderId[orderId] ?? const []) : const <String>[];
        final totalPrice = row['total_price'] == null
            ? null
            : double.tryParse(row['total_price'].toString());

        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(
          _DayOrder(
            id: orderId ?? 0,
            time: orderTime,
            status: row['status']?.toString() ?? 'pending',
            clientName: clientName,
            services: services,
            totalPrice: totalPrice,
            notes: row['notes']?.toString(),
          ),
        );
      }

      for (final entry in grouped.entries) {
        entry.value.sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));
      }

      if (!mounted) return;
      setState(() {
        _ordersByDay = grouped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la agenda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dayOrders = _ordersByDay[selectedKey] ?? const <_DayOrder>[];
    final monthCount = _ordersByDay.values.fold<int>(0, (sum, list) => sum + list.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda mensual'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMonth(_displayedMonth),
        color: const Color(0xff721c80),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMonthlyCalendar(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff721c80),
                  ),
                ),
                Text(
                  '$monthCount turnos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Turnos del ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff721c80),
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (dayOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No hay turnos para este dia.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              ...dayOrders.map((order) => _buildOrderCard(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    const weekdays = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final leadingEmpty = firstOfMonth.weekday % 7; // domingo = 0
    final totalCells = leadingEmpty + daysInMonth;
    final rows = ((totalCells + 6) / 7).floor();
    final gridCells = rows * 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff721c80),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mes anterior',
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mes siguiente',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 42,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
                  return const SizedBox.shrink();
                }
                final dayNumber = index - leadingEmpty + 1;
                final dayDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
                final dayKey = DateTime(dayDate.year, dayDate.month, dayDate.day);
                final count = _ordersByDay[dayKey]?.length ?? 0;
                final isSelected = _isSameDay(dayDate, _selectedDate);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = dayDate),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xff721c80) : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                          border: !isSelected && count > 0
                              ? Border.all(color: const Color(0xff721c80).withOpacity(0.35))
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xff721c80),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? const Color(0xff721c80) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    _loadMonth(next);
    final selectedInNewMonth =
        _selectedDate.year == next.year && _selectedDate.month == next.month;
    if (!selectedInNewMonth) {
      setState(() => _selectedDate = DateTime(next.year, next.month, 1));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildOrderCard(_DayOrder order) {
    final info = _statusInfo(order.status);
    final price = order.totalPrice == null ? '-' : '\$${order.totalPrice!.toStringAsFixed(2)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOrderDetails(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xff721c80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.time,
                  style: const TextStyle(
                    color: Color(0xff721c80),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xff721c80),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: order.services.isEmpty
                ? [
                    const Text(
                      'Sin servicios registrados',
                      style: TextStyle(color: Colors.grey),
                    )
                  ]
                : order.services
                    .map(
                      (service) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff721c80).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
          ),
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nota: ${order.notes}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(_DayOrder order) {
    final info = _statusInfo(order.status);
    final price = order.totalPrice == null ? '-' : '\$${order.totalPrice!.toStringAsFixed(2)}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Turno #${order.id}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _detailRow('Cliente', order.clientName),
                  _detailRow('Hora', order.time),
                  _detailRow('Precio', price),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (info['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      info['label'] as String,
                      style: TextStyle(
                        color: info['color'] as Color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Servicios',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  if (order.services.isEmpty)
                    Text(
                      'Sin servicios registrados',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else
                    ...order.services.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('- $s'),
                      ),
                    ),
                  if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Notas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(order.notes!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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

  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDbDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
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

  String _monthName(int month) {
    const names = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return names[month];
  }
}

class _DayOrder {
  final int id;
  final String time;
  final String status;
  final String clientName;
  final List<String> services;
  final double? totalPrice;
  final String? notes;

  const _DayOrder({
    required this.id,
    required this.time,
    required this.status,
    required this.clientName,
    required this.services,
    required this.totalPrice,
    required this.notes,
  });
}

