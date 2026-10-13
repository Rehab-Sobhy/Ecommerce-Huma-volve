import 'package:equatable/equatable.dart';
import 'category_entity.dart';

class ProductEntity extends Equatable {
  final int id;
  final String title;
  final String slug;
  final double price;
  final String description;
  final CategoryEntity? category;
  final List<String> images;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.description,
    this.category,
    required this.images,
  });

  /// Gets the primary display image, cleaning malformed URLs.
  String get displayImage {
    for (final img in images) {
      final cleaned = _cleanImageUrl(img);
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        return cleaned;
      }
    }
    return 'https://placehold.co/600x400?text=Product';
  }

  /// Gets all sanitized image URLs.
  List<String> get sanitizedImages {
    final list = images
        .map(_cleanImageUrl)
        .where((img) => img.startsWith('http://') || img.startsWith('https://'))
        .toList();
    return list.isEmpty
        ? ['https://placehold.co/600x400?text=Product']
        : list;
  }

  static String _cleanImageUrl(String raw) {
    var url = raw.trim();
    if (url.startsWith('[') || url.startsWith('"')) {
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

  @override
  List<Object?> get props => [id, title, slug, price, description, category, images];
}
