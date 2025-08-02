import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/diary_provider.dart';
import '../../providers/emotion_provider.dart';
import '../../widgets/emotion_gradient_background.dart';

class EmotionStatisticsPage extends StatefulWidget {
  const EmotionStatisticsPage({super.key});

  @override
  State<EmotionStatisticsPage> createState() => _EmotionStatisticsPageState();
}

class _EmotionStatisticsPageState extends State<EmotionStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7天';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 首次打开时检查是否需要加载历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadDiaries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<DiaryProvider, EmotionProvider>(
        builder: (context, diaryProvider, emotionProvider, child) {
          final emotions = _getEmotionsForPeriod(diaryProvider, emotionProvider, _selectedPeriod);
          
          return EmotionGradientBackground(
            emotions: emotions.isNotEmpty 
                ? emotions.take(3).toList() 
                : emotionProvider.getDefaultEmotions(),
            gradientType: EmotionGradientType.timeFlow,
            child: SafeArea(
              child: Column(
                children: [
                  // 自定义AppBar
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            '情绪统计',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // 平衡布局
                      ],
                    ),
                  ),
                  
                  // 时间段选择
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildPeriodChip('7天'),
                        const SizedBox(width: 10),
                        _buildPeriodChip('30天'),
                        const SizedBox(width: 10),
                        _buildPeriodChip('全部'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 主要内容区域
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Tab导航
                          Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                              tabs: [
                                Container(
                                  width: double.infinity,
                                  child: const Tab(text: '分布'),
                                ),
                                Container(
                                  width: double.infinity,
                                  child: const Tab(text: '趋势'),
                                ),
                                Container(
                                  width: double.infinity,
                                  child: const Tab(text: 'TOP3'),
                                ),
                              ],
                            ),
                          ),
                          
                          // Tab内容
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEmotionDistribution(diaryProvider, emotionProvider),
                                _buildEmotionTrend(diaryProvider, emotionProvider),
                                _buildTopEmotions(diaryProvider, emotionProvider),
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
          );
        },
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionDistribution(DiaryProvider diaryProvider, EmotionProvider emotionProvider) {
    final emotionStats = _getEmotionStatistics(diaryProvider, emotionProvider);
    
    if (emotionStats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_neutral, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              '暂无情绪数据',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 饼图
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: emotionStats.entries.map((entry) {
                  final color = EmotionColorMapping.getEmotionColor(entry.key);
                  final percentage = (entry.value / emotionStats.values.reduce((a, b) => a + b) * 100);
                  
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: color,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 图例
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: emotionStats.entries.map((entry) {
                final color = EmotionColorMapping.getEmotionColor(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key} (${entry.value}次)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTrend(DiaryProvider diaryProvider, EmotionProvider emotionProvider) {
    final trendData = _getTrendData(diaryProvider, emotionProvider);
    
    if (trendData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              '暂无趋势数据',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '情绪变化趋势',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trendData.length && index % 2 == 0) {
                          return Text(
                            DateFormat('M/d').format(trendData[index]['date']),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['count'].toDouble().clamp(0.0, double.infinity),
                      );
                    }).toList(),
                    isCurved: false,
                    color: Colors.white,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmotions(DiaryProvider diaryProvider, EmotionProvider emotionProvider) {
    final emotionStats = _getEmotionStatistics(diaryProvider, emotionProvider);
    final topEmotions = emotionStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top3 = topEmotions.take(3).toList();
    
    if (top3.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              '暂无排行数据',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最常出现的情绪',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: ListView.builder(
              itemCount: top3.length,
              itemBuilder: (context, index) {
                final emotion = top3[index];
                final color = EmotionColorMapping.getEmotionColor(emotion.key);
                final rank = index + 1;
                final icons = [Icons.emoji_events, Icons.military_tech, Icons.workspace_premium];
                final colors = [Colors.amber, Colors.grey[300]!, Colors.brown];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 排名图标
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icons[index],
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 情绪信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emotion.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '出现 ${emotion.value} 次',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 情绪颜色指示器
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getEmotionStatistics(DiaryProvider diaryProvider, EmotionProvider emotionProvider) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case '7天':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30天':
        startDate = now.subtract(const Duration(days: 30));
        break;
      default:
        startDate = DateTime(2020); // 很早的日期，包含所有数据
    }

    final emotions = <String, int>{};
    
    // 遍历所有日记，获取对应的情绪分析数据
    for (final diary in diaryProvider.diaries) {
      if (diary.date.isAfter(startDate) || diary.date.isAtSameMomentAs(startDate)) {
        // 格式化日期以匹配 EmotionProvider 的键格式
        final dateKey = _formatDate(diary.date);
        final emotionResult = emotionProvider.getEmotionForDate(dateKey);
        
        if (emotionResult != null) {
          // 从情绪分析结果中提取情绪
          for (final emotionData in emotionResult.emotions) {
            final emotion = emotionData.emotion;
            emotions[emotion] = (emotions[emotion] ?? 0) + 1;
          }
        }
      }
    }
    
    return emotions;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<EmotionData> _getEmotionsForPeriod(DiaryProvider diaryProvider, EmotionProvider emotionProvider, String period) {
    final emotionStats = _getEmotionStatistics(diaryProvider, emotionProvider);
    final now = DateTime.now();
    
    return emotionStats.entries.map((entry) {
      return EmotionData(
        emotion: entry.key,
        color: EmotionColorMapping.getEmotionColor(entry.key),
        intensity: (entry.value / 10).clamp(0.3, 1.0),
        time: now,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _getTrendData(DiaryProvider diaryProvider, EmotionProvider emotionProvider) {
    final now = DateTime.now();
    final days = _selectedPeriod == '7天' ? 7 : (_selectedPeriod == '30天' ? 30 : 90);
    final trendData = <Map<String, dynamic>>[];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      
      // 统计当天有情绪分析数据的日记数量
      final emotionResult = emotionProvider.getEmotionForDate(dateKey);
      final count = emotionResult != null ? emotionResult.emotions.length : 0;
      
      trendData.add({
        'date': date,
        'count': count,
      });
    }
    
    return trendData;
  }
  
  Future<void> _checkAndLoadDiaries() async {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    
    // 如果没有日记数据，请求历史记录
    if (diaryProvider.diaries.isEmpty) {
      await diaryProvider.loadDiaries(context: context);
    }
  }
}