import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://192.168.125.198:5000";

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '$baseUrl/api/', // Using localhost forwarded via ADB reverse
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login', // Use relative path
        data: {'email': email, 'password': password},
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.data['token']);
      return response.data;
    } on DioException catch (e) {
      print('LOGIN ERROR Type: ${e.type}');
      print('LOGIN ERROR Message: ${e.message}');
      print('LOGIN ERROR Data: ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Failed to connect to server. Check your network.');
    }
  }

  Future<List<dynamic>> getProducts() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'products', // Use relative path
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get products');
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.post(
        'products', // Use relative path
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create product',
      );
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.put(
        'products/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update product',
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        'products/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete product',
      );
    }
  }

  Future<List<dynamic>> getCustomers() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'customers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get customers');
    }
  }

  Future<void> createCustomer(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.post(
        'customers',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create customer',
      );
    }
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.put(
        'customers/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update customer',
      );
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        'customers/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete customer',
      );
    }
  }

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'products/barcode/$barcode', // Use relative path
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product with this barcode not found');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch product details',
      );
    }
  }

  Future<void> createBill(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.post(
        'bills', // Use relative path
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to save bill',
      );
    }
  }

  Future<void> updateBill(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.put(
        'bills/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update bill',
      );
    }
  }

  Future<List<dynamic>> getBills({String? filter, String? startDate, String? endDate, String? customer, String? paymentMode}) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'bills',
        queryParameters: {
          if (filter != null) 'filter': filter,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (customer != null) 'customer': customer,
          if (paymentMode != null) 'paymentMode': paymentMode,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get bills');
    }
  }

  Future<List<dynamic>> getCreditBalances() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'bills/credit',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get credit balances');
    }
  }

  Future<void> createPayment(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      await _dio.post(
        'payments',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to record payment');
    }
  }

  Future<List<dynamic>> getPayments(String customerId) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        'payments/customer/$customerId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch payment history');
    }
  }
}
