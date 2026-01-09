import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/orders_provider.dart';

/// Pantalla que muestra el historial de servicios realizados por el empleado
class EmployeeHistoryScreen extends ConsumerWidget {
  const EmployeeHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeId = Supabase.instance.client.auth.currentUser?.id;

    if (employeeId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: No se pudo obtener el ID del empleado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Historial',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('employee_id', employeeId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar historial',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff721c80),
              ),
            );
          }

          final ordersData = snapshot.data!;

          if (ordersData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay servicios realizados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los servicios que completes aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<Order>>(
            future: _loadOrdersWithServices(ordersData),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff721c80),
                  ),
                );
              }

              final orders = orderSnapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  // Trigger rebuild
                  (context as Element).markNeedsBuild();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Order>> _loadOrdersWithServices(
      List<Map<String, dynamic>> ordersData) async {
    List<Order> orders = [];

    for (var orderJson in ordersData) {
      try {
        final servicesData = await Supabase.instance.client
            .from('order_services')
            .select()
            .eq('order_id', orderJson['id']);

        orderJson['order_services'] = servicesData;
        orders.add(Order.fromJson(orderJson));
      } catch (e) {
        // Skip orders with errors
        continue;
      }
    }

    return orders;
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.formattedTime,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Servicios realizados
            Row(
              children: [
                const Icon(Icons.spa, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.services.length == 1
                        ? order.services.first.serviceName
                        : '${order.services.length} servicios',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duración
            if (order.actualDuration != null)
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Duración real: ${order.actualDuration} min',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    order.formattedDuration,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Total
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Total: ',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  order.formattedPrice,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff721c80),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Indicador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Text(
                    order.statusEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${order.id}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order.statusLabel,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Información
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: order.formattedDate,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Hora programada',
                value: order.formattedTime,
              ),

              if (order.startTime != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.play_circle,
                  label: 'Inicio real',
                  value: _formatTime(order.startTime!),
                ),
              ],

              if (order.endTime != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.stop_circle,
                  label: 'Finalización',
                  value: _formatTime(order.endTime!),
                ),
              ],

              if (order.actualDuration != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.timer,
                  label: 'Duración real',
                  value: '${order.actualDuration} min',
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Servicios
              Row(
                children: [
                  const Icon(Icons.spa, color: Color(0xff721c80), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Servicios Realizados (${order.services.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...order.services.map((service) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 28),
                        Expanded(
                          child: Text(
                            '• ${service.serviceName}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          service.formattedDuration,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.formattedPrice,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff721c80),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff721c80), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
