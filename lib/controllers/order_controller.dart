import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderController extends GetxController {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // عوامل التصفية
  final RxString _filterStatus = 'all'.obs;
  final RxString _sortBy = 'date_desc'.obs;
  final Rx<DateTime?> _startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> _endDate = Rx<DateTime?>(null);

  //البحث عن الطلبات
  final RxString _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;
  final RxList<String> recentSearches = <String>[].obs;

  String get filterStatus => _filterStatus.value;
  String get sortBy => _sortBy.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;

  List<Order> get filteredOrders {
    var filtered = orders.where((order) {
      if (_filterStatus.value != 'all' && order.status != _filterStatus.value) {
        return false;
      }
      if (_startDate.value != null &&
          order.orderDate.isBefore(_startDate.value!)) {
        return false;
      }
      if (_endDate.value != null && order.orderDate.isAfter(_endDate.value!)) {
        return false;
      }
      if (_searchQuery.value.isNotEmpty &&
          !order.orderNumber.toLowerCase().contains(
            _searchQuery.value.toLowerCase(),
          )) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortBy.value) {
      case 'date_asc':
        filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case 'price_asc':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
    }

    return filtered;
  }

  Future<Map<int, String>> _getFoodNames(List<Order> orders) async {
    try {
      // جمع جميع food_ids من جميع الطلبات
      final allFoodIds = <int>{};
      for (final order in orders) {
        for (final item in order.items) {
          allFoodIds.add(item.foodId);
        }
      }

      if (allFoodIds.isEmpty) return {};

      // جلب أسماء الأطعمة من قاعدة البيانات
      final response = await _supabaseClient
          .from('foods')
          .select('id, name')
          .inFilter('id', allFoodIds.toList());

      // تحويل النتيجة إلى Map
      final foodNames = <int, String>{};
      for (final food in response) {
        foodNames[food['id'] as int] = food['name'] as String;
      }

      return foodNames;
    } catch (e) {
      print('Error fetching food names: $e');
      return {};
    }
  }

  Future<void> loadUserOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _supabaseClient.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول');

      final response = await _supabaseClient
          .from('orders')
          .select('''
            *,
            order_items (*)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        orders.value = [];
        return;
      }

      final List<Order> loadedOrders = (response as List<dynamic>)
          .map((orderData) => Order.fromJson(orderData))
          .toList();

      // جلب أسماء الأطعمة
      final foodNames = await _getFoodNames(loadedOrders);

      // تحديث أسماء الأطعمة في عناصر الطلب
      for (final order in loadedOrders) {
        for (final item in order.items) {
          if (foodNames.containsKey(item.foodId)) {
            item.foodName = foodNames[item.foodId]!;
          }
        }
      }

      orders.value = loadedOrders;
    } catch (e) {
      errorMessage.value = 'فشل في تحميل الطلبات: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void setFilterStatus(String status) {
    _filterStatus.value = status;
  }

  void setSortBy(String sort) {
    _sortBy.value = sort;
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate.value = start;
    _endDate.value = end;
  }

  void clearFilters() {
    _filterStatus.value = 'all';
    _sortBy.value = 'date_desc';
    _startDate.value = null;
    _endDate.value = null;
  }

  Future<void> reorder(Order order) async {
    try {
      isLoading.value = true;
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) throw Exception('يجب تسجيل الدخول');

      for (final item in order.items) {
        await _supabaseClient.from('cart_items').upsert({
          'user_id': userId,
          'food_id': item.foodId,
          'quantity': item.quantity,
          'special_instructions': item.specialInstructions,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      Get.snackbar(
        'نجح',
        'تم إضافة الطلب إلى السلة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.toNamed('/cart');
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إعادة الطلب: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Reorder error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // دالة جديدة للتحديث التلقائي
  Stream<List<Order>> get ordersStream {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((event) => event.map((data) => Order.fromJson(data)).toList());
  }

  @override
  void onInit() {
    super.onInit();
    loadUserOrders();
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;

    if (query.isNotEmpty && !recentSearches.contains(query)) {
      recentSearches.insert(0, query);
      // حفظ فقط آخر 5 عمليات بحث
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    }
  }
}
