import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _launchUpdate() async {
    final Uri url = Uri.parse('https://www.pgyer.com/mood_diary');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }

  void _showRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return _buildAuthenticatedView(context, ref, authState);
    }

    return _buildUnauthenticatedView(context);
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF4F46E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/app.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '情绪日记',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '记录你的心情点滴',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton.icon(
                  onPressed: () => _showLogin(context),
                  icon: const Icon(Icons.login),
                  label: const Text('登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showRegister(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('注册'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: _launchUpdate,
                  icon: Icon(
                    Icons.system_update,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  label: Text(
                    '检查更新',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(BuildContext context, WidgetRef ref, AuthState authState) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF4F46E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/app.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '情绪日记',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '欢迎回来，${authState.user?.displayName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 导航到主功能页面
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('开始记录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: _launchUpdate,
                  icon: Icon(
                    Icons.system_update,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  label: Text(
                    '检查更新',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}