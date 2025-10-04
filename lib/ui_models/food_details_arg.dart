import '../models/food_item.dart';

class FoodDetailsArg {
  final FoodItem? food; // التغيير هنا
  final int? foodIndex; // للحفاظ على التوافقية
  final int? foodId; // للعمل مع Supabase

  FoodDetailsArg({this.food, this.foodIndex, this.foodId})
    : assert(
        food != null || foodIndex != null || foodId != null,
        'يجب توفير food أو foodIndex أو foodId',
      );
}
