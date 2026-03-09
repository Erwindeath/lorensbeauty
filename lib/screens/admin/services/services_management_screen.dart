import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lorensbeauty/providers/services_provider.dart';
import 'package:lorensbeauty/screens/admin/services/service_form_screen.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState
    extends ConsumerState<ServicesManagementScreen> {
  int? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allServicesProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final servicePhotosAsync = ref.watch(servicePrimaryPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Servicios'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: servicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
        error: (error, _) => Center(child: Text('Error: ${error.toString()}')),
        data: (services) {
          final categories = categoriesAsync.maybeWhen(
            data: (list) => list,
            orElse: () => <ServiceCategory>[],
          );
          final categoryNameById = {
            for (final c in categories) c.id: c.name,
          };
          final filtered = _filterServices(services, categoryNameById);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide:
                              BorderSide(color: Color(0xff721c80), width: 1.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Todas las categorias (${services.length})'),
                        ),
                        ...categories.map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text('${cat.name} (${cat.serviceCount})'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.search, color: Color(0xff721c80)),
                          hintText: 'Buscar servicio...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.trim().toLowerCase());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No se encontraron servicios'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 600
                                  ? 3
                                  : 2;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) => _buildServiceCard(
                              filtered[index],
                              categoryNameById,
                              servicePhotosAsync.maybeWhen(
                                data: (map) => map[filtered[index].id],
                                orElse: () => null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToServiceForm(null),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
    );
  }

  List<Service> _filterServices(
    List<Service> services,
    Map<int, String> categoryNameById,
  ) {
    return services.where((s) {
      final matchesCategory =
          _selectedCategoryId == null || s.categoryId == _selectedCategoryId;
      final categoryText = s.categoryId == null
          ? ''
          : (categoryNameById[s.categoryId!] ?? '').toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery) ||
          categoryText.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildServiceCard(
    Service service,
    Map<int, String> categoryNameById,
    String? primaryPhotoUrl,
  ) {
    final categoryName = service.categoryId == null
        ? 'Sin categoria'
        : (categoryNameById[service.categoryId!] ?? 'Categoria ${service.categoryId}');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: ((primaryPhotoUrl != null && primaryPhotoUrl.isNotEmpty) ||
                      (service.img != null && service.img!.isNotEmpty))
                  ? Image.network(
                      primaryPhotoUrl ?? service.img!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.spa, size: 32),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xff721c80)),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_active',
                          child: Row(
                            children: [
                              Icon(
                                service.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(service.isActive ? 'Desactivar' : 'Activar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            _navigateToServiceForm(service);
                            break;
                          case 'toggle_active':
                            await _toggleServiceActive(service);
                            break;
                          case 'delete':
                            _confirmDeleteService(service);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                Text(
                  service.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xff721c80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  service.formattedDuration,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Categoria: $categoryName',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (!service.isActive)
                  const Icon(Icons.visibility_off, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServiceActive(Service service) async {
    await updateService(
      serviceId: service.id,
      categoryId: service.categoryId,
      isActive: !service.isActive,
    );

    ref.invalidate(allServicesProvider);
    ref.invalidate(serviceCategoriesProvider);
  }

  Future<void> _navigateToServiceForm(Service? service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceFormScreen(service: service)),
    );
    if (result == true) {
      ref.invalidate(allServicesProvider);
      ref.invalidate(serviceCategoriesProvider);
    }
  }

  void _confirmDeleteService(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text('Estas seguro de eliminar el servicio "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteService(service.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servicio eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
                ref.invalidate(allServicesProvider);
                ref.invalidate(serviceCategoriesProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
