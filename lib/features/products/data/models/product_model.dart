import 'category_model.dart';

class ProductModel {
  final int id;
  final String title;
  final String slug;
  final double price;
  final String description;
  final CategoryModel? category;
  final List<String> images;
  final DateTime? creationAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.description,
    this.category,
    required this.images,
    this.creationAt,
    this.updatedAt,
  });

  /// Helper to clean malformed image URLs often returned by public test APIs
  static String cleanImageUrl(String raw) {
    var url = raw.trim();
    if (url.startsWith('["') || url.startsWith("['") || url.startsWith('[') || url.startsWith('"')) {
      url = url
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('\\', '');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://placehold.co/600x400?text=Product';
    }
    return url;
  }

  /// Gets the primary display image
  String get displayImage {
    for (final img in images) {
      final cleaned = cleanImageUrl(img);
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        return cleaned;
      }
    }
    return 'https://placehold.co/600x400?text=Product';
  }

  /// Gets all sanitized image URLs
  List<String> get sanitizedImages {
    final list = images
        .map((img) => cleanImageUrl(img))
        .where((img) => img.startsWith('http://') || img.startsWith('https://'))
        .toList();
    if (list.isEmpty) {
      return ['https://placehold.co/600x400?text=Product'];
    }
    return list;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse price safely as double
    double parsedPrice = 0.0;
    if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    } else if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // Parse category
    CategoryModel? parsedCategory;
    if (json['category'] is Map<String, dynamic>) {
      parsedCategory = CategoryModel.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['category'] is Map) {
      parsedCategory = CategoryModel.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      );
    }

    // Parse images list
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String? ?? 'Untitled Product',
      slug: json['slug'] as String? ?? '',
      price: parsedPrice,
      description: json['description'] as String? ?? '',
      category: parsedCategory,
      images: parsedImages,
      creationAt: json['creationAt'] != null
          ? DateTime.tryParse(json['creationAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'price': price,
      'description': description,
      if (category != null) 'category': category!.toJson(),
      'images': images,
    };
  }

  ProductModel copyWith({
    int? id,
    String? title,
    String? slug,
    double? price,
    String? description,
    CategoryModel? category,
    List<String>? images,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      creationAt: creationAt,
      updatedAt: updatedAt,
    );
  }
}
