import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/avatar_upload_service.dart';
import '../services/api_service.dart';

class AvatarUploadWidget extends StatefulWidget {
  final String? currentAvatarUrl;
  final Function(String)? onAvatarUploaded;

  const AvatarUploadWidget({
    Key? key,
    this.currentAvatarUrl,
    this.onAvatarUploaded,
  }) : super(key: key);

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  File? _selectedImage;
  bool _isUploading = false;

  // 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // 自动上传
        _uploadAvatar();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  // 上传头像
  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final success = await AvatarUploadService.uploadAvatar(_selectedImage!);

      if (success) {
        // 获取最新用户信息以获取更新后的头像URL
        final profileResponse = await ApiService.getProfile();
        if (profileResponse.isSuccess && 
            profileResponse.data != null && 
            profileResponse.data!['avatar'] != null) {
          final avatarUrl = profileResponse.data!['avatar'] as String;
          
          if (widget.onAvatarUploaded != null) {
            widget.onAvatarUploaded!(avatarUrl);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像上传成功')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像上传失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像上传出错: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 头像预览
        GestureDetector(
          onTap: _showImageSourceOptions,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildAvatarContent(),
          ),
        ),
        const SizedBox(height: 16),
        // 更换头像按钮
        TextButton.icon(
          onPressed: _isUploading ? null : _showImageSourceOptions,
          icon: const Icon(Icons.photo_camera),
          label: const Text('更换头像'),
        ),
      ],
    );
  }

  // 构建头像内容
  Widget _buildAvatarContent() {
    if (_isUploading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.currentAvatarUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, size: 60);
          },
        ),
      );
    } else {
      return const Icon(Icons.person, size: 60);
    }
  }

  // 显示图片来源选择弹窗
  void _showImageSourceOptions() {
    if (_isUploading) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}