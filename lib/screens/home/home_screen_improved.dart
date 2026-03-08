import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/components/carousel.dart';
import 'package:lorensbeauty/providers/services_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreenImproved extends ConsumerStatefulWidget {
  final VoidCallback? onCategorySelected;

  const HomeScreenImproved({Key? key, this.onCategorySelected}) : super(key: key);

  @override
  ConsumerState<HomeScreenImproved> createState() => _HomeScreenImprovedState();
}

class _HomeScreenImprovedState extends ConsumerState<HomeScreenImproved> {
  late final Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsWithPhotos();
  }

  Future<List<Map<String, dynamic>>> _fetchProductsWithPhotos() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('id, name, description, category_id, product_photos(photo_url)')
          .eq('active', true)
          .order('created_at', ascending: false)
          .limit(10);

      final products = List<Map<String, dynamic>>.from(response as List);
      for (var product in products) {
        final photos = product['product_photos'];
        if (photos != null && photos is List && photos.isNotEmpty) {
          product['img'] = photos[0]['photo_url'];
        } else {
          product['img'] = null;
        }
        product.remove('product_photos');
      }
      return products;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color.fromARGB(255, 196, 103, 169)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Loren's Beauty",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reserva tu cita o explora servicios y productos.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onCategorySelected != null) {
                          widget.onCategorySelected!();
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xff721c80)),
                      label: const Text(
                        'Reservar ahora',
                        style: TextStyle(
                          color: Color(0xff721c80),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Carousel(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Servicios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff721c80)),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (widget.onCategorySelected != null) {
                        widget.onCategorySelected!();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.grid_view, size: 16, color: Color(0xff721c80)),
                          SizedBox(width: 6),
                          Text(
                            'Ver todo',
                            style: TextStyle(
                              color: Color(0xff721c80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No hay categorias disponibles')),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: categories.length > 6 ? 6 : categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCompactCategoryCard(category);
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Color(0xff721c80))),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Error al cargar categorias')),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Productos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff721c80)),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navegar a productos
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xff721c80)),
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: Color(0xff721c80))),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No hay productos disponibles')),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryCard(ServiceCategory category) {
    final color = _parseColor(category.colorHex);
    final serviceCountAsync = ref.watch(servicesByCategoryProvider(category.id));

    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        if (widget.onCategorySelected != null) {
          widget.onCategorySelected!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
            Icon(_getIconData(category.iconName), size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            serviceCountAsync.when(
              data: (services) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${services.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _showProductModal(product),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product_${product['id']}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product['img'] != null
                    ? CachedNetworkImage(
                        imageUrl: product['img'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 30),
                        ),
                      )
                    : Container(
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.shopping_bag, size: 30, color: Colors.grey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'] ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductModal(Map<String, dynamic> product) {
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
          child: ListView(
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
              if (product['img'] != null)
                Hero(
                  tag: 'product_${product['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: product['img'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                product['name'] ?? 'Sin nombre',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff721c80)),
              ),
              const SizedBox(height: 10),
              if (product['description'] != null) ...[
                const Text(
                  'Descripcion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  product['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff721c80),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mas informacion', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xff721c80);
    }
  }

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
