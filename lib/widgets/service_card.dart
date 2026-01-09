import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lorensbeauty/provider/services_provider.dart';
class ServiceCard extends ConsumerWidget {
  final Map<String, dynamic> service;
  final int index;
  final VoidCallback onTap;
  const ServiceCard({
    
    Key? key,
    required this.service,
    required this.index,
    required this.onTap,
  }): super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedServiceIndexProvider);
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12.0),
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            width: isSelected ? 3 : 1,
            color: isSelected ? const Color(0xff721c80) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
              child: (service['img'] != null)
                  ? CachedNetworkImage(
                      imageUrl: service['img'],
                      height: 65,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(height: 65, color: Colors.grey[200]),
                      errorWidget: (c, _, __) => Container(
                        height: 65,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      height: 65,
                      color: Colors.grey[300],
                      child: const Icon(Icons.spa, color: Color(0xff721c80), size: 30),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Center(
                  child: Text(
                    service['name'] ?? 'Sin nombre',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff721c80),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
