import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../widgets/emotion_gradient_background.dart';
import 'api_logger.dart';

class EmotionAnalysisResult {
  final List<EmotionData> emotions;
  final EmotionGradientType gradientType;
  final String reasoning;
  final Map<String, dynamic> summary;
  final List<String> insights;
  final List<String> recommendations;

  EmotionAnalysisResult({
    required this.emotions,
    required this.gradientType,
    required this.reasoning,
    required this.summary,
    required this.insights,
    required this.recommendations,
  });

  factory EmotionAnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    
    // 解析情绪数据
    final emotionsJson = data['emotions'] as List;
    final emotions = emotionsJson.map((emotionJson) {
      return EmotionData(
        emotion: emotionJson['emotion'],
        color: _parseColor(emotionJson['color']),
        intensity: (emotionJson['intensity'] as num).toDouble(),
        time: _parseTimeFromPeriod(emotionJson['time_period']),
      );
    }).toList();

    // 解析渐变类型
    final gradientTypeStr = data['gradient_suggestion']['type'] as String;
    final gradientType = _parseGradientType(gradientTypeStr);

    return EmotionAnalysisResult(
      emotions: emotions,
      gradientType: gradientType,
      reasoning: data['gradient_suggestion']['reasoning'],
      summary: data['summary'],
      insights: List<String>.from(data['insights']),
      recommendations: List<String>.from(data['recommendations']),
    );
  }
  
  /// 从API响应中直接解析情绪数据（用于日记API的emotion_data字段）
  factory EmotionAnalysisResult.fromApiResponse(Map<String, dynamic> data) {
    // 解析情绪数据
    final emotionsJson = data['emotions'] as List;
    final emotions = emotionsJson.map((emotionJson) {
      return EmotionData(
        emotion: emotionJson['emotion'],
        color: _parseColor(emotionJson['color']),
        intensity: (emotionJson['intensity'] as num).toDouble(),
        time: _parseTimeFromPeriod(emotionJson['time_period']),
      );
    }).toList();

    // 解析渐变类型
    final gradientTypeStr = data['gradient_suggestion']['type'] as String;
    final gradientType = _parseGradientType(gradientTypeStr);

    return EmotionAnalysisResult(
      emotions: emotions,
      gradientType: gradientType,
      reasoning: data['gradient_suggestion']['reasoning'],
      summary: data['summary'],
      insights: List<String>.from(data['insights']),
      recommendations: List<String>.from(data['recommendations']),
    );
  }

  static Color _parseColor(String colorStr) {
    // 移除 # 并转换为 Flutter Color
    final hexColor = colorStr.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  static DateTime _parseTimeFromPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case '上午':
        return today.add(const Duration(hours: 9));
      case '中午':
        return today.add(const Duration(hours: 12));
      case '下午':
        return today.add(const Duration(hours: 15));
      case '晚上':
        return today.add(const Duration(hours: 20));
      default:
        return today.add(const Duration(hours: 12));
    }
  }

  static EmotionGradientType _parseGradientType(String typeStr) {
    switch (typeStr) {
      case 'radial':
        return EmotionGradientType.radial;
      case 'sweep':
      case 'timeFlow':
        return EmotionGradientType.timeFlow;
      case 'multiPoint':
      case 'dayCircle':
        return EmotionGradientType.dayCircle;
      case 'diagonal':
      case 'wave':
        return EmotionGradientType.timeFlow; // 暂时映射到timeFlow
      default:
        return EmotionGradientType.radial;
    }
  }
  
  /// 转换为JSON格式（用于序列化）
  Map<String, dynamic> toJson() {
    return {
      'emotions': emotions.map((emotion) => {
        'emotion': emotion.emotion,
        'color': '#${emotion.color.value.toRadixString(16).substring(2).toUpperCase()}',
        'intensity': emotion.intensity,
        'time_period': _formatTimePeriod(emotion.time),
      }).toList(),
      'gradient_suggestion': {
        'type': _formatGradientType(gradientType),
        'reasoning': reasoning,
      },
      'summary': summary,
      'insights': insights,
      'recommendations': recommendations,
    };
  }
  
  static String _formatTimePeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return '上午';
    if (hour >= 12 && hour < 14) return '中午';
    if (hour >= 14 && hour < 18) return '下午';
    return '晚上';
  }
  
  static String _formatGradientType(EmotionGradientType type) {
    switch (type) {
      case EmotionGradientType.radial:
        return 'radial';
      case EmotionGradientType.timeFlow:
        return 'sweep';
      case EmotionGradientType.dayCircle:
        return 'multiPoint';
      default:
        return 'radial';
    }
  }
}

