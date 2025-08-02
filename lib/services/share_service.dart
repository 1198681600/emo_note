import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as path;
import '../models/diary.dart';
import '../widgets/diary_share_card.dart';
import '../widgets/emotion_gradient_background.dart';

class ShareService {
  static Future<void> shareDiaryAsImage({
    required BuildContext context,
    required Diary diary,
    required String emotion,
  }) async {
    try {
      debugPrint('开始生成分享图片...');
      
      // 显示生成进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在生成分享图片...'),
            ],
          ),
        ),
      );

      final image = await _generateSimpleImage(diary, emotion);
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (image != null) {
        final file = await _saveImageToTempFile(image);
        debugPrint('图片保存成功: ${file.path}');
        
        // 自动保存到相册
        try {
          final result = await ImageGallerySaver.saveImage(
            image,
            quality: 100,
            name: 'diary_${DateTime.now().millisecondsSinceEpoch}',
          );
          debugPrint('保存到相册结果: $result');
        } catch (e) {
          debugPrint('保存到相册失败: $e');
        }
        
        // 拉起系统分享面板
        try {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: '来自情绪日记的心情记录',
          );
        } catch (e) {
          debugPrint('系统分享失败: $e');
          // 如果系统分享失败，显示提示
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('图片已保存到相册 📸'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片生成失败')),
          );
        }
      }
    } catch (e) {
      debugPrint('分享失败: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  static Future<void> shareDiaryAsText({
    required Diary diary,
    required String emotion,
  }) async {
    try {
      final text = _generateDiaryText(diary: diary, emotion: emotion);
      await Clipboard.setData(ClipboardData(text: text));
      debugPrint('文本已复制到剪贴板');
    } catch (e) {
      debugPrint('分享失败: $e');
    }
  }

  static Future<Uint8List?> _generateSimpleImage(Diary diary, String emotion) async {
    try {
      // 创建一个简单的画布图片
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(350, 500);
      
      // 获取情绪颜色
      final emotionColor = EmotionColorMapping.getEmotionColor(emotion);
      
      // 绘制渐变背景
      final gradient = ui.Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.6,
        [
          emotionColor,
          emotionColor.withOpacity(0.3),
        ],
        [0.0, 1.0],
      );
      
      final paint = Paint()..shader = gradient;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      
      // 绘制圆角矩形背景
      final roundedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
        const Radius.circular(20),
      );
      final bgPaint = Paint()..color = Colors.white.withOpacity(0.15);
      canvas.drawRRect(roundedRect, bgPaint);
      
      // 根据情绪颜色亮度决定文字颜色
      final isLightBackground = emotionColor.computeLuminance() > 0.5;
      final textColor = isLightBackground ? Colors.black87 : Colors.white;
      final subtleTextColor = isLightBackground ? Colors.black54 : Colors.white.withOpacity(0.9);
      
      // 准备文本样式
      final titleStyle = ui.TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );
      final dateStyle = ui.TextStyle(
        color: subtleTextColor,
        fontSize: 16,
      );
      final contentStyle = ui.TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.4,
      );
      
      // 绘制日期
      final dateText = '${diary.date.year}年${diary.date.month}月${diary.date.day}日';
      final dateParagraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(dateStyle)
        ..addText(dateText))
          .build();
      dateParagraph.layout(ui.ParagraphConstraints(width: size.width - 80));
      canvas.drawParagraph(dateParagraph, const Offset(40, 60));
      
      // 绘制心情标题
      final emotionTitle = '今日心情：$emotion';
      final titleParagraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(titleStyle)
        ..addText(emotionTitle))
          .build();
      titleParagraph.layout(ui.ParagraphConstraints(width: size.width - 80));
      canvas.drawParagraph(titleParagraph, const Offset(40, 100));
      
      // 绘制日记内容
      final truncatedContent = diary.content.length > 200 
          ? '${diary.content.substring(0, 200)}...' 
          : diary.content;
      
      final contentParagraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
      ))
        ..pushStyle(contentStyle)
        ..addText(truncatedContent))
          .build();
      contentParagraph.layout(ui.ParagraphConstraints(width: size.width - 100));
      canvas.drawParagraph(contentParagraph, const Offset(50, 160));
      
      // 绘制应用标识
      final appStyle = ui.TextStyle(
        color: subtleTextColor,
        fontSize: 12,
      );
      final appParagraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(appStyle)
        ..addText('来自情绪日记'))
          .build();
      appParagraph.layout(ui.ParagraphConstraints(width: size.width - 80));
      canvas.drawParagraph(appParagraph, Offset(40, size.height - 60));
      
      // 生成图片
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('图片生成失败: $e');
      return null;
    }
  }

  static Future<File> _saveImageToTempFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'diary_share_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path.join(tempDir.path, fileName));
    await file.writeAsBytes(imageBytes);
    return file;
  }

  static String _generateDiaryText({
    required Diary diary,
    required String emotion,
  }) {
    final dateStr = '${diary.date.year}年${diary.date.month}月${diary.date.day}日';
    return '''
📝 我的心情日记

📅 日期：$dateStr
💭 心情：$emotion

${diary.content}

---
来自情绪日记 App
    ''';
  }

  static Future<void> saveImageToGallery({
    required BuildContext context,
    required Diary diary,
    required String emotion,
  }) async {
    try {
      // 显示生成进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在生成图片...'),
            ],
          ),
        ),
      );

      final image = await _generateSimpleImage(diary, emotion);
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (image != null) {
        try {
          final result = await ImageGallerySaver.saveImage(
            image,
            quality: 100,
            name: 'diary_${DateTime.now().millisecondsSinceEpoch}',
          );
          debugPrint('保存到相册结果: $result');
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('图片已保存到相册 📸'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (saveError) {
          debugPrint('保存到相册失败: $saveError');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存失败: $saveError')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片生成失败')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }
}