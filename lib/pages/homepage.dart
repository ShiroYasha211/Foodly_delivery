import 'package:flutter/material.dart';
import 'package:food_delivery/controllers/favorite_controller.dart';
import 'package:food_delivery/models/categories_model.dart';
import 'package:food_delivery/pages/food_details_page.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';
import '../widgets/food_grid_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? categoryChosenId;
  List<FoodItem> filteredFood = [];
  List<FoodItem> allFood = [];
  List<CategoriesModel> categories = [];
  bool enableFilter = false;
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final FavoriteController _favoriteController = Get.find();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      await Future.wait([_loadCategories(), _loadFoodItems()]);
      setState(() {
        filteredFood = allFood;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "فشل فى تحميل البيانات";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _supabaseClient
          .from('categories')
          .select('*')
          .order('title');
      setState(() {
        categories = (response as List<dynamic>).map((categoryData) {
          return CategoriesModel(
            id: categoryData['id'],
            title: categoryData['title'] ?? '',
            imgPath: categoryData['img_path'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadFoodItems() async {
    try {
      final response = await _supabaseClient
          .from('foods')
          .select('*')
          .eq('is_available', true)
          .order('name');

      setState(() {
        allFood = (response as List<dynamic>).map((foodData) {
          return FoodItem(
            id: foodData['id'],
            name: foodData['name'] ?? '',
            imageUrl: foodData['img_url'] ?? '',
            price: (foodData['price'] as num?)?.toDouble() ?? 0.0,
            categoryId: foodData['category_id'],
            description: foodData['description'] ?? '',
            ingredients: foodData['ingredients'] != null
                ? List<String>.from(foodData['ingredients'])
                : [],
            isPopular: foodData['is_popular'] ?? false,
            rating: (foodData['rating'] as num?)?.toDouble() ?? 0.0,
            preparationTime: foodData['preparation_time'] ?? 15,
            isAvailable: foodData['is_available'] ?? true,
          );
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل قائمة الطعام';
      });
    }
  }

  void _filterFood(String query) {
    setState(() {
      if (query.isEmpty) {
        if (categoryChosenId != null) {
          filteredFood = allFood
              .where((item) => item.categoryId.toString() == categoryChosenId)
              .toList();
        } else {
          filteredFood = allFood;
        }
      } else {
        filteredFood = allFood
            .where(
              (item) =>
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        if (categoryChosenId != null) {
          filteredFood = filteredFood
              .where((item) => item.categoryId.toString() == categoryChosenId)
              .toList();
        }
      }
    });
  }

  void _clearFilters() {
    setState(() {
      categoryChosenId = null;
      _searchController.clear();
      filteredFood = allFood;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text('جاري تحميل البيانات...', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "إعادة المحاولة",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط البحث المدمج
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFood,
                decoration: InputDecoration(
                  hintText: 'ابحث عن طعامك المفضل...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            _filterFood('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // قسم التصنيفات
            Text(
              'التصنيفات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // زر "الكل"
                    final isSelected = categoryChosenId == null;
                    return _buildCategoryItem(
                      title: 'الكل',
                      icon: Icons.all_inclusive,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          categoryChosenId = null;
                          _filterFood(_searchController.text);
                        });
                      },
                    );
                  }

                  final category = categories[index - 1];
                  final isSelected = categoryChosenId == category.id.toString();
                  return _buildCategoryItem(
                    title: category.title,
                    imageUrl: category.imgPath,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        categoryChosenId = category.id.toString();
                        _filterFood(_searchController.text);
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // عنوان قسم الأطعمة مع عدد النتائج
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قائمة الطعام',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (categoryChosenId != null ||
                    _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'مسح الكل',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
              ],
            ),

            if (categoryChosenId != null || _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${filteredFood.length} نتيجة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // قائمة الطعام
            Expanded(
              child: filteredFood.isEmpty
                  ? SingleChildScrollView(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب البحث بكلمات أخرى أو تغيير التصنيف',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _clearFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                              ),
                              child: const Text(
                                'عرض الكل',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: filteredFood.length,
                      itemBuilder: (context, index) {
                        final food = filteredFood[index];
                        return FoodGridItem(
                          food: filteredFood[index],
                          onTap: () {
                            Get.to(
                              const FoodDetailsPage(),
                              arguments: filteredFood[index],
                            )?.then((value) {
                              if (value == true) {
                                _loadData(); // إعادة تحميل البيانات إذا كانت هناك تغييرات
                              }
                            });
                          },
                          onFavoriteToggle: (isFavorite) {
                            setState(() {
                              _favoriteController.toggleFavorite(food);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    String? imageUrl,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageUrl != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      imageUrl,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fastfood, size: 20),
                    ),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
