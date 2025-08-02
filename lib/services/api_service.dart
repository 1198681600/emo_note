import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJson) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromJson != null ? fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => code == 200;
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static String? get token => _token;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: _headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(jsonData, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<void>> sendCode(String email) {
    return _request<void>('POST', '/auth/send-code', body: {'email': email});
  }

  static Future<ApiResponse<void>> register(String email, String code) {
    return _request<void>('POST', '/auth/register', body: {
      'email': email,
      'code': code,
    });
  }

  static Future<ApiResponse<void>> verifyEmail(String email, String code) {
    return _request<void>('POST', '/auth/verify-email', body: {
      'email': email,
      'code': code,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> login(String email, String code) {
    return _request<Map<String, dynamic>>(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'code': code,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getProfile() {
    return _request<Map<String, dynamic>>(
      'GET',
      '/profile',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<void>> logout() {
    return _request<void>('POST', '/logout');
  }
}