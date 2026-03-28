import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _customers = [];
  List<dynamic> _creditCustomers = [];
  bool _isLoading = false;

  List<dynamic> get customers => _customers;
  List<dynamic> get creditCustomers => _creditCustomers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _apiService.getCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCreditBalances() async {
    _isLoading = true;
    notifyListeners();

    try {
      _creditCustomers = await _apiService.getCreditBalances();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Map<String, dynamic> customerData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createCustomer(customerData);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> customerData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateCustomer(id, customerData);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _apiService.deleteCustomer(id);
      _customers.removeWhere((c) => c['_id'] == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
