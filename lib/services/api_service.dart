import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/department.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  final Dio _dio;
  String? _token;
  void Function()? onUnauthorized;

  ApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: API_BASE_URL)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            // notify auth layer
            if (onUnauthorized != null) onUnauthorized!();
          }
          return handler.next(err);
        },
      ),
    );
  }

  void setToken(String? token) {
    _token = token;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String department,
    required String phoneNumber,
  }) async {
    try {
      final resp = await _dio.post(
        '/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'department': department,
          'phone_number': phoneNumber,
        },
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw ApiException(_friendlyErrorFromDio(e));
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw ApiException(_friendlyErrorFromDio(e));
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final resp = await _dio.get('/me');
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw ApiException(_friendlyErrorFromDio(e));
    }
  }

  Future<Map<String, dynamic>> askQuestion({required String question}) async {
    try {
      final resp = await _dio.post('/ask', data: {'question': question});
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw ApiException(_friendlyErrorFromDio(e));
    }
  }

  Future<List<Department>> getDepartments() async {
    try {
      final resp = await _dio.get('/departments');
      final data = resp.data as Map<String, dynamic>;
      final departmentsList = data['departments'] as List;
      return departmentsList
          .map((item) => Department.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_friendlyErrorFromDio(e));
    }
  }

  String _friendlyErrorFromDio(DioException e) {
    // Connection / Socket issues
    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return 'Failed to connect to the KARE API at $API_BASE_URL.\nPlease ensure the server is running and reachable from this device.';
    }

    // Timeout
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Request timed out. Please check your network and try again.';
    }

    // Bad response (4xx/5xx)
    if (e.response != null) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      return 'Server responded with status $status: ${data ?? e.message}';
    }

    // Fallback
    return e.message ?? 'An unknown network error occurred';
  }
}
