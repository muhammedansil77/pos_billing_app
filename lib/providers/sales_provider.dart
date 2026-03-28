import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _bills = [];
  bool _isLoading = false;
  String _currentFilter = 'today';
  String _paymentModeFilter = 'All'; // 'All', 'Cash', 'Credit'
  DateTimeRange? _customDateRange;

  List<dynamic> get bills => _bills;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  String get paymentModeFilter => _paymentModeFilter;
  DateTimeRange? get customDateRange => _customDateRange;

  double get totalSalesAmount => _bills.fold(0.0, (sum, bill) => sum + (bill['grandTotal'] ?? 0.0));
  
  double get totalProfit {
    double profit = 0;
    for (var bill in _bills) {
      profit += calculateBillProfit(bill);
    }
    return profit;
  }

  double calculateBillProfit(Map<String, dynamic> bill) {
    double billProfit = 0;
    final items = bill['items'] as List? ?? [];
    for (var item in items) {
      final sellingPrice = (item['price'] ?? 0).toDouble();
      final wholesalePrice = (item['wholesalePrice'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 0).toDouble();
      billProfit += (sellingPrice - wholesalePrice) * quantity;
    }
    billProfit -= (bill['discount'] ?? 0).toDouble();
    return billProfit;
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _customDateRange = null;
    notifyListeners();
    fetchBills();
  }

  void setPaymentModeFilter(String mode) {
    _paymentModeFilter = mode;
    notifyListeners();
    fetchBills();
  }

  void setCustomRange(DateTimeRange range) {
    _currentFilter = 'custom';
    _customDateRange = range;
    notifyListeners();
    fetchBills();
  }

  Future<void> fetchBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      String? filterParam;
      String? startDate;
      String? endDate;

      if (_currentFilter != 'all' && _currentFilter != 'custom') {
        filterParam = _currentFilter;
      } else if (_currentFilter == 'custom' && _customDateRange != null) {
        startDate = _customDateRange!.start.toIso8601String();
        endDate = _customDateRange!.end.toIso8601String();
      }

      _bills = await _apiService.getBills(
        filter: filterParam,
        startDate: startDate,
        endDate: endDate,
        paymentMode: _paymentModeFilter == 'All' ? null : _paymentModeFilter,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
