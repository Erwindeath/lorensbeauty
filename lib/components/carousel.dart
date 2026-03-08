import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  const Carousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <_PromoItem>[
      const _PromoItem(
        title: 'Luce increible',
        subtitle: 'Ahorra en tus tratamientos',
        cta: 'Ver promos',
        imageUrl:
            'https://images.squarespace-cdn.com/content/v1/5e867df9747b0e555c337eef/1589945925617-4NY8TG8F76FH1O0P46FW/Kampaamo-helsinki-hair-design-balayage-hiustenpidennys-varjays.png',
      ),
      const _PromoItem(
        title: 'Reserva tu cita',
        subtitle: 'Rapido y sin llamadas',
        cta: 'Reservar ahora',
        imageUrl:
            'https://img.grouponcdn.com/bynder/2sLSquS1xGWk4QjzYuL7h461CDsJ/2s-2048x1229/v1/sc600x600.jpg',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: CarouselSlider.builder(
        itemCount: items.length,
        options: CarouselOptions(
          height: 178,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          enlargeCenterPage: true,
          viewportFraction: 0.92,
        ),
        itemBuilder: (context, index, realIndex) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color.fromARGB(255, 196, 103, 169)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              item.cta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white24,
                        child: const Icon(Icons.image_not_supported, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoItem {
  final String title;
  final String subtitle;
  final String cta;
  final String imageUrl;

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.imageUrl,
  });
}
