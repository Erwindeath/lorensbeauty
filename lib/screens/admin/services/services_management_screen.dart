import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/providers/services_provider.dart';
import '../../../providers/products_provider.dart';


class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServicesManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState
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
          // Filtro por categoría
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoría',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text('${cat.name} (${cat.serviceCount})'),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Lista de productos
          Expanded(
            child: _buildServicesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (){},//=>_navigateToProductForm(null),
        backgroundColor: const Color(0xff721c80),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_selectedCategoryId == null) {
      // Mostrar todos los productos
      final productsAsync = ref.watch(allProductsProvider);

      return productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No hay productos registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
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
    } else {
      // Mostrar productos por categoría
      final productsAsync =
          ref.watch(productsByCategoryProvider(_selectedCategoryId!));

      return productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No hay productos en esta categoría'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
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
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: product.hasPhotos
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.firstPhotoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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
                child: const Icon(Icons.shopping_bag),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (product.isFeatured)
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
            if (!product.active)
              const Icon(Icons.visibility_off, color: Colors.grey, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.formattedPrice,
                style: const TextStyle(
                    color: Color(0xff721c80), fontWeight: FontWeight.bold)),
            if (product.categoryName != null)
              Text('Categoría: ${product.categoryName}',
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
                    product.active ? Icons.visibility_off : Icons.visibility,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(product.active ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_featured',
              child: Row(
                children: [
                  Icon(
                    product.isFeatured ? Icons.star_border : Icons.star,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 8),
                  Text(product.isFeatured ? 'Quitar destacado' : 'Destacar'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                //_navigateToProductForm(product);
                break;
              case 'delete':
                _confirmDelete(product);
                break;
              case 'toggle_active':
                await updateProduct(
                  productId: product.id,
                  active: !product.active,
                );
                _refreshProducts();
                break;
              case 'toggle_featured':
                await updateProduct(
                  productId: product.id,
                  isFeatured: !product.isFeatured,
                );
                _refreshProducts();
                break;
            }
          },
        ),
      ),
    );
  }

 /* void _navigateToProductForm(Product? product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );

    if (result == true) {
      _refreshProducts();
    }
  }*/

  void _refreshProducts() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(featuredProductsProvider);
    if (_selectedCategoryId != null) {
      ref.invalidate(productsByCategoryProvider(_selectedCategoryId!));
    }
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar el producto "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteProduct(product.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshProducts();
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
