import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/welcome_page.dart';
import 'pages/home/home_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/profile/profile_edit_page.dart';
import 'providers/auth_provider.dart';

class MoodDiaryApp extends ConsumerWidget {
  const MoodDiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '情绪日记',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileEditPage(),
        '/profile/edit': (context) => const ProfileEditPage(isFirstTime: false),
        '/profile/setup': (context) => const ProfileEditPage(isFirstTime: true),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 显示加载状态
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 未认证状态 - 显示欢迎页
    if (!authState.isAuthenticated || authState.user == null) {
      return const WelcomePage();
    }

    // 已认证但用户信息不完整 - 显示信息完善页面
    if (!authState.user!.isProfileComplete) {
      return const ProfileEditPage(isFirstTime: true);
    }

    // 已认证且信息完整 - 显示主页
    return const HomePage();
  }
}