class EmotionService {
  static const String baseUrl = 'http://192.168.31.90:8080/api';
  
  /// 分析日记内容的情绪
  static Future<EmotionAnalysisResult?> analyzeDiary({
    required String diaryContent,
    required String diaryDate,
    required String token,
    Map<String, dynamic>? userContext,
  }) async {
    final url = Uri.parse('$baseUrl/emotion/analyze-diary');
    
    final requestBody = {
      'diary_content': diaryContent,
      'diary_date': diaryDate,
      if (userContext != null) 'user_context': userContext,
    };
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    final startTime = DateTime.now();
    
    // 记录请求日志
    ApiLogger.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: requestBody,
    );

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      // 记录响应日志
      ApiLogger.logResponse(
        method: 'POST',
        url: url.toString(),
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        duration: duration,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return EmotionAnalysisResult.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      // 记录错误日志
      ApiLogger.logError(
        method: 'POST',
        url: url.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 分析一周的情绪趋势
  static Future<Map<String, dynamic>?> analyzeWeeklyTrend({
    required String weekStart,
    required List<Map<String, dynamic>> diaryData,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/emotion/analyze-weekly');
    
    final requestBody = {
      'week_start': weekStart,
      'diary_data': diaryData,
    };
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    final startTime = DateTime.now();
    
    // 记录请求日志
    ApiLogger.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: requestBody,
    );

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );
      
      final duration = DateTime.now().difference(startTime);
      
      // 记录响应日志
      ApiLogger.logResponse(
        method: 'POST',
        url: url.toString(),
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        duration: duration,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      // 记录错误日志
      ApiLogger.logError(
        method: 'POST',
        url: url.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 从用户上下文获取情绪分析所需信息
  static Map<String, dynamic> getUserContext({
    int? age,
    String? gender,
    String? profession,
  }) {
    final context = <String, dynamic>{};
    
    if (age != null && age > 0) context['age'] = age;
    if (gender != null && gender.isNotEmpty) context['gender'] = gender;
    if (profession != null && profession.isNotEmpty) context['profession'] = profession;
    
    return context;
  }

  /// 格式化日期为 API 所需格式
  static String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
}

// 使用示例
class EmotionServiceExample {
  static Future<void> example() async {
    const token = 'your_auth_token_here';
    const diaryContent = '今天上午心情很好，工作很顺利。中午吃饭的时候和同事聊天很开心。下午开会的时候有点紧张，但是最后顺利完成了。晚上回家看到家人很温暖。';
    
    // 1. 获取用户背景信息
    final userContext = EmotionService.getUserContext(
      age: 25,
      gender: '女',
      profession: '软件工程师',
    );
    
    // 2. 分析日记情绪
    final result = await EmotionService.analyzeDiary(
      diaryContent: diaryContent,
      diaryDate: EmotionService.formatDateForApi(DateTime.now()),
      token: token,
      userContext: userContext,
    );
    
    if (result != null) {
      print('分析成功!');
      print('检测到 ${result.emotions.length} 种情绪');
      print('建议渐变类型: ${result.gradientType}');
      print('原因: ${result.reasoning}');
      
      // 3. 使用结果创建渐变背景
      /*
      EmotionGradientBackground(
        emotions: result.emotions,
        gradientType: result.gradientType,
        child: YourWidget(),
      )
      */
    } else {
      print('情绪分析失败');
    }
  }
}