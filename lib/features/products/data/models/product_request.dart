class ProductRequest {
  final String title;
  final double price;
  final String description;
  final int categoryId;
  final List<String> images;

  ProductRequest({
    required this.title,
    required this.price,
    required this.description,
    required this.categoryId,
    required this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'categoryId': categoryId,
      'images': images,
    };
  }

  /// For partial update (PUT)
  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};
    if (title.isNotEmpty) data['title'] = title;
    if (price > 0) data['price'] = price;
    if (description.isNotEmpty) data['description'] = description;
    if (categoryId > 0) data['categoryId'] = categoryId;
    if (images.isNotEmpty) data['images'] = images;
    return data;
  }
}
