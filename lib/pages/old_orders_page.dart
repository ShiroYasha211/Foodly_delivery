import 'package:flutter/material.dart';
import 'package:food_delivery/controllers/order_controller.dart';
import 'package:food_delivery/models/order_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OldOrdersPage extends StatefulWidget {
  const OldOrdersPage({super.key});
  static const nameRoute = '/old-orders';

  @override
  State<OldOrdersPage> createState() => _OldOrdersPageState();
}

class _OldOrdersPageState extends State<OldOrdersPage> {
  final OrderController _orderController = Get.put(OrderController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orderController.orders.isEmpty) {
        _orderController.loadUserOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الطلبات القديمة"),
        centerTitle: false,
        actions: [
          // مؤشرات ذكية
          Obx(() {
            final hasSearch = _orderController.searchQuery.isNotEmpty;
            final hasFilters =
                _orderController.filterStatus != 'all' ||
                _orderController.startDate != null ||
                _orderController.endDate != null;

            return Row(
              children: [
                if (hasSearch || hasFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_orderController.filteredOrders.length}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.search),
                      if (hasSearch)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showSearchDialog,
                  tooltip: 'بحث في الطلبات',
                ),

                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list),
                      if (hasFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'تصفية وترتيب الطلبات',
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_orderController.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_orderController.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _orderController.loadUserOrders,
                  child: const Text("إعادة المحاولة"),
                ),
              ],
            ),
          );
        }
        if (_orderController.filteredOrders.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _orderController.filterStatus != 'all' ||
                            _orderController.startDate != null ||
                            _orderController.endDate != null
                        ? "لا توجد طلبات تطابق عوامل التصفية"
                        : "لا توجد طلبات سابقة",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (_orderController.filterStatus != 'all' ||
                      _orderController.startDate != null ||
                      _orderController.endDate != null)
                    ElevatedButton(
                      onPressed: () => _orderController.clearFilters(),
                      child: const Text('مسح الفلاتر'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('العودة للرئيسية'),
                    ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _orderController.loadUserOrders,
          child: ListView.separated(
            itemBuilder: (context, index) {
              final order = _orderController.filteredOrders[index];
              return _buildOrderCard(order, context);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: _orderController.filteredOrders.length,
            padding: const EdgeInsets.all(16),
          ),
        );
      }),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    final FocusNode searchFocusNode = FocusNode();

    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColorDark,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search, size: 40, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        'البحث في الطلبات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ابحث برقم الطلب فقط',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Search input
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _orderController.setSearchQuery(value);
                      Get.back();
                    },
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم الطلب...',
                      prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                _orderController.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _orderController.setSearchQuery('');
                            Get.back();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _orderController.setSearchQuery(
                              searchController.text,
                            );
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'بحث',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent searches (optional)
                if (_orderController.recentSearches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          'عمليات البحث الأخيرة',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _orderController.recentSearches
                              .take(3)
                              .map(
                                (search) => ActionChip(
                                  label: Text(search),
                                  onPressed: () {
                                    searchController.text = search;
                                    _orderController.setSearchQuery(search);
                                    Get.back();
                                  },
                                  backgroundColor: Colors.grey[100],
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      searchController.dispose();
      searchFocusNode.dispose();
    });

    // Auto focus after dialog opens
    Future.delayed(const Duration(milliseconds: 100), () {
      searchFocusNode.requestFocus();
    });
  }

  Widget _buildOrderCard(Order order, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'الطلب #${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy/MM/dd').format(order.orderDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm').format(order.orderDate),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),

                const SizedBox(height: 16),

                // Status and Price
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: order.statusColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            size: 16,
                            color: order.statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.statusText,
                            style: TextStyle(
                              color: order.statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Total Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'المجموع',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${order.totalAmount.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Order Items Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوجبات المطلوبة:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.foodName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${item.totalPrice.toStringAsFixed(2)} \$',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (order.items.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${order.items.length - 3} عناصر أخرى',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    // Details Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showOrderDetails(order),
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'التفاصيل',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reorder Button
                    Expanded(
                      child: Obx(
                        () => _orderController.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: () => _confirmReorder(order),
                                icon: const Icon(Icons.replay, size: 18),
                                label: const Text(
                                  'إعادة الطلب',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReorder(Order order) {
    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_cart_checkout,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'إعادة الطلب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'هل تريد إضافة هذا الطلب إلى السلة؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _orderController.reorder(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'تأكيد',
                        style: TextStyle(color: Colors.white),
                      ),
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

  void _showFilterDialog() {
    String tempFilterStatus = _orderController.filterStatus;
    String tempSortBy = _orderController.sortBy;
    DateTimeRange? tempDateRange;

    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColorDark,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تصفية وترتيب الطلبات',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // حالة الطلب
                        _buildFilterSection(
                          title: 'حالة الطلب',
                          icon: Icons.filter_alt_rounded,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tempFilterStatus,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                items:
                                    [
                                      'all',
                                      'pending',
                                      'confirmed',
                                      'preparing',
                                      'ready',
                                      'delivering',
                                      'delivered',
                                      'cancelled',
                                    ].map((status) {
                                      String text;
                                      IconData iconData;
                                      switch (status) {
                                        case 'all':
                                          text = 'جميع الطلبات';
                                          iconData = Icons.all_inclusive;
                                          break;
                                        case 'pending':
                                          text = 'قيد الانتظار';
                                          iconData = Icons.access_time;
                                          break;
                                        case 'confirmed':
                                          text = 'تم التأكيد';
                                          iconData = Icons.check_circle_outline;
                                          break;
                                        case 'preparing':
                                          text = 'قيد التحضير';
                                          iconData = Icons.restaurant;
                                          break;
                                        case 'ready':
                                          text = 'جاهز للتوصيل';
                                          iconData = Icons.done;
                                          break;
                                        case 'delivering':
                                          text = 'قيد التوصيل';
                                          iconData = Icons.delivery_dining;
                                          break;
                                        case 'delivered':
                                          text = 'تم التسليم';
                                          iconData = Icons.task_alt;
                                          break;
                                        case 'cancelled':
                                          text = 'ملغي';
                                          iconData = Icons.cancel;
                                          break;
                                        default:
                                          text = status;
                                          iconData = Icons.help;
                                      }
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Icon(
                                              iconData,
                                              size: 20,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 12),
                                            Text(text),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    tempFilterStatus = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // الترتيب
                        _buildFilterSection(
                          title: 'ترتيب حسب',
                          icon: Icons.sort,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tempSortBy,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'date_desc',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 12),
                                        Text('الأحدث أولاً'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'date_asc',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 12),
                                        Text('الأقدم أولاً'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'price_desc',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 12),
                                        Text('الأعلى سعراً أولاً'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'price_asc',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.money_off,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 12),
                                        Text('الأقل سعراً أولاً'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    tempSortBy = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // نطاق التاريخ
                        _buildFilterSection(
                          title: 'نطاق التاريخ',
                          icon: Icons.calendar_today,
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final DateTimeRange? picked =
                                      await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                        initialDateRange: DateTimeRange(
                                          start:
                                              _orderController.startDate ??
                                              DateTime.now().subtract(
                                                const Duration(days: 30),
                                              ),
                                          end:
                                              _orderController.endDate ??
                                              DateTime.now(),
                                        ),
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      tempDateRange = picked;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  tempDateRange != null
                                      ? '${DateFormat('yyyy/MM/dd').format(tempDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(tempDateRange!.end)}'
                                      : 'اختر نطاق التاريخ',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.black87,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              if (tempDateRange != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        tempDateRange = null;
                                      });
                                    },
                                    child: const Text('إزالة التصفية بالتاريخ'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        // Clear button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _orderController.clearFilters();
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: Text(
                              'مسح الكل',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Apply button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _orderController.setFilterStatus(
                                tempFilterStatus,
                              );
                              _orderController.setSortBy(tempSortBy);
                              if (tempDateRange != null) {
                                _orderController.setDateRange(
                                  tempDateRange!.start,
                                  tempDateRange!.end,
                                );
                              } else {
                                _orderController.setDateRange(null, null);
                              }
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'تطبيق',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تفاصيل الطلب',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: order.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: order.statusColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(order.status),
                              color: order.statusColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حالة الطلب',
                                    style: TextStyle(
                                      color: order.statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    order.statusText,
                                    style: TextStyle(
                                      color: order.statusColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Order Information
                      _buildDetailSection(
                        title: 'معلومات الطلب',
                        icon: Icons.info_rounded,
                        children: [
                          _buildDetailItem(
                            icon: Icons.calendar_today,
                            label: 'تاريخ الطلب',
                            value: DateFormat(
                              'yyyy/MM/dd - HH:mm',
                            ).format(order.orderDate),
                          ),
                          _buildDetailItem(
                            icon: Icons.attach_money,
                            label: 'المجموع',
                            value: '${order.totalAmount.toStringAsFixed(2)} \$',
                            isImportant: true,
                          ),
                          if (order.deliveryAddress != null)
                            _buildDetailItem(
                              icon: Icons.location_on,
                              label: 'عنوان التوصيل',
                              value: order.deliveryAddress!,
                            ),
                          if (order.paymentMethod != null)
                            _buildDetailItem(
                              icon: Icons.payment,
                              label: 'طريقة الدفع',
                              value: order.paymentMethod!,
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Order Items
                      _buildDetailSection(
                        title: 'الوجبات المطلوبة',
                        icon: Icons.restaurant_menu,
                        children: order.items
                            .map((item) => _buildOrderItemCard(item))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Close button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                        label: const Text('إغلاق'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Reorder button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _confirmReorder(order);
                        },
                        icon: const Icon(Icons.replay, color: Colors.white),
                        label: const Text(
                          'إعادة الطلب',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done;
      case 'delivering':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.foodName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${item.quantity}x',
                style: TextStyle(
                  color: Theme.of(Get.context!).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.unitPrice.toStringAsFixed(2)} ر.ي',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                '${item.totalPrice.toStringAsFixed(2)} ر.ي',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (item.specialInstructions != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ملاحظات: ${item.specialInstructions}',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isImportant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isImportant
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isImportant ? Colors.green : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
