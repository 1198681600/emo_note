import 'dart:convert';
import 'package:http/http.dart' as http;

// 今日运势数据模型
class FortuneCategory {
  final int score;
  final String title;
  final String description;
  final String color;
  final String icon;

  FortuneCategory({
    required this.score,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  factory FortuneCategory.fromJson(Map<String, dynamic> json) {
    return FortuneCategory(
      score: json['score'],
      title: json['title'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
    );
  }
}

class LuckyElements {
  final String color;
  final List<int> numbers;
  final String direction;
  final String time;

  LuckyElements({
    required this.color,
    required this.numbers,
    required this.direction,
    required this.time,
  });

  factory LuckyElements.fromJson(Map<String, dynamic> json) {
    return LuckyElements(
      color: json['color'],
      numbers: List<int>.from(json['number']),
      direction: json['direction'],
      time: json['time'],
    );
  }
}

class TodayFortuneResult {
  final String date;
  final int overallScore;
  final String fortuneSummary;
  final Map<String, FortuneCategory> categories;
  final LuckyElements luckyElements;
  final List<String> suggestions;
  final List<String> warnings;

  TodayFortuneResult({
    required this.date,
    required this.overallScore,
    required this.fortuneSummary,
    required this.categories,
    required this.luckyElements,
    required this.suggestions,
    required this.warnings,
  });

  factory TodayFortuneResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    
    // 解析分类运势
    final categoriesJson = data['categories'] as Map<String, dynamic>;
    final categories = <String, FortuneCategory>{};
    categoriesJson.forEach((key, value) {
      categories[key] = FortuneCategory.fromJson(value);
    });

    return TodayFortuneResult(
      date: data['date'],
      overallScore: data['overall_score'],
      fortuneSummary: data['fortune_summary'],
      categories: categories,
      luckyElements: LuckyElements.fromJson(data['lucky_elements']),
      suggestions: List<String>.from(data['suggestions']),
      warnings: List<String>.from(data['warnings']),
    );
  }
}

class FortuneService {
  static const String baseUrl = 'http://192.168.31.90:8080/api';
  
  /// 获取今日运势
  static Future<TodayFortuneResult?> getTodayFortune({
    required String date,
    required String token,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/fortune/daily');
      
      final requestBody = {
        'date': date,
        if (userContext != null) 'user_context': userContext,
      };

      print('发送今日运势请求到: $url');
      print('请求体: ${json.encode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('响应状态码: ${response.statusCode}');
      print('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return TodayFortuneResult.fromJson(responseData);
      } else {
        print('今日运势获取失败: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('今日运势请求异常: $e');
      return null;
    }
  }

  /// 格式化日期为 API 所需格式
  static String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// 从用户信息生成运势上下文
  static Map<String, dynamic> getUserFortuneContext({
    String? birthDate,
    String? zodiacSign,
    String? birthYear,
    String? gender,
  }) {
    final context = <String, dynamic>{};
    
    if (birthDate != null && birthDate.isNotEmpty) context['birth_date'] = birthDate;
    if (zodiacSign != null && zodiacSign.isNotEmpty) context['zodiac_sign'] = zodiacSign;
    if (birthYear != null && birthYear.isNotEmpty) context['birth_year'] = birthYear;
    if (gender != null && gender.isNotEmpty) context['gender'] = gender;
    
    return context;
  }

  /// 生成测试用的今日运势数据
  static TodayFortuneResult generateTestFortune(String date) {
    return TodayFortuneResult(
      date: date,
      overallScore: 85,
      fortuneSummary: '今天是充满机遇的一天，保持积极心态会带来意想不到的收获！',
      categories: {
        'love': FortuneCategory(
          score: 80,
          title: '爱情运势',
          description: '感情生活和谐，单身者有机会遇到心仪对象',
          color: '#FF6B6B',
          icon: 'heart',
        ),
        'career': FortuneCategory(
          score: 90,
          title: '事业运势',
          description: '工作效率极高，适合推进重要项目',
          color: '#4ECDC4',
          icon: 'briefcase',
        ),
        'wealth': FortuneCategory(
          score: 70,
          title: '财运',
          description: '理财谨慎，避免冲动消费',
          color: '#FFD700',
          icon: 'dollar',
        ),
        'health': FortuneCategory(
          score: 85,
          title: '健康运势',
          description: '精力充沛，适合运动健身',
          color: '#96CEB4',
          icon: 'heart_plus',
        ),
      },
      luckyElements: LuckyElements(
        color: '#4ECDC4',
        numbers: [3, 7, 15],
        direction: '东南方',
        time: '下午2-4点',
      ),
      suggestions: [
        '今天适合主动出击，把握机会',
        '多与他人沟通交流，会有意外收获',
        '保持乐观心态，好运自然来',
      ],
      warnings: [
        '避免在决策时过于冲动',
        '注意与同事的沟通方式',
      ],
    );
  }
}

// 使用示例
class FortuneServiceExample {
  static Future<void> example() async {
    const token = 'your_auth_token_here';
    
    // 1. 获取用户运势背景信息
    final userContext = FortuneService.getUserFortuneContext(
      birthDate: '1998-05-20',
      zodiacSign: '金牛座',
      birthYear: '1998',
      gender: '女',
    );
    
    // 2. 获取今日运势
    final result = await FortuneService.getTodayFortune(
      date: FortuneService.formatDateForApi(DateTime.now()),
      token: token,
      userContext: userContext,
    );
    
    if (result != null) {
      print('运势获取成功!');
      print('综合评分: ${result.overallScore}');
      print('运势总结: ${result.fortuneSummary}');
      print('爱情运势: ${result.categories['love']?.score}分');
      print('幸运颜色: ${result.luckyElements.color}');
      print('建议: ${result.suggestions.join(', ')}');
    } else {
      print('运势获取失败，使用默认数据');
      final testResult = FortuneService.generateTestFortune(
        FortuneService.formatDateForApi(DateTime.now())
      );
      print('测试数据综合评分: ${testResult.overallScore}');
    }
  }
}