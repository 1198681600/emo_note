import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/auth_provider.dart';
import '../../providers/diary_provider.dart';
import '../../providers/emotion_provider.dart';
import '../diary/diary_list_page.dart';
import '../diary/diary_edit_page.dart';
import '../../widgets/emotion_gradient_background.dart';
import '../../widgets/emotion_test_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  // 获取今日情绪数据（示例）
  List<EmotionData> _getTodayEmotions() {
    final now = DateTime.now();
    return [
      EmotionData(
        emotion: '开心',
        color: EmotionColorMapping.getEmotionColor('开心'),
        intensity: 0.8,
        time: now.subtract(const Duration(hours: 8)),
      ),
      EmotionData(
        emotion: '难过',
        color: EmotionColorMapping.getEmotionColor('难过'),
        intensity: 0.6,
        time: now.subtract(const Duration(hours: 4)),
      ),
      EmotionData(
        emotion: '感动',
        color: EmotionColorMapping.getEmotionColor('感动'),
        intensity: 0.9,
        time: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // 获取不同情绪场景的示例数据
  static List<EmotionData> getEmotionScenario(String scenario) {
    final now = DateTime.now();
    
    switch (scenario) {
      case '单一强烈情绪':
        return [
          EmotionData(
            emotion: '兴奋',
            color: EmotionColorMapping.getEmotionColor('兴奋'),
            intensity: 1.0,
            time: now,
          ),
        ];
      case '情绪冲突':
        return [
          EmotionData(
            emotion: '开心',
            color: EmotionColorMapping.getEmotionColor('开心'),
            intensity: 0.7,
            time: now.subtract(const Duration(hours: 2)),
          ),
          EmotionData(
            emotion: '焦虑',
            color: EmotionColorMapping.getEmotionColor('焦虑'),
            intensity: 0.8,
            time: now,
          ),
        ];
      case '复杂情绪':
        return [
          EmotionData(
            emotion: '平静',
            color: EmotionColorMapping.getEmotionColor('平静'),
            intensity: 0.5,
            time: now.subtract(const Duration(hours: 6)),
          ),
          EmotionData(
            emotion: '兴奋',
            color: EmotionColorMapping.getEmotionColor('兴奋'),
            intensity: 0.9,
            time: now.subtract(const Duration(hours: 3)),
          ),
          EmotionData(
            emotion: '满足',
            color: EmotionColorMapping.getEmotionColor('满足'),
            intensity: 0.7,
            time: now.subtract(const Duration(hours: 1)),
          ),
          EmotionData(
            emotion: '温暖',
            color: EmotionColorMapping.getEmotionColor('温暖'),
            intensity: 0.8,
            time: now,
          ),
        ];
      default:
        return [
          EmotionData(
            emotion: '开心',
            color: EmotionColorMapping.getEmotionColor('开心'),
            intensity: 0.8,
            time: now.subtract(const Duration(hours: 8)),
          ),
          EmotionData(
            emotion: '难过',
            color: EmotionColorMapping.getEmotionColor('难过'),
            intensity: 0.6,
            time: now.subtract(const Duration(hours: 4)),
          ),
          EmotionData(
            emotion: '感动',
            color: EmotionColorMapping.getEmotionColor('感动'),
            intensity: 0.9,
            time: now.subtract(const Duration(hours: 1)),
          ),
        ];
    }
  }

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

    // 使用真实的情绪数据或默认数据
    final emotionProvider = provider.Provider.of<EmotionProvider>(context);
    final todayEmotion = emotionProvider.getTodayEmotion();
    
    // 添加调试信息
    print('=== 主页面构建 ===');
    print('主页面刷新 - 今日情绪数据: ${todayEmotion != null ? '有数据' : '无数据'}');
    if (todayEmotion != null) {
      print('- 情绪数量: ${todayEmotion.emotions.length}');
      print('- 渐变类型: ${todayEmotion.gradientType}');
      print('- 情绪详情: ${todayEmotion.emotions.map((e) => e.emotion).join(', ')}');
    }
    print('=== 主页面构建结束 ===');
    
    List<EmotionData> emotions;
    EmotionGradientType gradientType;
    
    if (todayEmotion != null) {
      // 使用真实的情绪分析数据
      emotions = todayEmotion.emotions;
      gradientType = todayEmotion.gradientType;
      print('使用真实情绪数据');
    } else {
      // 使用默认示例数据
      emotions = emotionProvider.getDefaultEmotions();
      gradientType = EmotionColorMapping.suggestGradientType(emotions);
      print('使用默认情绪数据');
    }
    
    return Scaffold(
      body: EmotionGradientBackground(
        emotions: emotions,
        gradientType: gradientType,
        animationDuration: const Duration(seconds: 4),
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
                    color: Colors.white.withOpacity(0.1), // 进一步降低透明度
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
      floatingActionButton: const EmotionTestButton(),
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