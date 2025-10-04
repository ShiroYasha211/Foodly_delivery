class FoodItem {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int preparationTime;
  final List<String> ingredients;
  final double rating;
  final bool isPopular;
  final bool isAvailable;

  FoodItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.preparationTime,
    required this.ingredients,
    required this.rating,
    required this.isPopular,
    required this.isAvailable,
  });
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] ?? '',
      preparationTime: json['preparation_time'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      rating: (json['rating'] as num).toDouble(),
      isPopular: json['is_popular'] ?? false,
      isAvailable: json['is_available'] ?? true,
    );
  }
}
