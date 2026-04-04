import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = false;

  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _apiService.getCategories();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name, String description) async {
    try {
      await _apiService.createCategory({'name': name, 'description': description});
      await fetchCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(String id, String name, String description) async {
    try {
      await _apiService.updateCategory(id, {'name': name, 'description': description});
      await fetchCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.deleteCategory(id);
      await fetchCategories();
    } catch (e) {
      rethrow;
    }
  }
}
