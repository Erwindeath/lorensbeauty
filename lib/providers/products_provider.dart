import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// MODELOS
// ============================================

class ProductPhoto {
  final int id;
  final int productId;
  final String photoUrl;
  final String? caption;
  final DateTime uploadedAt;

  ProductPhoto({
    required this.id,
    required this.productId,
    required this.photoUrl,
    this.caption,
    required this.uploadedAt,
  });

  factory ProductPhoto.fromJson(Map<String, dynamic> json) {
    return ProductPhoto(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      photoUrl: json['photo_url'] as String,
      caption: json['caption'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'photo_url': photoUrl,
      'caption': caption,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class Product {
  final int id;
  final String name;
  final String? description;
  final String? treatmentExplanation;
  final double price;
  final String? brand;
  final List<String> benefits;
  final String? ingredients;
  final String? howToUse;
  final bool isFeatured;
  final int displayOrder;
  final bool active;
  final int? categoryId;
  final String? categoryName;
  final List<ProductPhoto> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.treatmentExplanation,
    required this.price,
    this.brand,
    this.benefits = const [],
    this.ingredients,
    this.howToUse,
    required this.isFeatured,
    required this.displayOrder,
    required this.active,
    this.categoryId,
    this.categoryName,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parsear fotos
    List<ProductPhoto> photosList = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photosList = (json['photos'] as List)
            .map((photo) => ProductPhoto.fromJson(photo as Map<String, dynamic>))
            .toList();
      }
    }

    // Parsear beneficios
    List<String> benefitsList = [];
    if (json['benefits'] != null) {
      if (json['benefits'] is List) {
        benefitsList = (json['benefits'] as List)
            .map((b) => b.toString())
            .toList();
      }
    }

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      treatmentExplanation: json['treatment_explanation'] as String?,
      price: (json['price'] ?? 0).toDouble(),
      brand: json['brand'] as String?,
      benefits: benefitsList,
      ingredients: json['ingredients'] as String?,
      howToUse: json['how_to_use'] as String?,
      isFeatured: json['is_featured'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      active: json['active'] ?? true,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      photos: photosList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get firstPhotoUrl {
    if (photos.isEmpty) return '';
    return photos.first.photoUrl;
  }

  bool get hasPhotos => photos.isNotEmpty;
}

class ProductCategory {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final String? iconName;
  final String? colorHex;
  final int displayOrder;
  final bool isActive;
  final String categoryType; // 'product' o 'service'
  final int productCount; // Cantidad de productos en esta categoría

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.iconName,
    this.colorHex,
    required this.displayOrder,
    required this.isActive,
    this.categoryType = 'product',
    this.productCount = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as int?,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      productCount: json['product_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'icon_name': iconName,
      'color_hex': colorHex,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Provider para obtener todas las categorías activas de PRODUCTOS
final categoriesProvider = StreamProvider<List<ProductCategory>>((ref) {
  return Supabase.instance.client
      .from('categories')
      .stream(primaryKey: ['id'])
      .eq('is_active', true)
      .order('display_order')
      .map((data) => data
          .where((json) => (json['category_id'] as String? ?? 'product') == 'product')
          .map((json) => ProductCategory.fromJson(json))
          .toList());
});

/// Provider para obtener categorías con contador de productos
final categoriesWithCountProvider = FutureProvider<List<ProductCategory>>((ref) async {
  try {
    // Obtener todas las categorías de productos
    final categories = await Supabase.instance.client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('display_order');

    // Para cada categoría, contar sus productos activos
    List<ProductCategory> categoriesWithCount = [];
    for (var categoryJson in categories) {
      final productsResponse = await Supabase.instance.client
          .from('products')
          .select()
          .eq('category_id', categoryJson['id'])
          .eq('active', true);

      categoryJson['product_count'] = productsResponse.length;
      categoriesWithCount.add(ProductCategory.fromJson(categoryJson));
    }

    return categoriesWithCount;
  } catch (e) {
    print('Error fetching categories with count: $e');
    return [];
  }
});

/// Provider para obtener productos por categoría
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, int>((ref, categoryId) async {
  try {
    final response = await Supabase.instance.client
        .from('products')
        .select('''
          *,
          categories!inner(name)
        ''')
        .eq('active', true)
        .eq('category_id', categoryId)
        .order('display_order')
        .order('created_at', ascending: false);

    List<Product> products = [];
    for (var productJson in response) {
      // Obtener fotos del producto
      final photos = await Supabase.instance.client
          .from('product_photos')
          .select()
          .eq('product_id', productJson['id'])
          .order('uploaded_at');

      // Agregar nombre de categoría
      productJson['category_name'] = productJson['categories']['name'];
      productJson['photos'] = photos;

      products.add(Product.fromJson(productJson));
    }

    return products;
  } catch (e) {
    print('Error fetching products by category: $e');
    return [];
  }
});

/// Provider para obtener TODOS los productos activos (para admin)
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('products')
        .select('''
          *,
          categories(name)
        ''')
        .eq('active', true)
        .order('created_at', ascending: false);

    List<Product> products = [];
    for (var productJson in response) {
      // Obtener fotos del producto
      final photos = await Supabase.instance.client
          .from('product_photos')
          .select()
          .eq('product_id', productJson['id'])
          .order('uploaded_at');

      // Agregar nombre de categoría si existe
      if (productJson['categories'] != null) {
        productJson['category_name'] = productJson['categories']['name'];
      }
      productJson['photos'] = photos;

      products.add(Product.fromJson(productJson));
    }

    return products;
  } catch (e) {
    print('Error fetching all products: $e');
    return [];
  }
});

/// Provider para obtener productos destacados
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('products')
        .select('''
          *,
          categories(name)
        ''')
        .eq('active', true)
        .eq('is_featured', true)
        .order('display_order')
        .limit(10);

    List<Product> products = [];
    for (var productJson in response) {
      // Obtener fotos del producto
      final photos = await Supabase.instance.client
          .from('product_photos')
          .select()
          .eq('product_id', productJson['id'])
          .order('uploaded_at');

      // Agregar nombre de categoría si existe
      if (productJson['categories'] != null) {
        productJson['category_name'] = productJson['categories']['name'];
      }
      productJson['photos'] = photos;

      products.add(Product.fromJson(productJson));
    }

    return products;
  } catch (e) {
    print('Error fetching featured products: $e');
    return [];
  }
});

