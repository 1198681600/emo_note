import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'app.dart';
import 'providers/diary_provider.dart';

void main() {
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ],
        child: const MoodDiaryApp(),
      ),
    ),
  );
}