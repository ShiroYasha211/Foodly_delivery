import 'package:flutter/material.dart';

class Order {
  final int id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final List<OrderItem> items;
  final String? deliveryAddress;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.items,
    this.deliveryAddress,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int, // تأكد أنه int
      orderNumber: json['order_number'] ?? 'N/A',
      orderDate: DateTime.parse(json['created_at']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      items:
          (json['order_items'] as List<dynamic>? ??
                  []) // تغيير من 'items' إلى 'order_items'
              .map((item) => OrderItem.fromJson(item))
              .toList(),
      deliveryAddress: json['delivery_address'],
      paymentMethod: json['payment_method'],
    );
  }

  // باقي الكود بدون تغيير...
  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'قيد التحضير';
      case 'ready':
        return 'جاهز للتوصيل';
      case 'delivering':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.blueAccent;
      case 'ready':
        return Colors.green;
      case 'delivering':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class OrderItem {
  final int foodId; // تغيير من String إلى int
  String foodName;
  final int quantity;
  final double unitPrice;
  final String? specialInstructions;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unitPrice,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['food_id'] as int, // تأكد أنه int
      foodName: json['food_name'] ?? 'Unknown',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] as num).toDouble(),
      specialInstructions: json['special_instructions'],
    );
  }

  double get totalPrice => unitPrice * quantity;
}
