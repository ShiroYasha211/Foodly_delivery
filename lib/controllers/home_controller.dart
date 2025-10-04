import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery/models/categories_model.dart';

import '../models/food_item.dart';

class HomeController extends GetxController {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  final RxList<FoodItem> allFoods = <FoodItem>[].obs;
  final RxList<FoodItem> filteredFoods = <FoodItem>[].obs;
  final RxList<CategoriesModel> categories = <CategoriesModel>[].obs;
  final RxString selectedCategory = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      // جلب التصنيفات
      final categoriesResponse = await _supabaseClient
          .from('categories')
          .select('*')
          .order('title');

      categories.value = (categoriesResponse as List)
          .map((json) => CategoriesModel.fromJson(json))
          .toList();

      // جلب جميع الأطعمة المتاحة
      final foodsResponse = await _supabaseClient
          .from('foods')
          .select('*')
          .eq('is_available', true)
          .order('name');

      allFoods.value = (foodsResponse as List)
          .map((json) => FoodItem.fromJson(json))
          .toList();

      filteredFoods.value = allFoods;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل البيانات: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterFoods() {
    List<FoodItem> result = allFoods;

    // التصفية حسب التصنيف
    if (selectedCategory.value != 'all') {
      final categoryId = int.tryParse(selectedCategory.value);
      if (categoryId != null) {
        result = result.where((food) => food.categoryId == categoryId).toList();
      }
    }

    // التصفية حسب البحث
    if (searchQuery.value.isNotEmpty) {
      result = result
          .where(
            (food) =>
                food.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                food.description.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
          )
          .toList();
    }

    filteredFoods.value = result;
  }

  void setCategory(String categoryId) {
    selectedCategory.value = categoryId;
    filterFoods();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    filterFoods();
  }

  void clearFilters() {
    selectedCategory.value = 'all';
    searchQuery.value = '';
    filteredFoods.value = allFoods;
  }

  // الحصول على الأطعمة الشعبية
  List<FoodItem> get popularFoods {
    return allFoods.where((food) => food.isPopular).toList();
  }
}
