import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/products_provider.dart';

class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends ConsumerState<CategoriesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No hay categorías registradas'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(null),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
    );
  }

  Widget _buildCategoryCard(ProductCategory category) {
    final color = _parseColor(category.colorHex ?? '#721c80');
    final icon = _getIconData(category.iconName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(category.description ?? 'Sin descripción'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xff721c80)),
              onPressed: () => _showCategoryDialog(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(category),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(ProductCategory? category) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController =
        TextEditingController(text: category?.description ?? '');
    String selectedIcon = category?.iconName ?? 'category';
    String selectedColor = category?.colorHex ?? '#721c80';
    String categoryType = category?.categoryType ?? 'product';
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Ícono',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'face', child: Text('Rostro (face)')),
                    DropdownMenuItem(value: 'spa', child: Text('Spa (spa)')),
                    DropdownMenuItem(value: 'brush', child: Text('Cepillo (brush)')),
                    DropdownMenuItem(value: 'palette', child: Text('Paleta (palette)')),
                    DropdownMenuItem(
                        value: 'shopping_bag', child: Text('Bolsa (shopping_bag)')),
                    DropdownMenuItem(
                        value: 'favorite', child: Text('Corazón (favorite)')),
                    DropdownMenuItem(
                        value: 'local_florist', child: Text('Flor (local_florist)')),
                    DropdownMenuItem(
                        value: 'category', child: Text('Categoría (category)')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedIcon = value ?? 'category');
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '#721c80', child: Text('Morado')),
                    DropdownMenuItem(value: '#E91E63', child: Text('Rosa')),
                    DropdownMenuItem(value: '#9C27B0', child: Text('Púrpura')),
                    DropdownMenuItem(value: '#3F51B5', child: Text('Azul')),
                    DropdownMenuItem(value: '#FF5722', child: Text('Naranja')),
                    DropdownMenuItem(value: '#795548', child: Text('Café')),
                    DropdownMenuItem(value: '#4CAF50', child: Text('Verde')),
                    DropdownMenuItem(value: '#FFC107', child: Text('Amarillo')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedColor = value ?? '#721c80');
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoryType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'product', child: Text('Producto')),
                    DropdownMenuItem(value: 'service', child: Text('Servicio')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => categoryType = value ?? 'product');
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Activa'),
                  value: isActive,
                  activeColor: const Color(0xff721c80),
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                await _saveCategory(
                  category?.id,
                  nameController.text,
                  descController.text,
                  selectedIcon,
                  selectedColor,
                  categoryType,
                  isActive,
                );

                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory(
    int? categoryId,
    String name,
    String description,
    String iconName,
    String colorHex,
    String categoryType,
    bool isActive,
  ) async {
    try {
      if (categoryId == null) {
        // Crear nueva categoría
        await Supabase.instance.client.from('categories').insert({
          'name': name,
          'description': description,
          'icon_name': iconName,
          'color_hex': colorHex,
          'is_active': isActive,
          'display_order': 0,
        });
      } else {
        // Actualizar categoría existente
        await Supabase.instance.client.from('categories').update({
          'name': name,
          'description': description,
          'icon_name': iconName,
          'color_hex': colorHex,
          'is_active': isActive,
        }).eq('id', categoryId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(categoriesProvider);
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
    }
  }

  void _confirmDelete(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la categoría "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
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

  Future<void> _deleteCategory(int categoryId) async {
    try {
      await Supabase.instance.client
          .from('categories')
          .delete()
          .eq('id', categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(categoriesProvider);
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
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xff721c80);
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'face':
        return Icons.face;
      case 'spa':
        return Icons.spa;
      case 'brush':
        return Icons.brush;
      case 'palette':
        return Icons.palette;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'favorite':
        return Icons.favorite;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.category;
    }
  }
}

