import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/services_provider.dart';
import '../../../helpers/image_upload_helper.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final Service? service;

  const ServiceFormScreen({Key? key, this.service}) : super(key: key);

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  int? _selectedCategoryId;
  bool _isActive = true;
  bool _isLoading = false;

  // Lista de imágenes seleccionadas (para nuevo servicio)
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _loadServiceData();
    }
  }

  void _loadServiceData() {
    final service = widget.service!;
    _nameController.text = service.name;
    _descriptionController.text = service.description ?? '';
    _priceController.text = service.price.toString();
    _durationController.text = service.durationMinutes.toString();
    _selectedCategoryId = service.categoryId;
    _isActive = service.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Nuevo Servicio' : 'Editar Servicio'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Servicio *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),

            // Categoría
            categoriesAsync.when(
              data: (categories) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text('${cat.name} (${cat.servicesCount})'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona una categoría' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showCreateCategoryDialog(),
                      icon: const Icon(Icons.add_circle),
                      color: const Color(0xff721c80),
                      iconSize: 32,
                      tooltip: 'Crear nueva categoría',
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error al cargar categorías'),
            ),
            const SizedBox(height: 16),

            // Precio
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio *',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El precio es requerido';
                if (double.tryParse(value!) == null) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Duración
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos) *',
                border: OutlineInputBorder(),
                helperText: 'Duración aproximada del servicio',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La duración es requerida';
                final duration = int.tryParse(value!);
                if (duration == null || duration <= 0) {
                  return 'Duración inválida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                helperText: 'Descripción detallada del servicio',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Switch Activo
            SwitchListTile(
              title: const Text('Servicio Activo'),
              subtitle: const Text('Los clientes pueden ver y reservar este servicio'),
              value: _isActive,
              activeColor: const Color(0xff721c80),
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            const SizedBox(height: 24),

            // Sección de selección de imágenes (solo para nuevo servicio)
            if (widget.service == null) ...[
              _buildImageSelectionSection(),
              const SizedBox(height: 24),
            ],

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.service == null ? 'Crear Servicio' : 'Actualizar Servicio',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // Gestión de fotos (solo si el servicio ya existe)
            if (widget.service != null) ...[
              const Divider(height: 32),
              _buildPhotosSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fotos del Servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
              ),
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              label: const Text('Agregar Foto'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Las fotos se subirán cuando crees el servicio',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        if (_selectedImages.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey[400]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay fotos seleccionadas',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca "Agregar Foto" para seleccionar imágenes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        padding: const EdgeInsets.all(4),
                      ),
                      onPressed: () {
                        setState(() => _selectedImages.removeAt(index));
                      },
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final serviceAsync = ref.watch(serviceByIdProvider(widget.service!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fotos del Servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _uploadPhoto(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
              ),
              icon: const Icon(Icons.add_a_photo, size: 20),
              label: const Text('Agregar Foto'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        serviceAsync.when(
          data: (service) {
            if (service?.photos.isEmpty ?? true) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.photo_library,
                          size: 64,
                          color: Colors.grey[400]
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay fotos agregadas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca "Agregar Foto" para subir imágenes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: service!.photos.length,
              itemBuilder: (context, index) {
                final photo = service.photos[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo.photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => _deletePhoto(photo.id),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error al cargar fotos'),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      final imageFile = await ImageUploadHelper.showImageSourceDialog(context);

      if (imageFile != null) {
        setState(() {
          _selectedImages.add(imageFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);
      final durationMinutes = int.parse(_durationController.text);

      if (widget.service == null) {
        // Crear nuevo servicio
        final newService = await createService(
          name: _nameController.text,
          price: price,
          durationMinutes: durationMinutes,
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        );

        if (newService == null) {
          throw Exception('No se pudo crear el servicio');
        }

        // Subir imágenes si hay seleccionadas
        if (_selectedImages.isNotEmpty) {
          int uploadedCount = 0;
          for (var imageFile in _selectedImages) {
            final photoUrl = await ImageUploadHelper.uploadServiceImage(
              imageFile,
              newService.id,
            );

            if (photoUrl != null) {
              await addServicePhoto(
                serviceId: newService.id,
                photoUrl: photoUrl,
              );
              uploadedCount++;
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Servicio creado con $uploadedCount foto${uploadedCount != 1 ? 's' : ''}'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servicio creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        // Actualizar servicio existente
        final success = await updateService(
          serviceId: widget.service!.id,
          name: _nameController.text,
          price: price,
          durationMinutes: durationMinutes,
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          isActive: _isActive,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servicio actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('No se pudo actualizar el servicio');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nueva Categoría de Servicio'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Categoría *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'El nombre es requerido' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        // Crear la categoría directamente en Supabase
                        final response = await Supabase.instance.client
                            .from('service_categories')
                            .insert({
                          'name': nameController.text,
                          'description': descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                          'is_active': true,
                        }).select('id').single();

                        final newCategoryId = response['id'] as int;

                        if (context.mounted) {
                          // Invalidar el provider para recargar categorías
                          ref.invalidate(serviceCategoriesProvider);

                          Navigator.pop(context, newCategoryId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Categoría creada exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al crear categoría: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setDialogState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    // Si se creó una categoría, seleccionarla automáticamente
    if (result != null) {
      setState(() => _selectedCategoryId = result);
    }
  }

  Future<void> _uploadPhoto() async {
    if (widget.service == null) return;

    try {
      // Mostrar diálogo para seleccionar fuente
      final imageFile = await ImageUploadHelper.showImageSourceDialog(context);

      if (imageFile == null) return;

      setState(() => _isLoading = true);

      // Subir imagen a Storage
      final photoUrl = await ImageUploadHelper.uploadServiceImage(
        imageFile,
        widget.service!.id,
      );

      if (photoUrl == null) {
        throw Exception('Error al subir la imagen');
      }

      // Guardar URL en la base de datos
      final success = await addServicePhoto(
        serviceId: widget.service!.id,
        photoUrl: photoUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Refrescar las fotos
        ref.invalidate(serviceByIdProvider(widget.service!.id));
      } else {
        throw Exception('Error al guardar la foto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await deleteServicePhoto(photoId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(serviceByIdProvider(widget.service!.id));
      }
    }
  }
}
