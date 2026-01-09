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
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // El QR contiene el ID de la orden
      final orderId = int.parse(code);

      // Obtener la orden
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

      setState(() {
        _isProcessing = false;
      });

      // Pausar la cámara
      cameraController.stop();

      // Mostrar modal con información de la orden
      _showOrderModal(order);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear QR: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderModal(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderActionModal(
        order: order,
        onAction: () {
          cameraController.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xFFB8860B),
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
            onPressed: () {
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara escáner
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Overlay con guía de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instrucciones
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta la cámara al código QR del cliente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB8860B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderActionModal extends StatefulWidget {
  final Order order;
  final VoidCallback onAction;

  const _OrderActionModal({
    required this.order,
    required this.onAction,
  });

  @override
  State<_OrderActionModal> createState() => _OrderActionModalState();
}

class _OrderActionModalState extends State<_OrderActionModal> {
  bool _isLoading = false;

  Future<void> _startOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employeeId = Supabase.instance.client.auth.currentUser?.id;
      if (employeeId == null) {
        throw Exception('No se pudo obtener el ID del empleado');
      }

      final success = await startOrder(widget.order.id, employeeId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio iniciado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onAction();
      } else {
        throw Exception('No se pudo iniciar el servicio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await completeOrder(widget.order.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio completado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onAction();
      } else {
        throw Exception('No se pudo completar el servicio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            // Indicador de arrastre
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

            // Estado
            Row(
              children: [
                Text(
                  widget.order.statusEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.statusLabel,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Orden #${widget.order.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Información de la cita
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Fecha y Hora',
              value: '${widget.order.formattedDate} • ${widget.order.formattedTime}',
            ),

            const SizedBox(height: 16),

            // Servicios
            _buildServicesCard(),

            const SizedBox(height: 16),

            // Duración y Precio
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Duración',
                    value: widget.order.formattedDuration,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.attach_money,
                    title: 'Total',
                    value: widget.order.formattedPrice,
                  ),
                ),
              ],
            ),

            if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.note,
                title: 'Notas',
                value: widget.order.notes!,
              ),
            ],

            const SizedBox(height: 24),

            // Botones de acción
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB8860B),
                ),
              )
            else
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB8860B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: Color(0xFFB8860B), size: 24),
              const SizedBox(width: 12),
              Text(
                'Servicios (${widget.order.services.length})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.order.services.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: Text(
                        service.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = widget.order.status;

    if (status == 'confirmed') {
      // Orden confirmada - puede iniciar servicio
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Iniciar Servicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAction();
            },
            child: const Text('Cancelar'),
          ),
        ],
      );
    } else if (status == 'in_progress') {
      // Servicio en progreso - puede completar
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Completar Servicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAction();
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    } else {
      // Orden completada o cancelada - solo mostrar información
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onAction();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cerrar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }
  }
}
