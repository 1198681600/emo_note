import 'dart:convert';
import 'package:flutter/foundation.dart';

/// API请求日志服务
class ApiLogger {
  static const String _tag = 'API_LOG';
  
  /// 记录API请求
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return; // 只在调试模式下记录日志
    
    final logLines = <String>[
      '┌─────────────────────────────────────────────────────────────',
      '│ [$_tag] API REQUEST',
      '├─────────────────────────────────────────────────────────────',
      '│ Method: $method',
      '│ URL: $url',
    ];
    
    // 记录请求头
    if (headers != null && headers.isNotEmpty) {
      logLines.add('│ Headers:');
      headers.forEach((key, value) {
        // 脱敏处理Authorization头
        final displayValue = key.toLowerCase() == 'authorization' 
            ? _maskToken(value) 
            : value;
        logLines.add('│   $key: $displayValue');
      });
    }
    
    // 记录请求体
    if (body != null) {
      logLines.add('│ Body:');
      final bodyStr = _formatBody(body);
      // 将多行内容按行分割并添加前缀
      bodyStr.split('\n').forEach((line) {
        logLines.add('│   $line');
      });
    }
    
    logLines.add('└─────────────────────────────────────────────────────────────');
    
    // 打印所有日志行
    for (final line in logLines) {
      debugPrint(line);
    }
  }
  
  /// 记录API响应
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    dynamic body,
    Duration? duration,
  }) {
    if (!kDebugMode) return; // 只在调试模式下记录日志
    
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final statusEmoji = isSuccess ? '✅' : '❌';
    
    final logLines = <String>[
      '┌─────────────────────────────────────────────────────────────',
      '│ [$_tag] API RESPONSE $statusEmoji',
      '├─────────────────────────────────────────────────────────────',
      '│ Method: $method',
      '│ URL: $url',
      '│ Status: $statusCode ${_getStatusText(statusCode)}',
    ];
    
    // 记录耗时
    if (duration != null) {
      logLines.add('│ Duration: ${duration.inMilliseconds}ms');
    }
    
    // 记录响应头（可选）
    if (headers != null && headers.isNotEmpty && kDebugMode) {
      logLines.add('│ Headers:');
      headers.forEach((key, value) {
        logLines.add('│   $key: $value');
      });
    }
    
    // 记录响应体
    if (body != null) {
      logLines.add('│ Response:');
      final bodyStr = _formatBody(body);
      // 将多行内容按行分割并添加前缀
      bodyStr.split('\n').forEach((line) {
        logLines.add('│   $line');
      });
    }
    
    logLines.add('└─────────────────────────────────────────────────────────────');
    
    // 打印所有日志行
    for (final line in logLines) {
      debugPrint(line);
    }
  }
  
  /// 记录API错误
  static void logError({
    required String method,
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return; // 只在调试模式下记录日志
    
    final logLines = <String>[
      '┌─────────────────────────────────────────────────────────────',
      '│ [$_tag] API ERROR ❌',
      '├─────────────────────────────────────────────────────────────',
      '│ Method: $method',
      '│ URL: $url',
      '│ Error: $error',
    ];
    
    if (stackTrace != null && kDebugMode) {
      logLines.add('│ StackTrace:');
      stackTrace.toString().split('\n').take(5).forEach((line) {
        logLines.add('│   $line');
      });
    }
    
    logLines.add('└─────────────────────────────────────────────────────────────');
    
    // 打印所有日志行
    for (final line in logLines) {
      debugPrint(line);
    }
  }
  
  /// 格式化请求/响应体
  static String _formatBody(dynamic body) {
    if (body == null) return 'null';
    
    try {
      // 如果是字符串，尝试解析为JSON并格式化
      if (body is String) {
        if (body.isEmpty) return 'empty';
        
        try {
          final parsed = jsonDecode(body);
          return const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (e) {
          // 如果不是JSON，直接返回字符串（截断长内容）
          return body.length > 1000 ? '${body.substring(0, 1000)}...[truncated]' : body;
        }
      }
      
      // 如果是Map或List，直接格式化
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (e) {
      return body.toString();
    }
  }
  
  /// 脱敏Token
  static String _maskToken(String token) {
    if (token.length <= 10) return '***';
    return '${token.substring(0, 10)}...***';
  }
  
  /// 获取状态码描述
  static String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 409: return 'Conflict';
      case 500: return 'Internal Server Error';
      default: return '';
    }
  }
}