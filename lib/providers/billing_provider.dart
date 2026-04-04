import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BillingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _billingItems = [];
  double _discount = 0.0;
  bool _isLoading = false;
  String _paymentMode = 'Cash';
  Map<String, dynamic>? _selectedCustomer;
  String? _editingBillId;

  List<Map<String, dynamic>> get billingItems => _billingItems;
  double get discount => _discount;
  bool get isLoading => _isLoading;
  String get paymentMode => _paymentMode;
  Map<String, dynamic>? get selectedCustomer => _selectedCustomer;
  String? get editingBillId => _editingBillId;

  double get subtotal => _billingItems.fold(0.0, (sum, item) {
    final price = (item['sellingPrice'] ?? item['price'] ?? 0.0) as num;
    final quantity = (item['billQuantity'] ?? 1.0) as num;
    return sum + (price.toDouble() * quantity.toDouble());
  });
  
  double get totalGst => _billingItems.fold(0.0, (sum, item) {
    final price = (item['sellingPrice'] ?? item['price'] ?? 0.0) as num;
    final quantity = (item['billQuantity'] ?? 1.0) as num;
    final gstRate = (item['gstPercentage'] ?? 0.0) as num;
    return sum + (price.toDouble() * quantity.toDouble() * (gstRate.toDouble() / 100));
  });

  double get grandTotal => (subtotal + totalGst) - _discount;

  void setPaymentMode(String mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void setSelectedCustomer(Map<String, dynamic>? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void addItem(Map<String, dynamic> product, double quantity) {
    final availableStock = (product['quantity'] ?? 0).toDouble();
    final unit = product['unit'] ?? 'Units';
    
    final existingIndex = _billingItems.indexWhere((item) => item['_id'] == product['_id']);
    double currentInBill = 0;
    if (existingIndex != -1) {
      currentInBill = ((_billingItems[existingIndex]['billQuantity'] ?? 0) as num).toDouble();
    }

    if (currentInBill + quantity > availableStock) {
      throw 'STOCK_LIMIT|${availableStock.toStringAsFixed(unit == 'Units' ? 0 : 3)}|$unit';
    }

    if (existingIndex != -1) {
      _billingItems[existingIndex]['billQuantity'] = ( (_billingItems[existingIndex]['billQuantity'] ?? 0) as num).toDouble() + quantity;
    } else {
      _billingItems.add({
        ...product,
        'billQuantity': quantity,
      });
    }
    notifyListeners();
  }

  void updateQuantity(int index, num delta) {
    final item = _billingItems[index];
    final availableStock = (item['quantity'] ?? 0).toDouble();
    final currentInBill = ( (item['billQuantity'] ?? 0) as num).toDouble();
    final unit = item['unit'] ?? 'Units';

    if (delta > 0 && currentInBill + delta > availableStock) {
      throw 'STOCK_LIMIT|${availableStock.toStringAsFixed(unit == 'Units' ? 0 : 3)}|$unit';
    }

    _billingItems[index]['billQuantity'] = (currentInBill + delta.toDouble());
    if (_billingItems[index]['billQuantity'] <= 0) {
      _billingItems.removeAt(index);
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _billingItems.removeAt(index);
    notifyListeners();
  }

  Future<void> checkout() async {
    if (_billingItems.isEmpty) throw Exception('No items in bill');
    if (_paymentMode == 'Credit' && _selectedCustomer == null) {
      throw Exception('PLEASE_SELECT_CUSTOMER');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final billData = {
        'customer': _selectedCustomer?['_id'], // Backend now allows optional customer for Cash
        'paymentMode': _paymentMode,
        'items': _billingItems.map((item) {
          final price = (item['sellingPrice'] ?? item['price'] ?? 0.0) as num;
          final quantity = (item['billQuantity'] ?? 1.0) as num;
          final gstRate = (item['gstPercentage'] ?? 0.0) as num;
          final gstAmount = price.toDouble() * quantity.toDouble() * (gstRate.toDouble() / 100);
          final itemSubtotal = price.toDouble() * quantity.toDouble();
          
          return {
            'product': item['product'] ?? item['_id'], // support old bill format vs new item format
            'name': item['name'],
            'quantity': quantity,
            'price': price,
            'wholesalePrice': (item['wholesalePrice'] ?? 0.0) as num,
            'gstAmount': gstAmount,
            'subtotal': itemSubtotal,
          };
        }).toList(),
        'subtotal': subtotal,
        'totalGst': totalGst,
        'discount': _discount,
        'grandTotal': grandTotal,
      };

      if (_editingBillId != null) {
        await _apiService.updateBill(_editingBillId!, billData);
      } else {
        await _apiService.createBill(billData);
      }
      clearBill();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadBillForEditing(Map<String, dynamic> bill) {
    clearBill();
    _editingBillId = bill['_id'];
    _paymentMode = bill['paymentMode'] ?? 'Cash';
    _selectedCustomer = bill['customer'] is Map ? bill['customer'] : null;
    _discount = (bill['discount'] ?? 0.0).toDouble();

    final items = bill['items'] as List<dynamic>? ?? [];
    for (var item in items) {
      // Reconstruct product structure for billing provider to use
      _billingItems.add({
        '_id': item['product'], // product object id
        'product': item['product'], // for fallback later
        'name': item['name'],
        'price': (item['price'] ?? 0.0).toDouble(),
        'wholesalePrice': (item['wholesalePrice'] ?? 0.0).toDouble(),
        'billQuantity': (item['quantity'] ?? 1).toDouble(),
        // Since we are editing, we bypass max stock limit for currently loaded items since they've already been deducted.
        // For new additions, they'll check against current available stock. We set an arbitrarily large quantity for loaded items just so the UI doesn't block them. Or we should fetch actual product info.
        // For simplicity, allowing current quantity + 999
        'quantity': ((item['quantity'] ?? 1).toDouble()) + 999.0, 
        'unit': item['unit'] ?? 'Units', 
      });
    }
    notifyListeners();
  }

  void clearBill() {
    _billingItems.clear();
    _discount = 0.0;
    _paymentMode = 'Cash';
    _selectedCustomer = null;
    _editingBillId = null;
    notifyListeners();
  }
}
