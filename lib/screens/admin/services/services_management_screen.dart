import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lorensbeauty/providers/services_provider.dart';
import 'service_form_screen.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState
    extends ConsumerState<ServicesManagementScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Servicios'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtro de categorías
          Container(
            padding: const EdgeInsets.all(16),
            child: categoriesAsync.when(
              data: (categories) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        checkmarkColor: Colors.white,
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() => _selectedCategoryId = null);
                        },
                        selectedColor: const Color(0xff721c80),
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == null
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((category) {
                        final isSelected = _selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${category.name} (${category.servicesCount})'),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected ? category.id : null;
                              });
                            },
                            selectedColor: const Color(0xff721c80),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error al cargar categorías'),
            ),
          ),

          // Lista de servicios
          Expanded(
            child: _buildServicesList(),
          ),
        ],
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

  Widget _buildServicesList() {
    // Obtener TODOS los servicios una sola vez
    final servicesAsync = ref.watch(allServicesProvider);

    return servicesAsync.when(
      data: (allServices) {
        // Filtrar localmente según la categoría seleccionada
        final filteredServices = _selectedCategoryId == null
            ? allServices
            : allServices
                .where((service) => service.categoryId == _selectedCategoryId)
                .toList();

        if (filteredServices.isEmpty) {
          return Center(
            child: Text(
              _selectedCategoryId == null
                  ? 'No hay servicios registrados'
                  : 'No hay servicios en esta categoría',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredServices.length,
          addAutomaticKeepAlives: true,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            return _buildServiceCard(filteredServices[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xff721c80)),
      ),
      error: (error, _) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: service.hasPhotos
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: service.firstPhotoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  memCacheWidth: 120,
                  memCacheHeight: 120,
                  maxWidthDiskCache: 120,
                  maxHeightDiskCache: 120,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xff721c80),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.spa),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (!service.isActive)
              const Icon(Icons.visibility_off, color: Colors.grey, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.formattedPrice,
                style: const TextStyle(
                    color: Color(0xff721c80), fontWeight: FontWeight.bold)),
            Text(service.formattedDuration,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            // Mostrar categoría solo cuando NO hay filtro activo
            if (_selectedCategoryId == null && service.categoryName != null)
              Text('Categoría: ${service.categoryName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
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
            PopupMenuItem(
              value: 'toggle_active',
              child: Row(
                children: [
                  Icon(
                    service.isActive ? Icons.visibility_off : Icons.visibility,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(service.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _navigateToServiceForm(service);
                break;
              case 'delete':
                _confirmDelete(service);
                break;
              case 'toggle_active':
                await updateService(
                  serviceId: service.id,
                  isActive: !service.isActive,
                );
                _refreshServices();
                break;
            }
          },
        ),
      ),
    );
  }

  void _navigateToServiceForm(Service? service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFormScreen(service: service),
      ),
    );

    if (result == true) {
      _refreshServices();
    }
  }

  void _refreshServices() {
    // Solo invalidamos allServicesProvider ya que ahora filtramos localmente
    ref.invalidate(allServicesProvider);
    ref.invalidate(serviceCategoriesProvider);
  }

  void _confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar el servicio "${service.name}"?'),
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
                _refreshServices();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
