import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/components/date_piceker.dart';
import 'package:lorensbeauty/providers/services_provider.dart';
import 'package:lorensbeauty/providers/orders_provider.dart';
import 'package:lorensbeauty/screens/orders/order_confirmation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingScreenNew extends ConsumerStatefulWidget {
  const BookingScreenNew({Key? key}) : super(key: key);

  @override
  ConsumerState<BookingScreenNew> createState() => _BookingScreenNewState();
}

class _BookingScreenNewState extends ConsumerState<BookingScreenNew> {
  // Paso actual: 0 = categoría, 1 = servicios
  int _currentStep = 0;

  // Horarios disponibles
  final List<String> timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
    "06:00 PM",
  ];

  int selectedTimeIndex = -1;

  // Método para obtener fotos de un servicio
  Future<List<String>> _fetchServicePhotos(int serviceId) async {
    try {
      final response = await Supabase.instance.client
          .from('services_photos')
          .select('photo_url')
          .eq('service_id', serviceId)
          .order('display_order');

      return (response as List)
          .map((photo) => photo['photo_url'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Si ya hay una categoría seleccionada (viene del Home), ir directo a paso 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedCategory = ref.read(selectedCategoryProvider);
      if (selectedCategory != null && _currentStep == 0) {
        setState(() => _currentStep = 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedServices = ref.watch(selectedServicesProvider);
    final totalPrice = ref.watch(formattedTotalProvider);
    final totalDuration = ref.watch(formattedDurationProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header con degradado
            Container(
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff721c80),
                    Color.fromARGB(255, 196, 103, 169),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 18,
                  right: 18,
                  bottom: 15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Botón de retroceder
                        if (_currentStep == 1 || selectedCategory != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              if (_currentStep == 1) {
                                setState(() => _currentStep = 0);
                              } else {
                                ref.read(selectedCategoryProvider.notifier).state = null;
                                ref.read(selectedServicesProvider.notifier).state = [];
                              }
                            },
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        Text(
                          _currentStep == 0
                              ? "Selecciona Categoría"
                              : "Selecciona Servicios",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const CustomDatePicker(),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PASO 0: Seleccionar Categoría
                  if (_currentStep == 0) _buildCategorySelection(),

                  // PASO 1: Seleccionar Servicios
                  if (_currentStep == 1) _buildServiceSelection(),

                  const SizedBox(height: 20),

                  // Horarios disponibles (solo si hay servicios seleccionados)
                  if (selectedServices.isNotEmpty) ...[
                    const Text(
                      "Horarios disponibles",
                      style: TextStyle(
                        color: Color.fromARGB(255, 45, 42, 42),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTimeSlots(),
                    const SizedBox(height: 20),
                  ],

                  // Resumen de la reserva
                  if (selectedServices.isNotEmpty) _buildSummary(totalPrice, totalDuration),

                  const SizedBox(height: 16),

                  // Botón de confirmar reserva
                  if (selectedServices.isNotEmpty)
                    _buildConfirmButton(context, selectedServices, selectedTimeIndex),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construir selección de categorías
  Widget _buildCategorySelection() {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No hay categorías disponibles'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Categorías de Servicios",
              style: TextStyle(
                color: Color.fromARGB(255, 45, 42, 42),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  // Card de categoría
  Widget _buildCategoryCard(ServiceCategory category) {
    final color = _parseColor(category.colorHex);

    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        setState(() => _currentStep = 1);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(category.iconName),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Construir selección de servicios
  Widget _buildServiceSelection() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    if (selectedCategory == null) return const SizedBox.shrink();

    final servicesAsync = ref.watch(servicesByCategoryProvider(selectedCategory.id));

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No hay servicios en esta categoría'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _parseColor(selectedCategory.colorHex).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Categoría: ${selectedCategory.name}',
                style: TextStyle(
                  color: _parseColor(selectedCategory.colorHex),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Selecciona uno o más servicios",
              style: TextStyle(
                color: Color.fromARGB(255, 45, 42, 42),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = ref.watch(selectedServicesProvider).any((s) => s.id == service.id);
                return _buildServiceCard(service, isSelected);
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  // Card de servicio con botón de info
  Widget _buildServiceCard(Service service, bool isSelected) {
    return GestureDetector(
      onTap: () {
        toggleServiceSelection(ref, service);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff721c80).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff721c80) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff721c80) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xff721c80) : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                // Info del servicio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (service.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            service.formattedDuration,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Precio
                Text(
                  service.formattedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff721c80),
                  ),
                ),
              ],
            ),
            // Botón de información (ícono !) en la esquina superior derecha
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showServiceInfoModal(service),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xff721c80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xff721c80),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para mostrar información detallada del servicio
  void _showServiceInfoModal(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: FutureBuilder<List<String>>(
            future: _fetchServicePhotos(service.id),
            builder: (context, snapshot) {
              final photos = snapshot.data ?? [];

              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Indicador de arrastre
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Galería de fotos
                  if (photos.isNotEmpty) ...[
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: photos[index],
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff721c80),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (photos.length > 1) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '${photos.length} fotos - Desliza para ver más',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ] else if (service.img != null) ...[
                    // Si no hay fotos en services_photos pero hay img en service
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: service.img!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Nombre del servicio
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff721c80),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Detalles (precio y duración)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff721c80).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xff721c80)),
                            const SizedBox(width: 6),
                            Text(
                              service.formattedDuration,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff721c80),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.green),
                            Text(
                              service.formattedPrice,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Descripción completa
                  if (service.description != null) ...[
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Botón para cerrar
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff721c80),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Construir horarios
  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        timeSlots.length,
        (index) => GestureDetector(
          onTap: () => setState(() => selectedTimeIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: selectedTimeIndex == index ? const Color(0xff721c80) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedTimeIndex == index ? const Color(0xff721c80) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Text(
              timeSlots[index],
              style: TextStyle(
                color: selectedTimeIndex == index ? Colors.white : Colors.black87,
                fontWeight: selectedTimeIndex == index ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Resumen de la reserva
  Widget _buildSummary(String totalPrice, String totalDuration) {
    final selectedServices = ref.watch(selectedServicesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de tu reserva:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xff721c80),
            ),
          ),
          const SizedBox(height: 12),
          ...selectedServices.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service.name)),
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duración total:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                totalDuration,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a pagar:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                totalPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xff721c80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Botón de confirmar
  Widget _buildConfirmButton(
    BuildContext context,
    List<Service> selectedServices,
    int selectedTimeIndex,
  ) {
    return GestureDetector(
      onTap: () async {
        if (selectedTimeIndex < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor selecciona un horario'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Mostrar diálogo de confirmación
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Reserva'),
            content: Text(
              '¿Confirmas tu reserva para ${timeSlots[selectedTimeIndex]}?\n\n'
              'Servicios: ${selectedServices.length}\n'
              'Total: ${ref.read(formattedTotalProvider)}',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff721c80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          // Mostrar loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                color: Color(0xff721c80),
              ),
            ),
          );

          try {
            // Obtener fecha seleccionada
            final selectedDate = ref.read(selectedBookingDateProvider);

            // Convertir hora seleccionada a formato TIME (HH:mm:ss)
            final timeSlot = timeSlots[selectedTimeIndex];
            final timeParts = _parseTimeSlot(timeSlot);

            // Calcular totales
            final totalPrice = selectedServices.fold<double>(
              0,
              (sum, service) => sum + service.price,
            );
            final totalDuration = selectedServices.fold<int>(
              0,
              (sum, service) => sum + service.durationMinutes,
            );

            // Preparar datos de servicios
            final servicesData = selectedServices.map((service) {
              return {
                'service_id': service.id,
                'service_name': service.name,
                'service_price': service.price,
                'service_duration': service.durationMinutes,
              };
            }).toList();

            // Crear la orden
            final order = await createOrder(
              orderDate: selectedDate,
              orderTime: timeParts,
              totalPrice: totalPrice,
              totalDuration: totalDuration,
              services: servicesData,
            );

            // Cerrar loading
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            if (order != null && context.mounted) {
              // Navegar a pantalla de confirmación con QR
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OrderConfirmationScreen(order: order),
                ),
              );

              // Resetear todo
              clearSelectedServices(ref);
              setState(() {
                _currentStep = 0;
                selectedTimeIndex = -1;
              });
            } else {
              // Error al crear orden
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al crear la reserva. Intenta nuevamente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            // Cerrar loading
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Mostrar error
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [
              Color(0xff721c80),
              Color.fromARGB(255, 196, 103, 169),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff721c80).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Confirmar Reserva",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Helper para convertir timeSlot (ej: "10:00 AM") a formato TIME (HH:mm:ss)
  String _parseTimeSlot(String timeSlot) {
    try {
      // Separar hora y período (AM/PM)
      final parts = timeSlot.split(' ');
      final timeParts = parts[0].split(':');
      final period = parts[1];

      int hour = int.parse(timeParts[0]);
      final minute = timeParts[1];

      // Convertir a formato 24 horas
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      // Formatear como HH:mm:ss
      return '${hour.toString().padLeft(2, '0')}:$minute:00';
    } catch (e) {
      return '09:00:00'; // Por defecto
    }
  }

  // Helper para parsear colores
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xff721c80); // Color por defecto
    }
  }

  // Helper para íconos
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'face':
        return Icons.face;
      case 'spa':
        return Icons.spa;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'mood':
        return Icons.mood;
      case 'brush':
        return Icons.brush;
      case 'content_cut':
        return Icons.content_cut;
      default:
        return Icons.spa;
    }
  }
}
