import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AvatarUploadService {
  /// 获取上传URL
  /// 
  /// 根据文件类型请求预签名上传URL
  /// [fileType] 文件MIME类型，如 'image/jpeg', 'image/png', 'image/webp'
  static Future<Map<String, String>?> getUploadUrl(String fileType) async {
    final response = await ApiService.generateUploadUrl(fileType);
    
    if (response.isSuccess && response.data != null) {
      return {
        'uploadUrl': response.data!['upload_url'] as String,
        'fileUrl': response.data!['file_url'] as String,
      };
    }
    return null;
  }

  /// 上传头像文件
  /// 
  /// 上传图片文件到预签名URL
  /// [file] 要上传的文件
  /// [uploadUrl] 预签名上传URL
  static Future<bool> uploadFile(File file, String uploadUrl) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadBytes(bytes, uploadUrl, _getMimeType(file.path));
    } catch (e) {
      debugPrint('上传文件失败: $e');
      return false;
    }
  }

  /// 上传头像字节数据
  /// 
  /// 上传图片字节到预签名URL
  /// [bytes] 要上传的字节数据
  /// [uploadUrl] 预签名上传URL
  /// [contentType] 文件MIME类型
  static Future<bool> uploadBytes(Uint8List bytes, String uploadUrl, String contentType) async {
    try {
      final response = await ApiService.httpClient.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('上传数据失败: $e');
      return false;
    }
  }

  /// 更新用户头像
  /// 
  /// 在上传文件成功后，更新用户资料中的头像URL
  /// [fileUrl] 上传后的文件URL
  static Future<bool> updateUserAvatar(String fileUrl) async {
    try {
      // 获取当前用户信息
      final profileResponse = await ApiService.getProfile();
      if (!profileResponse.isSuccess || profileResponse.data == null) {
        return false;
      }
      
      final userData = profileResponse.data!;
      
      // 更新用户头像
      final updateResponse = await ApiService.updateProfile(
        nickname: userData['nickname'] ?? '',
        gender: userData['gender'] ?? '',
        age: userData['age'] ?? 0,
        profession: userData['profession'] ?? '',
        avatar: fileUrl,
      );
      
      return updateResponse.isSuccess;
    } catch (e) {
      debugPrint('更新用户头像失败: $e');
      return false;
    }
  }

  /// 完整的头像上传流程
  /// 
  /// 将整个上传流程整合到一个方法中
  /// [file] 要上传的头像文件
  static Future<bool> uploadAvatar(File file) async {
    try {
      final fileType = _getMimeType(file.path);
      
      // 获取上传URL
      final uploadData = await getUploadUrl(fileType);
      if (uploadData == null) {
        return false;
      }
      
      // 上传文件
      final uploadSuccess = await uploadFile(file, uploadData['uploadUrl']!);
      if (!uploadSuccess) {
        return false;
      }
      
      // 更新用户头像URL
      return await updateUserAvatar(uploadData['fileUrl']!);
    } catch (e) {
      debugPrint('头像上传流程失败: $e');
      return false;
    }
  }

  /// 获取文件的MIME类型
  /// 
  /// 根据文件扩展名判断MIME类型
  /// [filePath] 文件路径
  static String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // 默认类型
    }
  }
}