import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/auth_provider.dart';
import '../../providers/diary_provider.dart';
import '../diary/diary_list_page.dart';
import '../diary/diary_edit_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _launchUpdate() async {
    final Uri url = Uri.parse('https://www.pgyer.com/mood_diary');
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authState.user!;

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
          child: Column(
            children: [
              // 顶部用户信息栏
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: user.avatar.isNotEmpty 
                        ? NetworkImage(user.avatar) 
                        : null,
                      child: user.avatar.isEmpty 
                        ? Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.white.withOpacity(0.8),
                          )
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '你好，${user.displayName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'profile':
                            _showProfile(context);
                            break;
                          case 'update':
                            await _launchUpdate();
                            break;
                          case 'logout':
                            await ref.read(authProvider.notifier).logout();
                            break;
                        }
                      },
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 20),
                              SizedBox(width: 12),
                              Text('个人设置'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(Icons.system_update_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('检查更新'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('退出登录'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 主要内容区域
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 可滚动的主要内容
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 30),
                              
                              // 标题
                              const Text(
                                '情绪日记',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '记录每一天的心情变化',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // 功能按钮区域
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30),
                                child: Column(
                                  children: [
                                    // 主要功能按钮
                                    _buildMainButton(
                                      context,
                                      icon: Icons.edit_note,
                                      title: '记录心情',
                                      subtitle: '写下今天的情绪和感受',
                                      color: const Color(0xFF6C63FF),
                                      onTap: () {
                                        _handleRecordMood(context);
                                      },
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // 次要功能按钮网格
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFeatureCard(
                                            icon: Icons.timeline,
                                            title: '情绪分析',
                                            color: Colors.orange,
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('功能开发中...')),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: _buildFeatureCard(
                                            icon: Icons.calendar_today,
                                            title: '历史记录',
                                            color: Colors.green,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const DiaryListPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 15),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFeatureCard(
                                            icon: Icons.psychology,
                                            title: '情绪建议',
                                            color: Colors.purple,
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('功能开发中...')),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: _buildFeatureCard(
                                            icon: Icons.share,
                                            title: '分享',
                                            color: Colors.teal,
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('功能开发中...')),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 100,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.75),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          elevation: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 处理记录心情按钮点击
  void _handleRecordMood(BuildContext context) async {
    final diaryProvider = provider.Provider.of<DiaryProvider>(context, listen: false);
    
    // 确保日记列表已加载
    if (diaryProvider.diaries.isEmpty && !diaryProvider.isLoading) {
      await diaryProvider.loadDiaries();
    }
    
    // 检查今天是否已有日记
    final todayDiary = diaryProvider.getTodayDiary();
    
    if (!context.mounted) return;
    
    if (todayDiary != null) {
      // 今天已有日记，打开编辑模式
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditPage(diary: todayDiary),
        ),
      );
    } else {
      // 今天没有日记，创建新日记
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DiaryEditPage(),
        ),
      );
    }
  }
}