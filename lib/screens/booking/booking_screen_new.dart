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
  // Categoria seleccionada en el filtro
  int? _selectedCategoryId;
  String _serviceSearchQuery = '';
  bool _hideScheduleFab = false;
  final TextEditingController _serviceSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scheduleSectionKey = GlobalKey();

  // Horarios disponibles segun configuracion admin (store_booking_slots)
  List<String> _availableTimeSlots = const [];
  bool _loadingTimeSlots = true;

  int selectedTimeIndex = -1;

  // Método para obtener fotos de un servicio
  Future<List<String>> _fetchServicePhotos(int serviceId) async {
    try {
      final response = await Supabase.instance.client
          .from('services_photos')
          .select('photo_url, uploaded_at, id')
          .eq('service_id', serviceId)
          .order('uploaded_at')
          .order('id');

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
    final selectedCategory = ref.read(selectedCategoryProvider);
    _selectedCategoryId = selectedCategory?.id;
    ref.read(selectedCategoryProvider.notifier).state = null;
    _loadTimeSlotsForDate(ref.read(selectedBookingDateProvider));
  }

  @override
  void dispose() {
    _serviceSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedBookingDateProvider, (previous, next) {
      if (previous == null ||
          previous.year != next.year ||
          previous.month != next.month ||
          previous.day != next.day) {
        _loadTimeSlotsForDate(next);
      }
    });

    final selectedServices = ref.watch(selectedServicesProvider);
    final totalPrice = ref.watch(formattedTotalProvider);
    final totalDuration = ref.watch(formattedDurationProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final servicesAsync = ref.watch(allServicesProvider);

    if (selectedServices.isEmpty && _hideScheduleFab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hideScheduleFab = false);
        }
      });
    }

    return Scaffold(
      floatingActionButton: selectedServices.isNotEmpty && !_hideScheduleFab
          ? FloatingActionButton.extended(
              onPressed: () async {
                setState(() => _hideScheduleFab = true);
                final targetContext = _scheduleSectionKey.currentContext;
                if (targetContext != null) {
                  await Scrollable.ensureVisible(
                    targetContext,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                }
              },
              backgroundColor: const Color(0xff721c80),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.schedule),
              label: const Text('Continuar con horario'),
            )
          : null,
      body: Column(
        children: [
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
                children: const [
                  Row(
                    children: [
                      Spacer(),
                      Text(
                        'Reserva tu momento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Elige tu experiencia y asegura tu cupo en minutos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  CustomDatePicker(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: _buildFixedFilters(categoriesAsync, servicesAsync),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceSelection(servicesAsync),
                    const SizedBox(height: 20),
                    if (selectedServices.isNotEmpty) ...[
                      Container(
                        key: _scheduleSectionKey,
                        child: const Text(
                          'Selecciona la hora perfecta',
                          style: TextStyle(
                            color: Color.fromARGB(255, 45, 42, 42),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTimeSlots(),
                      const SizedBox(height: 20),
                    ],
                    if (selectedServices.isNotEmpty) _buildSummary(totalPrice, totalDuration),
                    const SizedBox(height: 20),
                    if (selectedServices.isNotEmpty)
                      _buildConfirmButton(context, selectedServices),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    // Filtros fijos (categoria + busqueda condicional)
  Widget _buildFixedFilters(
    AsyncValue<List<ServiceCategory>> categoriesAsync,
    AsyncValue<List<Service>> servicesAsync,
  ) {
    final showSearch = servicesAsync.maybeWhen(
      data: (services) {
        final filteredByCategory = services
            .where((s) => _selectedCategoryId == null || s.categoryId == _selectedCategoryId)
            .toList();
        return filteredByCategory.length > 10;
      },
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        categoriesAsync.when(
          data: (categories) {
            final selectedExists = _selectedCategoryId == null
                ? true
                : categories.any((c) => c.id == _selectedCategoryId);
            final dropdownValue = selectedExists ? _selectedCategoryId : null;

            return DropdownButtonFormField<int?>(
              value: dropdownValue,
              decoration: InputDecoration(
                labelText: 'Tipo de servicio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xff721c80), width: 1.4),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Ver todos los servicios'),
                ),
                ...categories.map(
                  (cat) => DropdownMenuItem<int?>(
                    value: cat.id,
                    child: Text('${cat.name} (${cat.servicesCount})'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _serviceSearchQuery = '';
                  _serviceSearchController.clear();
                });
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: Color(0xff721c80)),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Error cargando categorias: $error'),
          ),
        ),
        if (showSearch) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _serviceSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xff721c80)),
                hintText: 'Buscar servicio por nombre...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: _serviceSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _serviceSearchController.clear();
                            _serviceSearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _serviceSearchQuery = value);
              },
            ),
          ),
        ],
      ],
    );
  }

  // Lista de servicios (scroll)
  Widget _buildServiceSelection(AsyncValue<List<Service>> servicesAsync) {
    final photoMap = ref.watch(servicePrimaryPhotosProvider).maybeWhen(
          data: (map) => map,
          orElse: () => const <int, String>{},
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Que servicio te vas a consentir hoy?',
          style: TextStyle(
            color: Color.fromARGB(255, 45, 42, 42),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        servicesAsync.when(
          data: (services) {
            final filteredByCategory = services
                .where((s) => _selectedCategoryId == null || s.categoryId == _selectedCategoryId)
                .toList();
            final query = _serviceSearchQuery.trim().toLowerCase();
            final filtered = query.isEmpty
                ? filteredByCategory
                : filteredByCategory.where((s) => s.name.toLowerCase().contains(query)).toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No hay servicios disponibles en esta categoria por ahora')),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final service = filtered[index];
                final isSelected = ref.watch(selectedServicesProvider).any((s) => s.id == service.id);
                final thumbnailUrl = photoMap[service.id] ?? service.img;
                return _buildServiceCard(service, isSelected, thumbnailUrl);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: Color(0xff721c80))),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  // Card de servicio con boton de info
  Widget _buildServiceCard(Service service, bool isSelected, String? thumbnailUrl) {
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
        child: Row(
          children: [
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
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            _buildServiceThumb(thumbnailUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xff721c80).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      service.formattedDuration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff721c80),
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showServiceInfoModal(service),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xff721c80).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xff721c80),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildServiceThumb(String? photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade200,
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.spa,
                  color: Color(0xff721c80),
                  size: 22,
                ),
              )
            : const Icon(
                Icons.spa,
                color: Color(0xff721c80),
                size: 22,
              ),
      ),
    );
  }

  // Modal para mostrar informacion detallada del servicio
  void _showServiceInfoModal(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
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
              final photoUrls = photos.isNotEmpty
                  ? photos
                  : ((service.img != null && service.img!.isNotEmpty)
                      ? <String>[service.img!]
                      : <String>[]);

              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
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
                  if (photoUrls.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 260,
                        child: PageView.builder(
                          itemCount: photoUrls.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: photoUrls[index],
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
                                      child: const Icon(Icons.image_not_supported, size: 50),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.42),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '${index + 1}/${photoUrls.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff721c80),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (photoUrls.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: photoUrls[index],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported, size: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff721c80),
                    ),
                  ),
                  const SizedBox(height: 15),
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
                  if (service.description != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xff721c80).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xff721c80).withOpacity(0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome, size: 18, color: Color(0xff721c80)),
                              SizedBox(width: 8),
                              Text(
                                'Descripcion del servicio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff721c80),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            service.description!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade800,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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
    if (_loadingTimeSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
      );
    }

    if (_availableTimeSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No hay horarios disponibles para este dia.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        _availableTimeSlots.length,
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
              _availableTimeSlots[index],
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
  ) {
    return GestureDetector(
      onTap: () async {
        final selectedSlot =
            (selectedTimeIndex >= 0 && selectedTimeIndex < _availableTimeSlots.length)
                ? _availableTimeSlots[selectedTimeIndex]
                : null;

        if (selectedSlot == null) {
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
            title: const Text('Finalizar reserva'),
            content: Text(
              '¿Confirmas tu reserva para $selectedSlot?\n\n'
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
            final timeSlot = selectedSlot;
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
                selectedTimeIndex = -1;
                _hideScheduleFab = false;
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
            "Reservar ahora",
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

  Future<void> _loadTimeSlotsForDate(DateTime date) async {
    setState(() {
      _loadingTimeSlots = true;
      selectedTimeIndex = -1;
    });

    try {
      final rows = await Supabase.instance.client
          .from('store_booking_slots')
          .select('slot_time')
          .eq('weekday', date.weekday)
          .order('slot_time');

      final slots = (rows as List)
          .map((r) => r['slot_time']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .map(_formatSlotForDisplay)
          .toList();

      if (!mounted) return;
      setState(() {
        _availableTimeSlots = slots;
        _loadingTimeSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableTimeSlots = const [];
        _loadingTimeSlots = false;
      });
    }
  }

  String _formatSlotForDisplay(String raw) {
    final normalized = _normalizeDbTime(raw);
    final parts = normalized.split(':');
    if (parts.length < 2) return normalized;

    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _normalizeDbTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    return '$h:$m';
  }
}
















