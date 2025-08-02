import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/emotion_gradient_background.dart';
import '../services/emotion_service.dart';

class EmotionProvider with ChangeNotifier {
  Map<String, EmotionAnalysisResult> _emotionCache = {};
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  /// 获取指定日期的情绪数据
  EmotionAnalysisResult? getEmotionForDate(String date) {
    return _emotionCache[date];
  }
  
  /// 获取今天的情绪数据
  EmotionAnalysisResult? getTodayEmotion() {
    // 使用与保存时相同的日期计算方式
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = _formatDate(todayDate);
    
    print('获取今日情绪数据:');
    print('- 今日日期: $today');
    print('- 缓存中的键: ${_emotionCache.keys.toList()}');
    
    final result = getEmotionForDate(today);
    print('- 查询结果: ${result != null ? '找到数据' : '未找到数据'}');
    
    return result;
  }
  
  /// 保存情绪分析结果
  Future<void> saveEmotionResult(String date, EmotionAnalysisResult result) async {
    print('保存情绪分析结果:');
    print('- 日期: $date');
    print('- 情绪数量: ${result.emotions.length}');
    print('- 渐变类型: ${result.gradientType}');
    
    _emotionCache[date] = result;
    print('缓存已更新，当前缓存大小: ${_emotionCache.length}');
    
    notifyListeners();
    print('已通知监听者更新');
    
    // 保存到本地存储
    await _saveToLocal();
    print('已保存到本地存储');
  }
  
  /// 从本地存储加载情绪数据
  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotionDataStr = prefs.getString('emotion_cache');
      
      if (emotionDataStr != null) {
        final emotionData = json.decode(emotionDataStr) as Map<String, dynamic>;
        
        _emotionCache = emotionData.map((key, value) {
          return MapEntry(key, _parseEmotionResult(value));
        });
        
        notifyListeners();
      }
    } catch (e) {
      print('加载本地情绪数据失败: $e');
    }
  }
  
  /// 保存到本地存储
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final emotionData = _emotionCache.map((key, value) {
        return MapEntry(key, _serializeEmotionResult(value));
      });
      
      await prefs.setString('emotion_cache', json.encode(emotionData));
    } catch (e) {
      print('保存情绪数据到本地失败: $e');
    }
  }
  
  /// 序列化情绪分析结果
  Map<String, dynamic> _serializeEmotionResult(EmotionAnalysisResult result) {
    return {
      'emotions': result.emotions.map((emotion) => {
        'emotion': emotion.emotion,
        'color': emotion.color.value,
        'intensity': emotion.intensity,
        'time': emotion.time.millisecondsSinceEpoch,
      }).toList(),
      'gradientType': result.gradientType.toString(),
      'reasoning': result.reasoning,
      'summary': result.summary,
      'insights': result.insights,
      'recommendations': result.recommendations,
    };
  }
  
  /// 反序列化情绪分析结果
  EmotionAnalysisResult _parseEmotionResult(Map<String, dynamic> data) {
    final emotionsData = data['emotions'] as List;
    final emotions = emotionsData.map((emotionData) {
      return EmotionData(
        emotion: emotionData['emotion'],
        color: Color(emotionData['color']),
        intensity: (emotionData['intensity'] as num).toDouble(),
        time: DateTime.fromMillisecondsSinceEpoch(emotionData['time']),
      );
    }).toList();
    
    final gradientTypeStr = data['gradientType'] as String;
    final gradientType = _parseGradientType(gradientTypeStr);
    
    return EmotionAnalysisResult(
      emotions: emotions,
      gradientType: gradientType,
      reasoning: data['reasoning'],
      summary: Map<String, dynamic>.from(data['summary']),
      insights: List<String>.from(data['insights']),
      recommendations: List<String>.from(data['recommendations']),
    );
  }
  
  EmotionGradientType _parseGradientType(String typeStr) {
    switch (typeStr) {
      case 'EmotionGradientType.radial':
        return EmotionGradientType.radial;
      case 'EmotionGradientType.timeFlow':
        return EmotionGradientType.timeFlow;
      case 'EmotionGradientType.dayCircle':
        return EmotionGradientType.dayCircle;
      default:
        return EmotionGradientType.radial;
    }
  }
  
  /// 清理过期的情绪数据（保留30天）
  Future<void> cleanOldData() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final cutoffDateStr = _formatDate(cutoffDate);
    
    _emotionCache.removeWhere((date, _) => date.compareTo(cutoffDateStr) < 0);
    await _saveToLocal();
    notifyListeners();
  }
  
  /// 获取一周的情绪数据
  List<EmotionAnalysisResult> getWeeklyEmotions() {
    final today = DateTime.now();
    final weeklyResults = <EmotionAnalysisResult>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      final emotion = getEmotionForDate(dateStr);
      
      if (emotion != null) {
        weeklyResults.add(emotion);
      }
    }
    
    return weeklyResults;
  }
  
  /// 获取默认的示例情绪数据（当没有真实数据时使用）
  List<EmotionData> getDefaultEmotions() {
    final now = DateTime.now();
    return [
      EmotionData(
        emotion: '平静',
        color: EmotionColorMapping.getEmotionColor('平静'),
        intensity: 0.6,
        time: now.subtract(const Duration(hours: 8)),
      ),
      EmotionData(
        emotion: '满足',
        color: EmotionColorMapping.getEmotionColor('满足'),
        intensity: 0.7,
        time: now.subtract(const Duration(hours: 4)),
      ),
      EmotionData(
        emotion: '温暖',
        color: EmotionColorMapping.getEmotionColor('温暖'),
        intensity: 0.8,
        time: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
  
  /// 格式化日期为字符串
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}