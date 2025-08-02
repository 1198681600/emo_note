import 'package:flutter/material.dart';
import 'dart:math' as math;

enum EmotionGradientType {
  radial,     // 辐射渐变 (单色，从中心向外)
  timeFlow,   // 时间流动渐变 (双色，左右时间过渡)
  dayCircle,  // 一日轮回渐变 (多色，圆形时间过渡)
}

class EmotionData {
  final String emotion;
  final Color color;
  final double intensity; // 0.0 - 1.0
  final DateTime time;

  EmotionData({
    required this.emotion,
    required this.color,
    required this.intensity,
    required this.time,
  });
}

class EmotionGradientBackground extends StatefulWidget {
  final Widget child;
  final List<EmotionData> emotions;
  final EmotionGradientType gradientType;
  final Duration animationDuration;

  const EmotionGradientBackground({
    super.key,
    required this.child,
    required this.emotions,
    this.gradientType = EmotionGradientType.radial,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<EmotionGradientBackground> createState() => _EmotionGradientBackgroundState();
}

class _EmotionGradientBackgroundState extends State<EmotionGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final gradient = _createGradient();
        
        // 添加调试信息
        print('渐变类型: ${widget.gradientType}');
        print('情绪数量: ${widget.emotions.length}');
        print('颜色数量: ${_getTimeBasedColors().length}');
        
        return Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
          child: widget.child,
        );
      },
    );
  }

  Gradient _createGradient() {
    switch (widget.gradientType) {
      case EmotionGradientType.radial:
        return _createRadialGradient();
      case EmotionGradientType.timeFlow:
        return _createTimeFlowGradient();
      case EmotionGradientType.dayCircle:
        return _createDayCircleGradient();
    }
  }

  // 获取按时间排序的颜色
  List<Color> _getTimeBasedColors() {
    if (widget.emotions.isEmpty) {
      return [const Color(0xFF6C63FF), const Color(0xFF4F46E5)];
    }

    // 按时间排序情绪（从早到晚）
    final sortedEmotions = List<EmotionData>.from(widget.emotions)
      ..sort((a, b) => a.time.compareTo(b.time));

    List<Color> colors = [];
    for (final emotion in sortedEmotions) {
      // 保持原色，强调时间过渡
      colors.add(emotion.color);
    }

    // 单色情况：添加渐变效果
    if (colors.length == 1) {
      final baseColor = colors[0];
      colors.add(baseColor.withValues(alpha: 0.5));
    }

    return colors;
  }

  // 生成基于时间的渐变stops
  List<double> _generateTimeStops(int colorCount) {
    if (colorCount <= 1) return [0.0, 1.0];
    
    List<double> stops = [];
    for (int i = 0; i < colorCount; i++) {
      stops.add(i / (colorCount - 1));
    }
    return stops;
  }

  // 生成圆形时间stops
  List<double> _generateCircularTimeStops(int colorCount) {
    if (colorCount <= 1) return [0.0, 1.0];
    
    List<double> stops = [];
    for (int i = 0; i <= colorCount; i++) { // +1 for循环
      stops.add(i / colorCount);
    }
    return stops;
  }

  // 单色辐射渐变 - 表现情绪的强度扩散
  RadialGradient _createRadialGradient() {
    if (widget.emotions.isEmpty) {
      return const RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
      );
    }
    
    final emotion = widget.emotions.first;
    final centerColor = emotion.color;
    final edgeColor = emotion.color.withValues(alpha: 0.3);
    
    return RadialGradient(
      center: Alignment.center,
      radius: 0.8 + emotion.intensity * 0.4,
      colors: [centerColor, edgeColor],
      stops: const [0.0, 1.0],
    );
  }

  // 时间流动渐变 - 从左到右表现时间过渡
  LinearGradient _createTimeFlowGradient() {
    final timeBasedColors = _getTimeBasedColors();
    
    return LinearGradient(
      begin: Alignment.centerLeft,  // 左侧代表早晨
      end: Alignment.centerRight,   // 右侧代表晚上
      colors: timeBasedColors,
      stops: _generateTimeStops(timeBasedColors.length),
    );
  }

  // 一日轮回渐变 - 圆形表现一天的情绪轮回
  SweepGradient _createDayCircleGradient() {
    final timeBasedColors = _getTimeBasedColors();
    
    return SweepGradient(
      center: Alignment.center,
      startAngle: -math.pi / 2, // 从顶部开始（代表早晨）
      endAngle: 3 * math.pi / 2, // 顺时针一圈
      colors: timeBasedColors + [timeBasedColors.first], // 循环回到起点
      stops: _generateCircularTimeStops(timeBasedColors.length),
    );
  }

}

// 情绪色彩映射系统
class EmotionColorMapping {
  static const Map<String, Color> _emotionColors = {
    '开心': Color(0xFFFFD700),      // 金黄色
    '快乐': Color(0xFFFF6B6B),      // 珊瑚红
    '兴奋': Color(0xFFFF8E53),      // 橙色
    '平静': Color(0xFF4ECDC4),      // 青绿色
    '放松': Color(0xFF45B7D1),      // 天蓝色
    '满足': Color(0xFF96CEB4),      // 薄荷绿
    '难过': Color(0xFF6C5CE7),      // 紫色
    '沮丧': Color(0xFF74B9FF),      // 蓝色
    '焦虑': Color(0xFFFDCB6E),      // 淡黄色
    '紧张': Color(0xFFE17055),      // 橙红色
    '愤怒': Color(0xFFD63031),      // 红色
    '烦躁': Color(0xFFE84393),      // 粉红色
    '感动': Color(0xFFA29BFE),      // 淡紫色
    '温暖': Color(0xFFFFB8B8),      // 粉色
    '孤独': Color(0xFF636E72),      // 灰色
    '迷茫': Color(0xFFB2BEC3),      // 浅灰色
  };

  static Color getEmotionColor(String emotion) {
    return _emotionColors[emotion] ?? const Color(0xFF6C63FF);
  }

  static List<Color> getEmotionColors(List<String> emotions) {
    return emotions.map((emotion) => getEmotionColor(emotion)).toList();
  }

  static EmotionGradientType suggestGradientType(List<EmotionData> emotions) {
    if (emotions.isEmpty) return EmotionGradientType.radial;
    
    // 根据情绪数量建议渐变类型
    if (emotions.length == 1) {
      return EmotionGradientType.radial;    // 单色辐射渐变，表现情绪强度
    } else if (emotions.length == 2) {
      return EmotionGradientType.timeFlow;  // 双色时间流动，表现情绪变化
    } else {
      return EmotionGradientType.dayCircle; // 多色一日轮回，表现复杂情绪
    }
  }
}