/// Provider para obtener un producto específico por ID
final productByIdProvider =
    FutureProvider.family<Product?, int>((ref, productId) async {
  try {
    final response = await Supabase.instance.client
        .from('products')
        .select('''
          *,
          categories(name)
        ''')
        .eq('id', productId)
        .single();

    // Obtener fotos del producto
    final photos = await Supabase.instance.client
        .from('product_photos')
        .select()
        .eq('product_id', productId)
        .order('uploaded_at');

    // Agregar datos adicionales
    if (response['categories'] != null) {
      response['category_name'] = response['categories']['name'];
    }
    response['photos'] = photos;

    return Product.fromJson(response);
  } catch (e) {
    print('Error fetching product by id: $e');
    return null;
  }
});

/// Provider para buscar productos
final searchProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];

  try {
    final response = await Supabase.instance.client
        .from('products')
        .select('''
          *,
          categories(name)
        ''')
        .eq('active', true)
        .or('name.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%')
        .order('is_featured', ascending: false)
        .order('name')
        .limit(20);

    List<Product> products = [];
    for (var productJson in response) {
      // Obtener fotos del producto
      final photos = await Supabase.instance.client
          .from('product_photos')
          .select()
          .eq('product_id', productJson['id'])
          .order('uploaded_at');

      if (productJson['categories'] != null) {
        productJson['category_name'] = productJson['categories']['name'];
      }
      productJson['photos'] = photos;

      products.add(Product.fromJson(productJson));
    }

    return products;
  } catch (e) {
    print('Error searching products: $e');
    return [];
  }
});

// ============================================
// FUNCIONES CRUD (Para Admin)
// ============================================

/// Crear un nuevo producto
Future<Product?> createProduct({
  required String name,
  required double price,
  required int categoryId,
  String? description,
  String? treatmentExplanation,
  String? brand,
  List<String>? benefits,
  String? ingredients,
  String? howToUse,
  bool isFeatured = false,
  int displayOrder = 0,
}) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final response = await Supabase.instance.client
        .from('products')
        .insert({
          'name': name,
          'price': price,
          'category_id': categoryId,
          'description': description,
          'treatment_explanation': treatmentExplanation,
          'brand': brand,
          'benefits': benefits,
          'ingredients': ingredients,
          'how_to_use': howToUse,
          'is_featured': isFeatured,
          'display_order': displayOrder,
          'active': true,
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    response['photos'] = [];
    return Product.fromJson(response);
  } catch (e) {
    print('Error creating product: $e');
    return null;
  }
}

/// Actualizar un producto existente
Future<bool> updateProduct({
  required int productId,
  String? name,
  double? price,
  int? categoryId,
  String? description,
  String? treatmentExplanation,
  String? brand,
  List<String>? benefits,
  String? ingredients,
  String? howToUse,
  bool? isFeatured,
  bool? active,
  int? displayOrder,
}) async {
  try {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updateData['name'] = name;
    if (price != null) updateData['price'] = price;
    if (categoryId != null) updateData['category_id'] = categoryId;
    if (description != null) updateData['description'] = description;
    if (treatmentExplanation != null) updateData['treatment_explanation'] = treatmentExplanation;
    if (brand != null) updateData['brand'] = brand;
    if (benefits != null) updateData['benefits'] = benefits;
    if (ingredients != null) updateData['ingredients'] = ingredients;
    if (howToUse != null) updateData['how_to_use'] = howToUse;
    if (isFeatured != null) updateData['is_featured'] = isFeatured;
    if (active != null) updateData['active'] = active;
    if (displayOrder != null) updateData['display_order'] = displayOrder;

    await Supabase.instance.client
        .from('products')
        .update(updateData)
        .eq('id', productId);

    return true;
  } catch (e) {
    print('Error updating product: $e');
    return false;
  }
}

/// Eliminar un producto
Future<bool> deleteProduct(int productId) async {
  try {
    await Supabase.instance.client
        .from('products')
        .delete()
        .eq('id', productId);

    return true;
  } catch (e) {
    print('Error deleting product: $e');
    return false;
  }
}

/// Subir foto de producto
Future<ProductPhoto?> uploadProductPhoto({
  required int productId,
  required String photoUrl,
  String? caption,
}) async {
  try {
    final response = await Supabase.instance.client
        .from('product_photos')
        .insert({
          'product_id': productId,
          'photo_url': photoUrl,
          'caption': caption,
          'uploaded_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return ProductPhoto.fromJson(response);
  } catch (e) {
    print('Error uploading product photo: $e');
    return null;
  }
}

/// Eliminar foto de producto
Future<bool> deleteProductPhoto(int photoId) async {
  try {
    await Supabase.instance.client
        .from('product_photos')
        .delete()
        .eq('id', photoId);

    return true;
  } catch (e) {
    print('Error deleting product photo: $e');
    return false;
  }
}
