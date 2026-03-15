import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  final _api = ApiService();

  Future<void> fetchOrders({int? userId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final endpoint =
          userId != null ? 'orders/read.php?user_id=$userId' : 'orders/read.php';
      final res = await _api.get(endpoint);
      if (res['success'] == true) {
        _orders = (res['data'] as List).map((e) => Order.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Failed to load orders: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> placeOrder({
    required int userId,
    required double totalAmount,
    required String shippingAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _api.post('orders/create.php', {
        'user_id': userId,
        'total_amount': totalAmount,
        'shipping_address': shippingAddress,
        'items': items,
      });
      if (res['success'] == true) {
        await fetchOrders(userId: userId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final res = await _api.put('orders/update_status.php', {
        'id': orderId,
        'status': status,
      });
      if (res['success'] == true) {
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          _orders[idx] = Order(
            id: _orders[idx].id,
            userId: _orders[idx].userId,
            customerName: _orders[idx].customerName,
            totalAmount: _orders[idx].totalAmount,
            status: status,
            shippingAddress: _orders[idx].shippingAddress,
            createdAt: _orders[idx].createdAt,
            items: _orders[idx].items,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }
}
