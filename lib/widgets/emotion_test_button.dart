import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../services/emotion_service.dart';
import 'emotion_gradient_background.dart';

class EmotionTestButton extends StatelessWidget {
  const EmotionTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      onPressed: () => _testEmotionAnalysis(context),
      child: const Icon(Icons.psychology),
      tooltip: '测试情绪分析',
    );
  }

  void _testEmotionAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择测试渐变效果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyTestGradient(context, 'single', '单一强烈情绪');
              },
              child: const Text('🌟 单一强烈情绪'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyTestGradient(context, 'morning_night', '早晚情绪变化');
              },
              child: const Text('🌅🌙 早晚情绪变化'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyTestGradient(context, 'full_day', '三色情绪融合');
              },
              child: const Text('🎨 三色情绪融合'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyTestGradient(context, 'circle_test', '圆形渐变测试');
              },
              child: const Text('🌀 圆形渐变测试'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTestGradient(BuildContext context, String type, String description) {
    final emotionProvider = context.read<EmotionProvider>();
    
    List<EmotionData> testEmotions;
    EmotionGradientType gradientType;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (type) {
      case 'single':
        // 单一强烈情绪 - 整天都很开心
        testEmotions = [
          EmotionData(
            emotion: '开心',
            color: EmotionColorMapping.getEmotionColor('开心'),
            intensity: 0.9,
            time: today.add(const Duration(hours: 12)), // 中午时刻
          ),
        ];
        gradientType = EmotionGradientType.radial;
        break;
      case 'morning_night':
        // 早晚情绪变化 - 从早上焦虑到晚上平静
        testEmotions = [
          EmotionData(
            emotion: '焦虑',
            color: EmotionColorMapping.getEmotionColor('焦虑'),
            intensity: 0.8,
            time: today.add(const Duration(hours: 8)), // 早上8点
          ),
          EmotionData(
            emotion: '平静',
            color: EmotionColorMapping.getEmotionColor('平静'),
            intensity: 0.9,
            time: today.add(const Duration(hours: 20)), // 晚上8点
          ),
        ];
        gradientType = EmotionGradientType.timeFlow;
        break;
      case 'full_day':
        // 三色情绪变化 - 早中晚的情绪变化
        testEmotions = [
          EmotionData(
            emotion: '平静',
            color: EmotionColorMapping.getEmotionColor('平静'),
            intensity: 0.7,
            time: today.add(const Duration(hours: 7)), // 早上7点
          ),
          EmotionData(
            emotion: '紧张',
            color: EmotionColorMapping.getEmotionColor('紧张'),
            intensity: 0.8,
            time: today.add(const Duration(hours: 14)), // 下午2点
          ),
          EmotionData(
            emotion: '开心',
            color: EmotionColorMapping.getEmotionColor('开心'),
            intensity: 0.9,
            time: today.add(const Duration(hours: 18)), // 傍晚6点
          ),
        ];
        gradientType = EmotionGradientType.multiPoint;
        break;
      case 'circle_test':
        // 圆形渐变测试 - 四种情绪的循环效果
        testEmotions = [
          EmotionData(
            emotion: '开心',
            color: EmotionColorMapping.getEmotionColor('开心'),
            intensity: 0.8,
            time: today.add(const Duration(hours: 6)), // 早上6点
          ),
          EmotionData(
            emotion: '焦虑',
            color: EmotionColorMapping.getEmotionColor('焦虑'),
            intensity: 0.7,
            time: today.add(const Duration(hours: 12)), // 中午12点
          ),
          EmotionData(
            emotion: '平静',
            color: EmotionColorMapping.getEmotionColor('平静'),
            intensity: 0.9,
            time: today.add(const Duration(hours: 18)), // 傍晚6点
          ),
          EmotionData(
            emotion: '温暖',
            color: EmotionColorMapping.getEmotionColor('温暖'),
            intensity: 0.8,
            time: today.add(const Duration(hours: 22)), // 晚上10点
          ),
        ];
        gradientType = EmotionGradientType.dayCircle;
        break;
      default:
        return;
    }

    final testResult = EmotionAnalysisResult(
      emotions: testEmotions,
      gradientType: gradientType,
      reasoning: '测试：$description',
      summary: {
        'dominant_emotion': '测试',
        'emotional_stability': 7.5,
        'mood_trend': description,
        'energy_level': '高'
      },
      insights: [
        '测试：应用了$description',
        '测试：渐变类型为 ${gradientType.toString().split('.').last}',
        '测试：包含 ${testEmotions.length} 种情绪色彩'
      ],
      recommendations: [
        '测试：现在可以清楚看到渐变效果',
        '测试：尝试不同类型来对比效果',
        '测试：真实日记会产生更贴合的渐变'
      ],
    );

    // 保存测试数据
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    emotionProvider.saveEmotionResult(dateStr, testResult);

    // 显示结果
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ $description 已应用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('渐变类型: ${gradientType.toString().split('.').last}'),
            const SizedBox(height: 8),
            ...testEmotions.map((emotion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: emotion.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${emotion.emotion} (${(emotion.intensity * 100).toInt()}%)'),
                ],
              ),
            )),
            const SizedBox(height: 12),
            const Text('主页背景现在会显示对应的渐变效果！', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}