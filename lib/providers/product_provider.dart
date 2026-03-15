import 'package:flutter/foundation.dart' hide Category;
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  int? _selectedCategory;

  List<Product> get products {
    var list = _products;
    if (_selectedCategory != null) {
      list = list.where((p) => p.categoryId == _selectedCategory).toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_search.toLowerCase()) ||
              p.description.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  int? get selectedCategory => _selectedCategory;

  final _api = ApiService();

  void setSearch(String val) {
    _search = val;
    notifyListeners();
  }

  void setCategory(int? id) {
    _selectedCategory = id;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('products/read.php');
      if (res['success'] == true) {
        _products = (res['data'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Failed to load products: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _api.get('categories/read.php');
      if (res['success'] == true) {
        _categories = (res['data'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Product?> getProduct(int id) async {
    try {
      final res = await _api.get('products/read_one.php?id=$id');
      if (res['success'] == true) return Product.fromJson(res['data']);
    } catch (_) {}
    return null;
  }

  Future<bool> createProduct({
    required Map<String, String> fields,
    required dynamic imageBytes,
    String? imageName,
  }) async {
    try {
      final res = await _api.uploadProduct(
        fields: fields,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      if (res['success'] == true) {
        await fetchProducts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateProduct({
    required int id,
    required Map<String, String> fields,
    dynamic imageBytes,
    String? imageName,
  }) async {
    try {
      final res = await _api.uploadProduct(
        fields: fields,
        imageBytes: imageBytes,
        imageName: imageName,
        method: 'PUT',
        productId: id,
      );
      if (res['success'] == true) {
        await fetchProducts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final res = await _api.delete('products/delete.php?id=$id');
      if (res['success'] == true) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> createCategory(String name) async {
    try {
      final res =
          await _api.post('categories/create.php', {'name': name});
      if (res['success'] == true) {
        await fetchCategories();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final res = await _api.delete('categories/delete.php?id=$id');
      if (res['success'] == true) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
