import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.fold(0, (sum, i) => sum + i.subtotal);

  final _api = ApiService();

  Future<void> fetchCart(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('cart/read.php?user_id=$userId');
      if (res['success'] == true) {
        _items = (res['data'] as List)
            .map((e) => CartItem.fromJson(e))
            .toList();
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> addToCart(int userId, int productId, int quantity) async {
    try {
      final res = await _api.post('cart/add.php', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
      if (res['success'] == true) {
        await fetchCart(userId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateQuantity(int userId, int cartId, int quantity) async {
    try {
      final res = await _api.put('cart/update.php', {
        'id': cartId,
        'quantity': quantity,
      });
      if (res['success'] == true) {
        await fetchCart(userId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeItem(int userId, int cartId) async {
    try {
      final res = await _api.delete('cart/delete.php?id=$cartId');
      if (res['success'] == true) {
        _items.removeWhere((i) => i.id == cartId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
}
