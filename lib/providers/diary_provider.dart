import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../services/api_service.dart';
import '../services/emotion_service.dart';
import '../providers/emotion_provider.dart';
import 'package:provider/provider.dart';

class DiaryProvider with ChangeNotifier {
  List<Diary> _diaries = [];
  bool _isLoading = false;
  String? _error;

  List<Diary> get diaries => _diaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadDiaries({BuildContext? context}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getDiaries();
      if (response.isSuccess && response.data != null) {
        _diaries = response.data!;
        
        // 同步情绪数据到EmotionProvider
        if (context != null) {
          final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
          for (final diary in _diaries) {
            if (diary.hasEmotionData) {
              final diaryDate = _formatDate(diary.date);
              await emotionProvider.saveEmotionResult(diaryDate, diary.emotionData!);
            }
          }
        }
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('加载日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createDiary(String content, {String? date, BuildContext? context}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.createDiary(content, date: date);
      if (response.isSuccess && response.data != null) {
        final diary = response.data!;
        _diaries.insert(0, diary);
        
        // 如果日记有情绪数据，同步到EmotionProvider
        if (diary.hasEmotionData && context != null) {
          final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
          final diaryDate = _formatDate(diary.date);
          await emotionProvider.saveEmotionResult(diaryDate, diary.emotionData!);
        }
        
        notifyListeners();
        return true;
      } else {
        // 处理特定的错误情况
        if (response.message.contains('already exists')) {
          _setError('今天已经写过日记了，请编辑现有日记或选择其他日期');
        } else {
          _setError(response.message);
        }
        return false;
      }
    } catch (e) {
      _setError('创建日记失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Diary?> getDiary(int id) async {
    try {
      Diary? diary = _diaries.firstWhere((d) => d.id == id, orElse: () => throw StateError('Not found'));
      return diary;
    } catch (e) {
      final response = await ApiService.getDiary(id);
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        _setError(response.message);
        return null;
      }
    }
  }

  Future<bool> updateDiary(int id, String content, {BuildContext? context}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.updateDiary(id, content);
      if (response.isSuccess && response.data != null) {
        final diary = response.data!;
        final index = _diaries.indexWhere((d) => d.id == id);
        if (index != -1) {
          _diaries[index] = diary;
          
          // 如果日记有情绪数据，同步到EmotionProvider
          if (diary.hasEmotionData && context != null) {
            final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
            final diaryDate = _formatDate(diary.date);
            await emotionProvider.saveEmotionResult(diaryDate, diary.emotionData!);
          }
          
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('更新日记失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDiary(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.deleteDiary(id);
      if (response.isSuccess) {
        _diaries.removeWhere((d) => d.id == id);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('删除日记失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }

  // 检查今天是否已有日记
  Diary? getTodayDiary() {
    final today = DateTime.now();
    final todayStr = _formatDate(today);
    
    try {
      return _diaries.firstWhere((diary) {
        final diaryDate = diary.date.toLocal();
        final diaryStr = _formatDate(diaryDate);
        return diaryStr == todayStr;
      });
    } catch (e) {
      return null;
    }
  }
  
  /// 格式化日期为字符串
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 获取指定日期的日记
  Diary? getDiaryByDate(DateTime date) {
    final dateStr = _formatDate(date);
    
    try {
      return _diaries.firstWhere((diary) {
        final diaryDate = diary.date.toLocal();
        final diaryStr = _formatDate(diaryDate);
        return diaryStr == dateStr;
      });
    } catch (e) {
      return null;
    }
  }
  
  /// 获取有情绪数据的日记列表
  List<Diary> get diariesWithEmotion {
    return _diaries.where((diary) => diary.hasEmotionData).toList();
  }
}