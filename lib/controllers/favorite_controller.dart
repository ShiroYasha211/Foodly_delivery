import 'package:food_delivery/models/food_item.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteController extends GetxController {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final RxList<int> _favoriteIds = <int>[].obs;

  List<int> get favoriteIds => _favoriteIds;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        final response = await _supabaseClient
            .from('favorites')
            .select('food_id')
            .eq('user_id', user.id);

        _favoriteIds.value = (response as List)
            .map<int>((item) => item['food_id'] as int)
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favoriteIds.value = [];
    }
  }

  bool isFoodFavorite(int foodId) {
    return _favoriteIds.contains(foodId);
  }

  Future<void> addToFavorites(FoodItem foodItem) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      await _supabaseClient.from('favorites').insert({
        'user_id': user.id,
        'food_id': foodItem.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      _favoriteIds.add(foodItem.id);
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(FoodItem foodItem) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      await _supabaseClient
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('food_id', foodItem.id);
      _favoriteIds.remove(foodItem.id);
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  Future<void> toggleFavorite(FoodItem foodItem) async {
    if (isFoodFavorite(foodItem.id)) {
      await removeFromFavorites(foodItem);
    } else {
      await addToFavorites(foodItem);
    }
  }
}
