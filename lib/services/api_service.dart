import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/diary.dart';

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
  static const String baseUrl = 'http://192.168.31.90:8080/api';
  static String? _token;
  
  // 添加 http 客户端依赖注入支持，方便测试
  static http.Client httpClient = http.Client();

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
          response = await httpClient.get(url, headers: _headers);
          break;
        case 'POST':
          response = await httpClient.post(
            url,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await httpClient.put(
            url,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await httpClient.delete(url, headers: _headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // 处理新的错误响应格式
      if (jsonData.containsKey('error')) {
        return ApiResponse<T>(
          code: response.statusCode,
          message: jsonData['error'] as String,
        );
      }
      
      return ApiResponse.fromJson(jsonData, fromJson);
    } catch (e) {
      debugPrint('API请求错误: $e');
      return ApiResponse<T>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<void>> sendCode(String email) {
    return _request<void>('POST', '/auth/send-code', body: {'email': email});
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

  static Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String nickname,
    required String gender,
    required int age,
    required String profession,
    String? avatar,
  }) {
    return _request<Map<String, dynamic>>(
      'POST',
      '/profile',
      body: {
        'nickname': nickname,
        'gender': gender,
        'age': age,
        'profession': profession,
        if (avatar != null) 'avatar': avatar,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> generateUploadUrl(String fileType) {
    return _request<Map<String, dynamic>>(
      'POST',
      '/upload/generate-url',
      body: {
        'file_type': fileType,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<Diary>> createDiary(String content, {String? date}) async {
    final body = <String, dynamic>{'content': content};
    if (date != null) {
      body['date'] = date;
    }
    
    try {
      final url = Uri.parse('$baseUrl/diary/create');
      final response = await httpClient.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );
      
      final jsonData = jsonDecode(response.body);
      
      // 处理错误响应
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('error')) {
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: jsonData['error'] as String,
        );
      }
      
      // 处理直接返回日记对象的情况
      if (jsonData is Map<String, dynamic>) {
        final diary = Diary.fromJson(jsonData);
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: '创建日记成功',
          data: diary,
        );
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      debugPrint('API请求错误: $e');
      return ApiResponse<Diary>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<List<Diary>>> getDiaries() async {
    try {
      final url = Uri.parse('$baseUrl/diary/list');
      final response = await httpClient.post(url, headers: _headers);
      
      final jsonData = jsonDecode(response.body);
      
      // 处理直接返回数组的情况（与统一响应格式不同）
      if (jsonData is List) {
        final diaries = jsonData.map((item) => Diary.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse<List<Diary>>(
          code: response.statusCode,
          message: '获取日记列表成功',
          data: diaries,
        );
      }
      
      // 处理统一响应格式
      if (jsonData is Map<String, dynamic>) {
        // 检查是否有错误
        if (jsonData.containsKey('error')) {
          return ApiResponse<List<Diary>>(
            code: response.statusCode,
            message: jsonData['error'] as String,
          );
        }
        
        // 处理统一响应格式
        return ApiResponse.fromJson(
          jsonData, 
          (data) => (data as List).map((item) => Diary.fromJson(item as Map<String, dynamic>)).toList(),
        );
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      debugPrint('API请求错误: $e');
      return ApiResponse<List<Diary>>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<Diary>> getDiary(int id) async {
    try {
      final url = Uri.parse('$baseUrl/diary/get');
      final response = await httpClient.post(
        url,
        headers: _headers,
        body: jsonEncode({'id': id}),
      );
      
      final jsonData = jsonDecode(response.body);
      
      // 处理错误响应
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('error')) {
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: jsonData['error'] as String,
        );
      }
      
      // 处理直接返回日记对象的情况
      if (jsonData is Map<String, dynamic>) {
        final diary = Diary.fromJson(jsonData);
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: '获取日记成功',
          data: diary,
        );
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      debugPrint('API请求错误: $e');
      return ApiResponse<Diary>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<Diary>> updateDiary(int id, String content) async {
    try {
      final url = Uri.parse('$baseUrl/diary/update');
      final response = await httpClient.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'id': id,
          'content': content,
        }),
      );
      
      final jsonData = jsonDecode(response.body);
      
      // 处理错误响应
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('error')) {
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: jsonData['error'] as String,
        );
      }
      
      // 处理直接返回日记对象的情况
      if (jsonData is Map<String, dynamic>) {
        final diary = Diary.fromJson(jsonData);
        return ApiResponse<Diary>(
          code: response.statusCode,
          message: '更新日记成功',
          data: diary,
        );
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      debugPrint('API请求错误: $e');
      return ApiResponse<Diary>(
        code: 500,
        message: '网络请求失败: $e',
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> deleteDiary(int id) {
    return _request<Map<String, dynamic>>(
      'POST',
      '/diary/delete',
      body: {'id': id},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}