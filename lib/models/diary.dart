import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/emotion_service.dart';

class Diary {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int userId;
  final DateTime date;
  final String content;
  final String? emotionAnalysis; // JSON字符串形式的原始情绪分析数据
  final EmotionAnalysisResult? emotionData; // 解析后的情绪数据

  Diary({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.userId,
    required this.date,
    required this.content,
    this.emotionAnalysis,
    this.emotionData,
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    // 解析原始情绪分析数据
    final emotionAnalysisRaw = json['EmotionAnalysis'] as String?;
    EmotionAnalysisResult? emotionData;
    
    // 如果有emotion_data字段（新API格式），优先使用
    if (json['emotion_data'] != null) {
      try {
        emotionData = EmotionAnalysisResult.fromApiResponse(json['emotion_data']);
      } catch (e) {
        debugPrint('解析emotion_data失败: $e');
      }
    }
    // 否则尝试解析EmotionAnalysis字段
    else if (emotionAnalysisRaw != null && emotionAnalysisRaw.isNotEmpty) {
      try {
        final emotionJson = jsonDecode(emotionAnalysisRaw);
        emotionData = EmotionAnalysisResult.fromApiResponse(emotionJson);
      } catch (e) {
        debugPrint('解析EmotionAnalysis失败: $e');
      }
    }
    
    return Diary(
      id: json['ID'] is int ? json['ID'] as int : int.parse(json['ID'].toString()),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      deletedAt: json['DeletedAt'] != null ? DateTime.parse(json['DeletedAt'] as String) : null,
      userId: json['UserID'] is int ? json['UserID'] as int : int.parse(json['UserID'].toString()),
      date: DateTime.parse(json['Date'] as String),
      content: json['Content'] as String,
      emotionAnalysis: emotionAnalysisRaw,
      emotionData: emotionData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'DeletedAt': deletedAt?.toIso8601String(),
      'UserID': userId,
      'Date': date.toIso8601String(),
      'Content': content,
      if (emotionAnalysis != null) 'EmotionAnalysis': emotionAnalysis,
      if (emotionData != null) 'emotion_data': emotionData!.toJson(),
    };
  }

  Diary copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? userId,
    DateTime? date,
    String? content,
    String? emotionAnalysis,
    EmotionAnalysisResult? emotionData,
  }) {
    return Diary(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      content: content ?? this.content,
      emotionAnalysis: emotionAnalysis ?? this.emotionAnalysis,
      emotionData: emotionData ?? this.emotionData,
    );
  }

  @override
  String toString() {
    return 'Diary{id: $id, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, userId: $userId, date: $date, content: $content, hasEmotionData: ${emotionData != null}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt &&
          userId == other.userId &&
          date == other.date &&
          content == other.content &&
          emotionAnalysis == other.emotionAnalysis;

  @override
  int get hashCode =>
      id.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      content.hashCode ^
      emotionAnalysis.hashCode;
      
  /// 检查是否有情绪数据
  bool get hasEmotionData => emotionData != null;
  
  /// 获取情绪数据的简化描述
  String get emotionSummary {
    if (emotionData == null) return '暂无情绪分析';
    final emotions = emotionData!.emotions.map((e) => e.emotion).join('、');
    return '主要情绪：$emotions';
  }
}