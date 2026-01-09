import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Producto no encontrado'),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // AppBar con foto principal
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xff721c80),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildPhotoGallery(product),
                ),
              ),

              // Contenido del producto
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge destacado
                          if (product.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Destacado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Nombre del producto
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff721c80),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Marca
                          if (product.brand != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.verified,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  product.brand!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Categoría
                          if (product.categoryName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.categoryName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Precio
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xff721c80).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Precio:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  product.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff721c80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Descripción
                    if (product.description != null) ...[
                      _buildSection(
                        icon: Icons.description,
                        title: 'Descripción',
                        content: product.description!,
                      ),
                      const Divider(height: 1),
                    ],

                    // Beneficios
                    if (product.benefits.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Color(0xff721c80), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Beneficios',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...product.benefits.map((benefit) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xff721c80),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          benefit,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],

                    // Ingredientes
                    if (product.ingredients != null) ...[
                      _buildSection(
                        icon: Icons.science,
                        title: 'Ingredientes',
                        content: product.ingredients!,
                      ),
                      const Divider(height: 1),
                    ],

                    // Modo de uso
                    if (product.howToUse != null) ...[
                      _buildSection(
                        icon: Icons.info_outline,
                        title: 'Modo de Uso',
                        content: product.howToUse!,
                      ),
                      const Divider(height: 1),
                    ],

                    // Explicación del tratamiento
                    if (product.treatmentExplanation != null) ...[
                      _buildSection(
                        icon: Icons.medical_services,
                        title: 'Información del Tratamiento',
                        content: product.treatmentExplanation!,
                      ),
                      const Divider(height: 1),
                    ],

                    // Espacio para el botón flotante
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xff721c80),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
            ],
          ),
        ),
      ),
      // Botón flotante de WhatsApp
      floatingActionButton: productAsync.when(
        data: (product) => product != null
            ? FloatingActionButton.extended(
                onPressed: () => _openWhatsApp(context, product),
                backgroundColor: const Color(0xff25D366),
                icon: const Icon(Icons.chat, size: 28),
                label: const Text(
                  'Solicitar por WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPhotoGallery(Product product) {
    if (!product.hasPhotos) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
        ),
      );
    }

    if (product.photos.length == 1) {
      return Image.network(
        product.firstPhotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 80),
        ),
      );
    }

    return PageView.builder(
      itemCount: product.photos.length,
      itemBuilder: (context, index) {
        final photo = product.photos[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 80),
              ),
            ),
            // Indicador de página
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${index + 1}/${product.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff721c80), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, Product product) async {
    final message = '''
¡Hola! 👋

Estoy interesada/o en el siguiente producto:

📦 *${product.name}*
${product.brand != null ? '🏷️ Marca: ${product.brand}' : ''}
💰 Precio: ${product.formattedPrice}

${product.description ?? ''}

¿Está disponible? ¿Cómo puedo adquirirlo?

Gracias!
''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/593982316315?text=$encodedMessage';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
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
}
