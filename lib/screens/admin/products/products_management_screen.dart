import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/products_provider.dart';
import 'product_form_screen.dart';

class ProductsManagementScreen extends ConsumerStatefulWidget {
  const ProductsManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState
    extends ConsumerState<ProductsManagementScreen> {
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
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Productos'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xff721c80)),
        ),
        error: (error, _) => Center(child: Text('Error: ${error.toString()}')),
        data: (products) {
          final categories = _buildCategoryOptions(products);
          final filtered = _filterProducts(products);

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
                          borderSide: BorderSide(color: Color(0xff721c80), width: 1.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Todas las categorias (${products.length})'),
                        ),
                        ...categories.map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text('${cat.name} (${cat.count})'),
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
                      prefixIcon: const Icon(Icons.search, color: Color(0xff721c80)),
                      hintText: 'Buscar producto...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    ? const Center(child: Text('No se encontraron productos'))
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
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) => _buildProductCard(filtered[index]),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToProductForm(null),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  List<_CategoryOption> _buildCategoryOptions(List<Product> products) {
    final counter = <int, _CategoryOption>{};
    for (final p in products) {
      final id = p.categoryId;
      if (id == null) continue;
      final name = (p.categoryName ?? 'Sin categoria').trim();
      if (!counter.containsKey(id)) {
        counter[id] = _CategoryOption(id: id, name: name, count: 0);
      }
      counter[id] = _CategoryOption(
        id: id,
        name: counter[id]!.name,
        count: counter[id]!.count + 1,
      );
    }

    final list = counter.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          (p.categoryName?.toLowerCase().contains(_searchQuery) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildProductCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: product.hasPhotos
                  ? Image.network(
                      product.firstPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.shopping_bag, size: 32),
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
                        product.name,
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
                                color: const Color(0xFFFFD700),
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
                            _navigateToProductForm(product);
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
                  ],
                ),
                Text(
                  product.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xff721c80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.categoryName != null)
                  Text(
                    'Categoria: ${product.categoryName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.isFeatured)
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    if (!product.active) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.visibility_off, color: Colors.grey, size: 16),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProductForm(Product? product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );

    if (result == true) {
      _refreshProducts();
    }
  }

  void _refreshProducts() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(featuredProductsProvider);
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text('Estas seguro de eliminar el producto "${product.name}"?'),
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

class _CategoryOption {
  final int id;
  final String name;
  final int count;

  const _CategoryOption({
    required this.id,
    required this.name,
    required this.count,
  });
}
