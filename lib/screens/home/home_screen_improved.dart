import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lorensbeauty/providers/services_provider.dart';
import 'package:lorensbeauty/screens/orders/my_orders_screen.dart';
import 'package:lorensbeauty/screens/products/product_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreenImproved extends ConsumerStatefulWidget {
  final VoidCallback? onCategorySelected;

  const HomeScreenImproved({Key? key, this.onCategorySelected}) : super(key: key);

  @override
  ConsumerState<HomeScreenImproved> createState() => _HomeScreenImprovedState();
}

class _HomeScreenImprovedState extends ConsumerState<HomeScreenImproved> {
  late final Future<Map<String, dynamic>?> _nextOrderFuture;
  late final Future<List<Map<String, dynamic>>> _promoOrRecentProductsFuture;
  late final Future<String> _todayScheduleFuture;

  @override
  void initState() {
    super.initState();
    _nextOrderFuture = _fetchNextOrder();
    _promoOrRecentProductsFuture = _fetchPromoOrRecentProducts();
    _todayScheduleFuture = _fetchTodaySchedule();
  }

  Future<Map<String, dynamic>?> _fetchNextOrder() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final rows = await Supabase.instance.client
          .from('orders')
          .select('id, order_date, order_time, status, total_price')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'confirmed'])
          .gte('order_date', todayStr)
          .order('order_date')
          .order('order_time')
          .limit(1);

      if ((rows as List).isEmpty) return null;
      final order = Map<String, dynamic>.from(rows.first);

      final services = await Supabase.instance.client
          .from('order_services')
          .select('service_name')
          .eq('order_id', order['id']);

      order['services'] = services;
      return order;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPromoOrRecentProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('id, name, price, brand, is_featured, created_at, product_photos(photo_url)')
          .eq('active', true)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false)
          .limit(8);

      final products = List<Map<String, dynamic>>.from(response as List);
      for (final product in products) {
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

  Future<String> _fetchTodaySchedule() async {
    try {
      final weekday = DateTime.now().weekday;
      final rows = await Supabase.instance.client
          .from('store_booking_slots')
          .select('slot_time')
          .eq('weekday', weekday)
          .order('slot_time');

      final slots = (rows as List)
          .map((r) => r['slot_time']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .map(_normalizeHour)
          .toList();

      if (slots.isEmpty) return 'Hoy cerrado';
      return 'Hoy: ${slots.first} - ${slots.last}';
    } catch (_) {
      return 'Horario no disponible';
    }
  }

  String _normalizeHour(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color(0xffC46FA9)],
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
                    children: [
                      const Expanded(
                        child: Text(
                          "Loren's Beauty",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_none, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu espacio para reservar, seguir citas y explorar productos.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onCategorySelected,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Reservar en 2 pasos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xff721c80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('Mis reservas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _nextOrderFuture,
                builder: (context, snapshot) {
                  final order = snapshot.data;
                  if (order == null) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xff721c80).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_available, color: Color(0xff721c80)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Aun no tienes una proxima cita. Agenda la tuya y asegura tu cupo.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final date = order['order_date']?.toString() ?? '';
                  final time = _normalizeHour(order['order_time']?.toString() ?? '--:--');
                  final firstService = (order['services'] as List?)?.isNotEmpty == true
                      ? order['services'][0]['service_name']?.toString() ?? 'Servicio'
                      : 'Servicio';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffEEF6FF), Color(0xffF8EEFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffDCC8F1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xff721c80),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstService,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff2F1E3A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$date - $time',
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${(order['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: Color(0xff721c80),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FutureBuilder<String>(
                future: _todayScheduleFuture,
                builder: (context, snapshot) {
                  final text = snapshot.data ?? 'Cargando horario...';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18, color: Color(0xff721c80)),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4B4451),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Servicios',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff721c80),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onCategorySelected,
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final topCategories = categories.take(4).toList();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: topCategories
                        .map(
                          (category) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: category == topCategories.last ? 0 : 8,
                              ),
                              child: _serviceQuickCard(category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff721c80)),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding:  EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Productos',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff721c80),
                    ),
                  ),
                   Text(
                    'Actualizados recientemente',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _promoOrRecentProductsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xff721c80)),
                    ),
                  );
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No hay productos disponibles por ahora.'),
                  );
                }
                return SizedBox(
                  height: 196,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _productQuickCard(products[index]),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _serviceQuickCard(ServiceCategory category) {
    final color = _parseColor(category.colorHex);
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        widget.onCategorySelected?.call();
      },
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.78)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(_getIconData(category.iconName), color: Colors.white, size: 24),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productQuickCard(Map<String, dynamic> product) {
    final priceRaw = product['price'];
    final price = priceRaw is num ? priceRaw.toDouble() : 0.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product['id'] as int),
          ),
        );
      },
      child: Container(
        width: 146,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: product['img'] != null
                  ? CachedNetworkImage(
                      imageUrl: product['img'] as String,
                      height: 98,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _productPlaceholder(),
                    )
                  : _productPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Producto',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xff721c80),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      height: 98,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'face':
        return Icons.face_retouching_natural;
      case 'spa':
        return Icons.spa_outlined;
      case 'brush':
        return Icons.brush_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'favorite':
        return Icons.favorite_border;
      default:
        return Icons.star_outline;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xff721c80);
    }
  }
}
