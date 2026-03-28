import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = false;

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _apiService.getProducts();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createProduct(productData);
      await fetchProducts(); // Refresh list after adding
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateProduct(id, productData);
      await fetchProducts(); // Refresh list after updating
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p['_id'] == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
