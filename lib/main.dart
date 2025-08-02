import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'app.dart';
import 'providers/diary_provider.dart';
import 'providers/emotion_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 创建情绪提供者并加载本地数据
  final emotionProvider = EmotionProvider();
  await emotionProvider.loadFromLocal();
  
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => DiaryProvider()),
          provider.ChangeNotifierProvider.value(value: emotionProvider),
        ],
        child: const MoodDiaryApp(),
      ),
    ),
  );
}