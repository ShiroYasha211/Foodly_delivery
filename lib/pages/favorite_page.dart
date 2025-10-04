import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/pages/food_details_page.dart';
import 'package:food_delivery/ui_models/food_details_arg.dart';
import 'package:food_delivery/utils/app_assets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../controllers/supabase_controller.dart';
import '../models/food_item.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  //final SupabaseController _supabaseController = Get.find();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  List<FoodItem> favoriteFood = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // جلب المفضلة من Supabase
  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'المستخدم غير مسجل الدخول';
          _isLoading = false;
        });
        return;
      }

      // جلب الأطعمة المفضلة من Supabase
      final response = await _supabaseClient
          .from('favorites')
          .select('''
            food_id,
            foods:foods(*)
              ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final List<FoodItem> loadedFavorites = [];
        for (var favorite in response) {
          final foodData = favorite['foods'];
          if (foodData != null) {
            loadedFavorites.add(
              FoodItem(
                id: foodData['id'],
                categoryId: foodData['category_id'],
                name: foodData['name'] ?? '',
                description: foodData['description'] ?? '',
                price: (foodData['price'] as num).toDouble(),
                imageUrl: foodData['img_url'] ?? '',
                preparationTime: foodData['preparation_time'] ?? 15,
                ingredients: List<String>.from(foodData['ingredients'] ?? []),
                rating: (foodData['rating'] as num).toDouble(),
                isPopular: foodData['is_popular'] ?? false,
                isAvailable: foodData['is_available'] ?? true,
              ),
            );
          }
        }
        setState(() {
          favoriteFood = loadedFavorites;
          _isLoading = false;
        });
      } else {
        setState(() {
          favoriteFood = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل المفضلة: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("المفضلة"), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "المفضلة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (favoriteFood.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showClearAllFavoritesDialog();
              },
              tooltip: "حذف الكل",
            ),
        ],
      ),
      body: favoriteFood.isNotEmpty
          ? _buildFavoritesList(favoriteFood, size, theme)
          : _buildEmptyState(size, theme, isLandscape),
    );
  }

  // بناء قائمة المفضلة
  Widget _buildFavoritesList(
    List<FoodItem> favoriteFood,
    Size size,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // عدد العناصر في المفضلة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: theme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "عدد العناصر: ${favoriteFood.length}",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // قائمة العناصر
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.separated(
                itemCount: favoriteFood.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildFavoriteItem(favoriteFood[index], size, theme);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // عنصر المفضلة
  Widget _buildFavoriteItem(FoodItem foodItem, Size size, ThemeData theme) {
    return Dismissible(
      key: Key('favorite_${foodItem.id}_${foodItem.name}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(foodItem.name);
      },
      onDismissed: (direction) {
        _removeFromFavorites(foodItem);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            _navigateToFoodDetails(foodItem);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // صورة الطعام
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: foodItem.imageUrl,
                    placeholder: (context, url) => Container(
                      width: size.width * 0.2,
                      height: size.width * 0.2,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: size.width * 0.2,
                      height: size.width * 0.2,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    ),
                    width: size.width * 0.2,
                    height: size.width * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(width: 16),

                // معلومات الطعام
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodItem.name,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // التقييم إذا كان متوفرًا
                      if (foodItem.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              foodItem.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      Text(
                        "${foodItem.price.toStringAsFixed(2)} \$",
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // زر إزالة من المفضلة
                IconButton(
                  onPressed: () {
                    _removeFromFavorites(foodItem);
                  },
                  icon: Icon(
                    Icons.favorite,
                    color: theme.primaryColor,
                    size: 28,
                  ),
                  tooltip: "إزالة من المفضلة",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // واجهة فارغة
  Widget _buildEmptyState(Size size, ThemeData theme, bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.emptyState,
              fit: BoxFit.contain,
              height: isLandscape ? size.height * 0.5 : size.height * 0.3,
              width: size.width * 0.7,
            ),

            const SizedBox(height: 24),

            Text(
              "لا توجد عناصر في المفضلة",
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "يمكنك إضافة وجباتك المفضلة بالنقر على أيقونة القلب في صفحة التفاصيل",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // التنقل إلى صفحة التفاصيل
  void _navigateToFoodDetails(FoodItem foodItem) {
    Get.to(
      const FoodDetailsPage(),
      arguments: FoodDetailsArg(
        foodId: foodItem.id,
      ), // استخدام foodId بدلاً من index
    )!.then((_) {
      // إعادة تحميل البيانات بعد العودة
      _loadFavorites();
    });
  }

  // إزالة من المفضلة في Supabase
  Future<void> _removeFromFavorites(FoodItem foodItem) async {
    try {
      final user = _supabaseClient.auth.currentUser;

      if (user == null) {
        Get.snackbar(
          "خطأ",
          "المستخدم غير مسجل الدخول",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // تحديث الحالة في Supabase
      await _supabaseClient
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('food_id', foodItem.id);

      // إعادة تحميل البيانات
      await _loadFavorites();

      // إشعار بالإزالة
      Get.snackbar(
        "تم الإزالة",
        "تمت إزالة ${foodItem.name} من المفضلة",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.favorite_border, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في إزالة العنصر من المفضلة: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  // تأكيد الحذف
  Future<bool> _showDeleteConfirmation(String foodName) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إزالة من المفضلة"),
        content: Text("هل تريد إزالة $foodName من المفضلة؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("إزالة", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // حذف كل المفضلة
  void _showClearAllFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف الكل"),
        content: const Text(
          "هل أنت متأكد من أنك تريد حذف جميع العناصر من المفضلة؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllFavorites();
            },
            child: const Text("حذف الكل", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // مسح كل المفضلة في Supabase
  Future<void> _clearAllFavorites() async {
    try {
      final user = _supabaseClient.auth.currentUser;

      if (user == null) {
        Get.snackbar(
          "خطأ",
          "المستخدم غير مسجل الدخول",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }
      // تحديث جميع العناصر في Supabase
      await _supabaseClient.from('favorites').delete().eq('user_id', user.id);

      // إعادة تحميل البيانات
      await _loadFavorites();

      // إشعار بالمسح
      Get.snackbar(
        "تم المسح",
        "تمت إزالة جميع العناصر من المفضلة",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.delete_sweep, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في حذف جميع العناصر",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }
}
