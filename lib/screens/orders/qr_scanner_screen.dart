import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/orders_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final orderId = int.parse(code);
      final orderData = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      final servicesData = await Supabase.instance.client
          .from('order_services')
          .select()
          .eq('order_id', orderId);

      orderData['order_services'] = servicesData;
      final order = Order.fromJson(orderData);

      if (!mounted) return;
      setState(() => _isProcessing = false);
      cameraController.stop();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _OrderActionModal(
          order: order,
          onClosed: () => cameraController.start(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: cameraController.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 255,
              height: 255,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          Positioned(
            top: 34,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Escanea el QR del cliente para gestionar sus servicios',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xff721c80)),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderActionModal extends StatefulWidget {
  final Order order;
  final VoidCallback onClosed;

  const _OrderActionModal({
    required this.order,
    required this.onClosed,
  });

  @override
  State<_OrderActionModal> createState() => _OrderActionModalState();
}

class _OrderActionModalState extends State<_OrderActionModal> {
  bool _loading = false;
  late final String? _employeeId;
  late final List<OrderService> _services;
  final Set<int> _selectedServiceIds = {};
  int _tapVersion = 0;

  @override
  void initState() {
    super.initState();
    _employeeId = Supabase.instance.client.auth.currentUser?.id;
    _services = List<OrderService>.from(widget.order.services);
    if (_services.isNotEmpty) _selectedServiceIds.add(_services.first.id);
  }

  List<OrderService> get _selectedServices =>
      _services.where((s) => _selectedServiceIds.contains(s.id)).toList();

  bool _isTakenByAnother(OrderService s) {
    if (_employeeId == null) return false;
    if (s.employeeId == null || s.employeeId!.isEmpty) return false;
    if (s.status == 'pending' || s.status == 'confirmed') return false;
    return s.employeeId != _employeeId;
  }

  bool _canComplete(OrderService s) {
    if (s.status != 'in_progress') return false;
    if (s.employeeId == null || _employeeId == null) return true;
    return s.employeeId == _employeeId;
  }

  Future<void> _handleAction() async {
    final selected = _selectedServices;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un servicio.')),
      );
      return;
    }
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el empleado actual')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      int started = 0;
      int completed = 0;
      int skipped = 0;

      for (final s in selected) {
        if (_isTakenByAnother(s)) {
          skipped++;
          continue;
        }
        bool ok;
        if (_canComplete(s)) {
          ok = await completeOrderService(
            orderId: widget.order.id,
            orderServiceId: s.id,
            employeeId: _employeeId!,
          );
          if (ok) {
            completed++;
          }
        } else {
          ok = await startOrderService(
            orderId: widget.order.id,
            orderServiceId: s.id,
            employeeId: _employeeId!,
          );
          if (ok) {
            started++;
          }
        }
      }

      if (started == 0 && completed == 0 && skipped > 0) {
        throw Exception('Los servicios seleccionados estan bloqueados por otro empleado.');
      }
      if (started == 0 && completed == 0) {
        throw Exception(
          'No se pudo guardar el cambio de servicios. Verifica permisos/politicas en order_services.',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Iniciados: $started • Completados: $completed'
            '${skipped > 0 ? ' • Omitidos: $skipped' : ''}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
      widget.onClosed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff721c80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xff721c80)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${widget.order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                      Text(
                        '${widget.order.formattedDate} - ${widget.order.formattedTime}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF7F2FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE6D7F2)),
              ),
              child: const Text(
                'Puedes seleccionar uno o varios servicios de esta orden.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff5C3A75)),
              ),
            ),
            const SizedBox(height: 14),
            ..._services.map((s) {
              final selected = _selectedServiceIds.contains(s.id);
              final taken = _isTakenByAnother(s);
              final statusColor = s.status == 'completed'
                  ? Colors.green
                  : s.status == 'in_progress'
                      ? Colors.blue
                      : Colors.grey;
              return InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedServiceIds.remove(s.id);
                    } else {
                      _selectedServiceIds.add(s.id);
                    }
                    _tapVersion++;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  key: ValueKey('svc_${s.id}_$_tapVersion'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff721c80).withOpacity(0.14)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xff721c80) : Colors.grey.shade300,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: selected ? const Color(0xff721c80) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (selected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff721c80).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Seleccionado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff721c80),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    taken ? 'Tomado por otro empleado' : _serviceStatusLabel(s.status),
                                    style: TextStyle(fontSize: 12, color: statusColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(s.formattedDuration, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xff721c80)))
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      widget.order.status == 'completed' || widget.order.status == 'cancelled'
                          ? null
                          : _handleAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedServiceIds.length > 1
                        ? 'Procesar servicios seleccionados'
                        : 'Procesar servicio seleccionado',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onClosed();
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  String _serviceStatusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      case 'pending':
      case 'confirmed':
      default:
        return 'Pendiente';
    }
  }
}
