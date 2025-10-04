import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_delivery/models/cart_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // إضافة عنصر للسلة
  void addItem(CartItem item) {
    final existingItemIndex = cartItems.indexWhere(
      (cartItem) =>
          cartItem.foodId == item.foodId &&
          cartItem.specialInstructions == item.specialInstructions,
    );

    if (existingItemIndex != -1) {
      // زيادة الكمية إذا العنصر موجود
      cartItems[existingItemIndex] = cartItems[existingItemIndex].copyWith(
        quantity: cartItems[existingItemIndex].quantity + item.quantity,
      );
    } else {
      // إضافة عنصر جديد
      cartItems.add(item);
    }
  }

  // زيادة كمية عنصر
  void increaseQuantity(int index) {
    cartItems[index] = cartItems[index].copyWith(
      quantity: cartItems[index].quantity + 1,
    );
  }

  // تقليل كمية عنصر
  void decreaseQuantity(int index) {
    if (cartItems[index].quantity > 1) {
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity - 1,
      );
    } else {
      removeItem(index);
    }
  }

  // حذف عنصر
  void removeItem(int index) {
    cartItems.removeAt(index);
  }

  // تحديث ملاحظات خاصة
  void updateSpecialInstructions(int index, String instructions) {
    cartItems[index] = cartItems[index].copyWith(
      specialInstructions: instructions,
    );
  }

  // الحصول على المجموع الكلي
  double get totalAmount {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // الحصول على عدد العناصر
  int get itemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // تفريغ السلة
  void clearCart() {
    cartItems.clear();
  }

  // التحقق إذا السلة فارغة
  bool get isEmpty => cartItems.isEmpty;

  // إنشاء طلب جديد
  Future<void> createOrder({
    String deliveryAddress = 'لم يتم تحديد العنوان',
    String paymentMethod = 'نقدي عند الاستلام',
  }) async {
    try {
      isLoading.value = true;

      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول لإنشاء طلب');
      }

      if (cartItems.isEmpty) {
        throw Exception('السلة فارغة');
      }

      // 1. حساب المجموع الكلي من عناصر السلة
      final double totalAmount = cartItems.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // 2. إنشاء الطلب في جدول orders
      final orderResponse = await _supabaseClient
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': totalAmount,
            'status': 'pending',
            'delivery_address': deliveryAddress,
            'payment_method': paymentMethod,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id, order_number')
          .single();

      final int orderId = orderResponse['id'];
      final String orderNumber = orderResponse['order_number'];

      // 3. إضافة عناصر الطلب في جدول order_items
      for (final cartItem in cartItems) {
        // التأكد من أن الطعام لا يزال موجوداً في قاعدة البيانات
        final foodResponse = await _supabaseClient
            .from('foods')
            .select('name, price, is_available')
            .eq('id', cartItem.foodId)
            .maybeSingle();

        if (foodResponse == null) {
          throw Exception('الطعام غير موجود في القائمة: ${cartItem.foodId}');
        }

        if (!foodResponse['is_available']) {
          throw Exception('الطعام غير متاح حالياً: ${foodResponse['name']}');
        }

        //final String foodName = foodResponse['name'] as String;
        final double currentPrice = (foodResponse['price'] as num).toDouble();

        await _supabaseClient.from('order_items').insert({
          'order_id': orderId,
          'food_id': cartItem.foodId,
          // 'food_name': foodName,
          'quantity': cartItem.quantity,
          'unit_price': currentPrice,
          'special_instructions': cartItem.specialInstructions,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. تفريغ السلة بعد النجاح
      clearCart();

      // 5. إرسال إشعار النجاح
      Get.snackbar(
        'تم إنشاء الطلب بنجاح 🎉',
        'رقم طلبك: $orderNumber\nسيتم التوصيل خلال 30-45 دقيقة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // 6. تسجيل الحدث في console لل debugging
      print('تم إنشاء الطلب بنجاح: #$orderNumber - المبلغ: $totalAmount \$');
    } catch (e) {
      // معالجة الأخطاء بشكل أكثر تفصيلاً
      String errorMessage = 'فشل في إنشاء الطلب';

      if (e.toString().contains('يجب تسجيل الدخول')) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.toString().contains('السلة فارغة')) {
        errorMessage = 'السلة فارغة، أضف عناصر أولاً';
      } else if (e.toString().contains('غير متاح')) {
        errorMessage = 'أحد المنتجات غير متاح حالياً';
      } else if (e.toString().contains('غير موجود')) {
        errorMessage = 'أحد المنتجات لم يعد موجوداً في القائمة';
      }

      Get.snackbar(
        'خطأ في الطلب ❌',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
