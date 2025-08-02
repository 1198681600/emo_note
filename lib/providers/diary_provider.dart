import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../services/api_service.dart';

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

  Future<void> loadDiaries() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getDiaries();
      if (response.isSuccess && response.data != null) {
        _diaries = response.data!;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('加载日记失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createDiary(String content, {String? date}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.createDiary(content, date: date);
      if (response.isSuccess && response.data != null) {
        _diaries.insert(0, response.data!);
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

  Future<bool> updateDiary(int id, String content) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.updateDiary(id, content);
      if (response.isSuccess && response.data != null) {
        final index = _diaries.indexWhere((d) => d.id == id);
        if (index != -1) {
          _diaries[index] = response.data!;
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
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      return _diaries.firstWhere((diary) {
        final diaryDate = diary.date.toLocal();
        final diaryStr = '${diaryDate.year}-${diaryDate.month.toString().padLeft(2, '0')}-${diaryDate.day.toString().padLeft(2, '0')}';
        return diaryStr == todayStr;
      });
    } catch (e) {
      return null;
    }
  }
}