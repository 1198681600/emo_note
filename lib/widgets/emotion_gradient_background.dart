import 'package:flutter/material.dart';
import 'dart:math' as math;

enum EmotionGradientType {
  radial,      // 辐射渐变 (单色，从中心向外)
  timeFlow,    // 时间流动渐变 (双色，左右时间过渡)
  multiPoint,  // 多焦点渐变 (三色，三角形布局)
  dayCircle,   // 一日轮回渐变 (多色，圆形时间过渡)
  diagonal,    // 对角线渐变 (情绪对比)
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
    this.animationDuration = const Duration(seconds: 30),
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
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    
    // 循环动画，让渐变更加生动
    _animationController.repeat();
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
      case EmotionGradientType.multiPoint:
        return _createMultiPointGradient();
      case EmotionGradientType.dayCircle:
        return _createDayCircleGradient();
      case EmotionGradientType.diagonal:
        return _createDiagonalGradient();
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

  // 多焦点渐变 - 三角形布局展现三种情绪
  LinearGradient _createMultiPointGradient() {
    final colors = _getTimeBasedColors();
    final animationValue = _animation.value;
    
    if (colors.length >= 3) {
      // 完整360度连续旋转 - 平滑的一整圈旋转
      final angle = animationValue * 2 * math.pi; // 0 到 360度的连续变化
      final beginAlignment = Alignment(
        math.cos(angle) * 0.8, 
        math.sin(angle) * 0.8
      );
      final endAlignment = Alignment(
        -math.cos(angle) * 0.8, 
        -math.sin(angle) * 0.8
      );
      
      // 创建更平滑的三色过渡
      return LinearGradient(
        begin: beginAlignment,
        end: endAlignment,
        colors: [
          colors[0],
          _blendColors(colors[0], colors[1], 0.3),
          _blendColors(colors[0], colors[1], 0.7),
          colors[1],
          _blendColors(colors[1], colors[2], 0.3),
          _blendColors(colors[1], colors[2], 0.7),
          colors[2],
          _blendColors(colors[2], colors[0], 0.5), // 循环回第一种颜色
        ],
        stops: const [0.0, 0.15, 0.25, 0.4, 0.6, 0.75, 0.85, 1.0],
      );
    } else if (colors.length == 2) {
      // 双色渐变也添加旋转效果
      final angle = animationValue * 2 * math.pi;
      final beginAlignment = Alignment(
        math.cos(angle) * 0.9, 
        math.sin(angle) * 0.9
      );
      final endAlignment = Alignment(
        -math.cos(angle) * 0.9, 
        -math.sin(angle) * 0.9
      );
      
      return LinearGradient(
        begin: beginAlignment,
        end: endAlignment,
        colors: colors,
      );
    } else {
      // 单色情况：创建线性渐变而不是径向渐变
      final baseColor = colors.isNotEmpty ? colors[0] : const Color(0xFF6C63FF);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [baseColor, baseColor.withValues(alpha: 0.5)],
      );
    }
  }

  // 对角线渐变 - 强调情绪对比
  LinearGradient _createDiagonalGradient() {
    final colors = _getTimeBasedColors();
    
    // 动态角度：基于动画进度旋转
    final animationValue = _animation.value;
    final angle = animationValue * 2 * math.pi;
    
    return LinearGradient(
      begin: Alignment(math.cos(angle), math.sin(angle)),
      end: Alignment(-math.cos(angle), -math.sin(angle)),
      colors: colors.length >= 2 ? colors : [colors[0], colors[0].withValues(alpha: 0.5)],
      stops: _generateTimeStops(colors.length),
    );
  }

  // 一日轮回渐变 - 圆形表现一天的情绪轮回
  SweepGradient _createDayCircleGradient() {
    final timeBasedColors = _getTimeBasedColors();
    
    // 确保颜色列表不为空
    if (timeBasedColors.isEmpty) {
      return const SweepGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
      );
    }
    
    // 创建平滑的循环颜色序列，避免接缝
    List<Color> circularColors = [];
    List<double> circularStops = [];
    
    // 添加原始颜色
    for (int i = 0; i < timeBasedColors.length; i++) {
      circularColors.add(timeBasedColors[i]);
      circularStops.add(i / timeBasedColors.length);
    }
    
    // 添加第一个颜色到末尾，确保完美循环
    circularColors.add(timeBasedColors.first);
    circularStops.add(1.0);
    
    // 为了更平滑的过渡，在接缝处添加中间色
    if (timeBasedColors.length > 1) {
      final lastColor = timeBasedColors.last;
      final firstColor = timeBasedColors.first;
      final blendedColor = Color.lerp(lastColor, firstColor, 0.5);
      
      // 在接缝处插入混合色
      circularColors.insert(circularColors.length - 1, blendedColor!);
      circularStops.insert(circularStops.length - 1, 0.95);
      
      // 重新计算stops以保持正确的比例
      for (int i = 0; i < circularStops.length - 2; i++) {
        circularStops[i] = i / (circularStops.length - 2) * 0.9;
      }
    }
    
    return SweepGradient(
      center: Alignment.center,
      startAngle: -math.pi / 2, // 从顶部开始（代表早晨）
      endAngle: 3 * math.pi / 2, // 顺时针一圈
      colors: circularColors,
      stops: circularStops,
    );
  }

  // 颜色混合工具函数
  Color _blendColors(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
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
      return EmotionGradientType.radial;     // 单色辐射渐变，表现情绪强度
    } else if (emotions.length == 2) {
      return EmotionGradientType.timeFlow;   // 双色时间流动，表现情绪变化
    } else {
      return EmotionGradientType.multiPoint; // 三色及以上多焦点渐变，更自然的过渡
    }
  }
}