class CartItem {
  final int foodId;
  final String foodName;
  final double price;
  int quantity;
  final String? specialInstructions;
  final String imageUrl;

  CartItem({
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    required this.imageUrl,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({int? quantity, String? specialInstructions}) {
    return CartItem(
      foodId: foodId,
      foodName: foodName,
      price: price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      imageUrl: imageUrl,
    );
  }
}
