import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/products_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _howToUseController = TextEditingController();

  List<String> _benefits = [];
  final _benefitController = TextEditingController();

  int? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _treatmentController.text = product.treatmentExplanation ?? '';
    _priceController.text = product.price.toString();
    _brandController.text = product.brand ?? '';
    _ingredientsController.text = product.ingredients ?? '';
    _howToUseController.text = product.howToUse ?? '';
    _benefits = List.from(product.benefits);
    _selectedCategoryId = product.categoryId;
    _isFeatured = product.isFeatured;
    _isActive = product.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _treatmentController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _howToUseController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto'),
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
                labelText: 'Nombre del Producto *',
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
                                  child: Text('${cat.name} (${cat.productCount})'),
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

            // Marca
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Beneficios
            _buildBenefitsSection(),
            const SizedBox(height: 16),

            // Ingredientes
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredientes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Modo de uso
            TextFormField(
              controller: _howToUseController,
              decoration: const InputDecoration(
                labelText: 'Modo de Uso',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Explicación del tratamiento
            TextFormField(
              controller: _treatmentController,
              decoration: const InputDecoration(
                labelText: 'Explicación del Tratamiento',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Switches
            SwitchListTile(
              title: const Text('Producto Destacado'),
              subtitle: const Text('Aparecerá en la página principal'),
              value: _isFeatured,
              activeColor: const Color(0xff721c80),
              onChanged: (value) {
                setState(() => _isFeatured = value);
              },
            ),
            SwitchListTile(
              title: const Text('Producto Activo'),
              subtitle: const Text('Los clientes pueden ver este producto'),
              value: _isActive,
              activeColor: const Color(0xff721c80),
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            const SizedBox(height: 24),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.product == null ? 'Crear Producto' : 'Actualizar Producto',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // Gestión de fotos (solo si el producto ya existe)
            if (widget.product != null) ...[
              const Divider(height: 32),
              _buildPhotosSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beneficios',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _benefitController,
                decoration: const InputDecoration(
                  hintText: 'Agregar beneficio',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_benefitController.text.isNotEmpty) {
                  setState(() {
                    _benefits.add(_benefitController.text);
                    _benefitController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add_circle, color: Color(0xff721c80)),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_benefits.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _benefits.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline,
                      color: Color(0xff721c80)),
                  title: Text(_benefits[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _benefits.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final productAsync = ref.watch(productByIdProvider(widget.product!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos del Producto',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nota: La gestión completa de fotos (subir desde galería) requiere configuración adicional de Storage en Supabase.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        productAsync.when(
          data: (product) {
            if (product?.photos.isEmpty ?? true) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay fotos agregadas'),
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
              itemCount: product!.photos.length,
              itemBuilder: (context, index) {
                final photo = product.photos[index];
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);

      if (widget.product == null) {
        // Crear nuevo producto
        final newProduct = await createProduct(
          name: _nameController.text,
          price: price,
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          treatmentExplanation: _treatmentController.text.isEmpty
              ? null
              : _treatmentController.text,
          brand: _brandController.text.isEmpty ? null : _brandController.text,
          benefits: _benefits.isEmpty ? null : _benefits,
          ingredients: _ingredientsController.text.isEmpty
              ? null
              : _ingredientsController.text,
          howToUse: _howToUseController.text.isEmpty
              ? null
              : _howToUseController.text,
          isFeatured: _isFeatured,
        );

        if (newProduct != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('No se pudo crear el producto');
        }
      } else {
        // Actualizar producto existente
        final success = await updateProduct(
          productId: widget.product!.id,
          name: _nameController.text,
          price: price,
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          treatmentExplanation: _treatmentController.text.isEmpty
              ? null
              : _treatmentController.text,
          brand: _brandController.text.isEmpty ? null : _brandController.text,
          benefits: _benefits.isEmpty ? null : _benefits,
          ingredients: _ingredientsController.text.isEmpty
              ? null
              : _ingredientsController.text,
          howToUse: _howToUseController.text.isEmpty
              ? null
              : _howToUseController.text,
          isFeatured: _isFeatured,
          active: _isActive,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('No se pudo actualizar el producto');
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
      final success = await deleteProductPhoto(photoId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(productByIdProvider(widget.product!.id));
      }
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nueva Categoría'),
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
                const SizedBox(height: 8),
                const Text(
                  'La categoría se creará como tipo "Producto"',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            .from('categories')
                            .insert({
                          'name': nameController.text,
                          'category_type': 'product',
                          'is_active': true,
                        }).select('id').single();

                        final newCategoryId = response['id'] as int;

                        if (context.mounted) {
                          // Invalidar el provider para recargar categorías
                          ref.invalidate(categoriesProvider);

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
}
