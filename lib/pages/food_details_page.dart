import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery/models/food_item.dart';
import 'package:food_delivery/ui_models/food_details_arg.dart';
import 'package:food_delivery/widgets/food_details/custom_counter.dart';
import 'package:food_delivery/widgets/food_details/property_item.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorite_controller.dart';
import '../models/cart_item_model.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/favorite_button.dart';

class FoodDetailsPage extends StatefulWidget {
  const FoodDetailsPage({super.key});
  static const routeName = '/Food-Details-Page';

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final CartController _cartController = Get.find<CartController>();
  final FavoriteController _favoriteController = Get.find<FavoriteController>();

  int quantity = 1;
  FoodItem? foodItem;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _specialInstructions;

  @override
  @override
  void initState() {
    super.initState();
    _processArguments();
  }

  Future<void> _processArguments() async {
    try {
      final args = Get.arguments;

      if (args is FoodItem) {
        setState(() {
          foodItem = args;
          _isLoading = false;
        });
      } else if (args is FoodDetailsArg) {
        // إذا أرسلت FoodDetailsArg
        if (args.food != null) {
          setState(() {
            foodItem = args.food;
            _isLoading = false;
          });
        } else if (args.foodId != null) {
          // جلب البيانات من السيرفر باستخدام foodId
          await _loadFoodFromServer(args.foodId!);
        }
      } else {
        setState(() {
          _errorMessage = 'بيانات غير صحيحة';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFoodFromServer(int foodId) async {
    try {
      final response = await _supabaseClient
          .from('foods')
          .select('*')
          .eq('id', foodId)
          .single();

      setState(() {
        foodItem = FoodItem(
          id: response['id'],
          categoryId: response['category_id'],
          name: response['name'] ?? '',
          description: response['description'] ?? '',
          price: (response['price'] as num).toDouble(),
          imageUrl: response['img_url'] ?? '',
          preparationTime: response['preparation_time'] ?? 15,
          ingredients: List<String>.from(response['ingredients'] ?? []),
          rating: (response['rating'] as num).toDouble(),
          isPopular: response['is_popular'] ?? false,
          isAvailable: response['is_available'] ?? true,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل بيانات الطعام';
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // الحصول على البيانات من الـ arguments
    final args = Get.arguments;
    if (args is FoodItem && foodItem == null) {
      setState(() {
        foodItem = args;
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (foodItem == null) return;

    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'يجب تسجيل الدخول',
          'يجب تسجيل الدخول لإضافة عناصر إلى السلة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (!foodItem!.isAvailable) {
        Get.snackbar(
          'غير متاح',
          'هذا المنتج غير متاح حالياً',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      _cartController.addItem(
        CartItem(
          foodId: foodItem!.id,
          foodName: foodItem!.name,
          price: foodItem!.price,
          quantity: quantity,
          imageUrl: foodItem!.imageUrl,
          specialInstructions: _specialInstructions,
        ),
      );

      Get.snackbar(
        'تم الإضافة ✅',
        'تمت إضافة ${foodItem!.name} إلى السلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة العنصر إلى السلة: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showSpecialInstructionsDialog() {
    final TextEditingController instructionsController = TextEditingController(
      text: _specialInstructions,
    );

    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملاحظات خاصة',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أدخل أي ملاحظات أو تعليمات خاصة...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _specialInstructions = instructionsController.text
                              .trim();
                        });
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              const SizedBox(height: 16),
              const Text('جاري تحميل بيانات الطعام...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || foodItem == null) {
      return Scaffold(
        appBar: AppBar(leading: const CustomBackButton(height: 10, width: 10)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'الطعام غير موجود',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    final currentFoodItem = foodItem!;
    double total = quantity * currentFoodItem.price;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // AppBar مع الصورة
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: size.height * 0.4,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          // صورة الطعام
                          Align(
                            alignment: Alignment.center,
                            child: CachedNetworkImage(
                              imageUrl: currentFoodItem.imageUrl,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              //height: size.height * 0.2,
                            ),
                          ),

                          // تدرج لوني
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CustomBackButton(height: 10, width: 10),
                    ),
                    actions: [
                      Obx(() {
                        _favoriteController.isFoodFavorite(currentFoodItem.id);
                        return FavoriteButton(
                          height: 40,
                          width: 40,
                          foodItem: currentFoodItem,
                          onFavoriteChanged: (isFav) {
                            setState(() {
                              _favoriteController.toggleFavorite(
                                currentFoodItem,
                              );
                            });
                          },
                        );
                        // return IconButton(
                        //   onPressed: () async {
                        //     if (isFavorite) {
                        //       await _favoriteController.removeFromFavorites(
                        //         currentFoodItem,
                        //       );
                        //     } else {
                        //       await _favoriteController.addToFavorites(
                        //         currentFoodItem,
                        //       );
                        //   }
                        // },

                        // icon: isFavorite
                        //     ? const Icon(Icons.favorite)
                        //     : const Icon(Icons.favorite_border),
                        // color: isFavorite ? Colors.red : Colors.black54,
                        // iconSize: 28,
                      }),
                      if (currentFoodItem.isPopular)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'شعبي',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // محتوى التفاصيل
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان والسعر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentFoodItem.name,
                                        style: theme.textTheme.headlineSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${currentFoodItem.price.toStringAsFixed(2)} \$',
                                        style: theme.textTheme.headlineSmall!
                                            .copyWith(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                CustomCounter(
                                  initialValue: quantity,
                                  onChanged: (value) {
                                    setState(() {
                                      quantity = value;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // خصائص الطعام
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  PropertyItem(
                                    icon: Icons.access_time,
                                    propertyValue:
                                        '${currentFoodItem.preparationTime} دقيقة',
                                    propertyName: 'وقت التحضير',
                                  ),
                                  PropertyItem(
                                    icon: Icons.star,
                                    propertyValue: currentFoodItem.rating
                                        .toString(),
                                    propertyName: 'التقييم',
                                  ),
                                  PropertyItem(
                                    icon: Icons.local_fire_department,
                                    propertyValue:
                                        '${currentFoodItem.preparationTime * 20} سعرة',
                                    propertyName: 'السعرات',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // وصف الطعام
                            Text(
                              'الوصف',
                              style: theme.textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentFoodItem.description,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // المكونات
                            if (currentFoodItem.ingredients.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'المكونات',
                                    style: theme.textTheme.titleLarge!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: currentFoodItem.ingredients
                                        .map(
                                          (ingredient) => Chip(
                                            label: Text(ingredient),
                                            backgroundColor: theme.primaryColor
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 24),

                            // ملاحظات خاصة
                            GestureDetector(
                              onTap: _showSpecialInstructionsDialog,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.note_add,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _specialInstructions ??
                                            'إضافة ملاحظات خاصة (اختياري)',
                                        style: TextStyle(
                                          color: _specialInstructions != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // قسم الشراء
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // السعر الإجمالي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المجموع',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} \$',
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // زر الإضافة إلى السلة
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentFoodItem.isAvailable
                              ? theme.primaryColor
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.shopping_cart,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          currentFoodItem.isAvailable
                              ? 'أضف إلى السلة'
                              : 'غير متاح',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
