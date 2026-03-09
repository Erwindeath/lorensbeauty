import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/orders_provider.dart';

class EmployeeHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends ConsumerState<EmployeeHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _periodFilter = 'all';
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeId = Supabase.instance.client.auth.currentUser?.id;
    if (employeeId == null) {
      return const Scaffold(
        body: Center(child: Text('No se pudo obtener el empleado actual.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historial de Servicios'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('employee_id', employeeId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error cargando historial.'));
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff721c80)),
            );
          }

          return FutureBuilder<List<_OrderWithClient>>(
            future: _enrichOrders(snapshot.data!),
            builder: (context, detailsSnapshot) {
              if (!detailsSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                );
              }

              final all = detailsSnapshot.data!;
              final filtered = _applyFilters(all);

              return Column(
                children: [
                  _buildFilters(all.length),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No hay resultados con estos filtros.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildOrderCard(filtered[i]),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_OrderWithClient>> _enrichOrders(List<Map<String, dynamic>> rows) async {
    final out = <_OrderWithClient>[];
    for (final row in rows) {
      try {
        final orderId = row['id'] as int;
        final userId = row['user_id']?.toString();

        final services = await Supabase.instance.client
            .from('order_services')
            .select()
            .eq('order_id', orderId);
        row['order_services'] = services;
        final order = Order.fromJson(row);

        var clientName = 'Cliente';
        if (userId != null) {
          final profile = await Supabase.instance.client
              .from('user_profiles')
              .select('full_name')
              .eq('id', userId)
              .maybeSingle();
          final n = profile?['full_name']?.toString().trim();
          if (n != null && n.isNotEmpty) clientName = n;
        }

        out.add(_OrderWithClient(order: order, clientName: clientName));
      } catch (_) {}
    }
    return out;
  }

  List<_OrderWithClient> _applyFilters(List<_OrderWithClient> source) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    final q = _search.toLowerCase().trim();

    return source.where((item) {
      final date = item.order.createdAt;
      final periodOk = _periodFilter == 'all' ||
          (_periodFilter == 'week' && date.isAfter(weekAgo)) ||
          (_periodFilter == 'month' && date.isAfter(monthAgo));
      if (!periodOk) return false;
      if (q.isEmpty) return true;

      final client = item.clientName.toLowerCase();
      final services = item.order.services.map((s) => s.serviceName.toLowerCase()).join(' ');
      return client.contains(q) || services.contains(q);
    }).toList();
  }

  Widget _buildFilters(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            children: [
              _periodChip('Todo', 'all'),
              const SizedBox(width: 8),
              _periodChip('Semana', 'week'),
              const SizedBox(width: 8),
              _periodChip('Mes', 'month'),
              const Spacer(),
              Text('$total', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Filtra por cliente o servicio...',
              prefixIcon: const Icon(Icons.search, color: Color(0xff721c80)),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _periodFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _periodFilter = value),
      selectedColor: const Color(0xff721c80),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildOrderCard(_OrderWithClient item) {
    final o = item.order;
    final color = o.status == 'completed'
        ? Colors.green
        : o.status == 'in_progress'
            ? Colors.blue
            : o.status == 'cancelled'
                ? Colors.red
                : Colors.grey;

    return InkWell(
      onTap: () => _showDetail(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.clientName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Text(
                  o.formattedTime,
                  style: const TextStyle(color: Color(0xff721c80), fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${o.formattedDate} - ${o.statusLabel}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              o.services.map((s) => s.serviceName).take(2).join(', ') +
                  (o.services.length > 2 ? ' +${o.services.length - 2}' : ''),
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(_OrderWithClient item) async {
    final order = item.order;
    final employeeId = Supabase.instance.client.auth.currentUser?.id ?? '';
    var services = List<OrderService>.from(order.services);
    try {
      final latestServices = await Supabase.instance.client
          .from('order_services')
          .select()
          .eq('order_id', order.id);
      services = latestServices
          .map((s) => OrderService.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (_) {}
    if (!mounted) return;

    final localStatus = <int, String>{for (final s in services) s.id: s.status};
    final localEmployee = <int, String?>{for (final s in services) s.id: s.employeeId};

    final selected = services
        .where((s) => s.status == 'in_progress' && (s.employeeId == null || s.employeeId == employeeId))
        .map((s) => s.id)
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String statusOf(OrderService s) => (localStatus[s.id] ?? s.status).toLowerCase();
          String? employeeOf(OrderService s) => localEmployee[s.id] ?? s.employeeId;

          final selectedServices = services.where((s) => selected.contains(s.id)).toList();
          final selectedToStart = selectedServices
              .where((s) => statusOf(s) != 'in_progress' && statusOf(s) != 'completed')
              .toList();
          final selectedToComplete = selectedServices.where((s) => statusOf(s) == 'in_progress').toList();

          Future<void> runStart() async {
            var started = 0;
            for (final s in selectedToStart) {
              final ok = await startOrderService(
                orderId: order.id,
                orderServiceId: s.id,
                employeeId: employeeId,
              );
              if (ok) {
                started++;
                setModalState(() {
                  localStatus[s.id] = 'in_progress';
                  localEmployee[s.id] = employeeId;
                  selected.add(s.id);
                });
              }
            }
            if (!mounted) return;
            if (started == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo iniciar los servicios seleccionados.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Servicios iniciados: $started'),
                backgroundColor: Colors.green,
              ),
            );
          }

          Future<void> runComplete() async {
            var completed = 0;
            for (final s in selectedToComplete) {
              final ok = await completeOrderService(
                orderId: order.id,
                orderServiceId: s.id,
                employeeId: employeeId,
              );
              if (ok) {
                completed++;
                setModalState(() {
                  localStatus[s.id] = 'completed';
                  selected.remove(s.id);
                });
              }
            }
            if (!mounted) return;
            if (completed == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo completar los servicios seleccionados.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Servicios completados: $completed'),
                backgroundColor: Colors.green,
              ),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.74,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(item.clientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Orden #${order.id} - ${order.statusLabel}'),
                  const SizedBox(height: 8),
                  Text(
                    'Iniciar: ${selectedToStart.length} • Completar: ${selectedToComplete.length}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...services.map((s) {
                    final status = statusOf(s);
                    final owner = employeeOf(s);
                    final isSelected = selected.contains(s.id);
                    final isCompleted = status == 'completed';
                    final takenByAnother = status == 'in_progress' && owner != null && owner != employeeId;
                    final isDisabled = isCompleted || takenByAnother;
                    final statusText = isCompleted
                        ? 'Completado'
                        : status == 'in_progress'
                            ? 'En progreso'
                            : 'Pendiente';

                    return InkWell(
                      onTap: isDisabled
                          ? null
                          : () {
                              setModalState(() {
                                if (isSelected) {
                                  selected.remove(s.id);
                                } else {
                                  selected.add(s.id);
                                }
                              });
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey.shade100
                              : isSelected
                                  ? const Color(0xff721c80).withOpacity(0.08)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xff721c80) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                              color: isCompleted
                                  ? Colors.green
                                  : isDisabled
                                      ? Colors.grey.shade400
                                      : isSelected
                                          ? const Color(0xff721c80)
                                          : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.serviceName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDisabled ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    takenByAnother
                                        ? '${s.formattedDuration} - ${s.formattedPrice} - Tomado por otro empleado'
                                        : '${s.formattedDuration} - ${s.formattedPrice} - $statusText',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  if (order.status == 'in_progress' || order.status == 'confirmed') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: selectedToStart.isEmpty ? null : runStart,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff721c80),
                              side: const BorderSide(color: Color(0xff721c80)),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              selectedToStart.length <= 1
                                  ? 'Iniciar'
                                  : 'Iniciar (${selectedToStart.length})',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedToComplete.isEmpty ? null : runComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              selectedToComplete.length <= 1
                                  ? 'Completar'
                                  : 'Completar (${selectedToComplete.length})',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Los servicios completados quedan bloqueados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderWithClient {
  final Order order;
  final String clientName;

  const _OrderWithClient({
    required this.order,
    required this.clientName,
  });
}
