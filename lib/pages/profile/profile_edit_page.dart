import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/avatar_upload_service.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  final bool isFirstTime;
  
  const ProfileEditPage({
    super.key,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  
  String _selectedGender = '';
  bool _isLoading = false;
  
  // Avatar handling
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedAvatarFile;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _ageController.text = user.age > 0 ? user.age.toString() : '';
      _professionController.text = user.profession;
      _selectedGender = user.gender;
      _avatarUrl = user.avatar.isNotEmpty ? user.avatar : null;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    super.dispose();
  }
  
  // 选择照片方法
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _selectedAvatarFile = File(pickedFile.path);
        _isUploadingAvatar = true;
      });
      
      // 上传头像
      await _uploadAvatar();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
  
  // 上传头像方法
  Future<void> _uploadAvatar() async {
    if (_selectedAvatarFile == null) return;
    
    try {
      final success = await AvatarUploadService.uploadAvatar(_selectedAvatarFile!);
      
      if (success) {
        // 获取最新的用户资料，包括更新后的头像
        await ref.read(authProvider.notifier).updateProfile(
          nickname: _nicknameController.text.trim(),
          gender: _selectedGender,
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          profession: _professionController.text.trim(),
        );
        
        final user = ref.read(authProvider).user;
        if (user != null && mounted) {
          setState(() {
            _avatarUrl = user.avatar;
            _isUploadingAvatar = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像上传成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('头像上传失败');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 显示头像选择选项
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
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


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        nickname: _nicknameController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        profession: _professionController.text.trim(),
      );

      if (!success) {
        throw Exception(ref.read(authProvider).error ?? '更新失败');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息已保存'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isFirstTime) {
          // 首次完善信息后，导航到主页
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // 编辑信息后，返回上一页
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isFirstTime ? '完善个人信息' : '编辑个人信息'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstTime) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 48,
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '欢迎加入情绪日记！',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '为了给您提供更好的服务体验，请完善您的个人信息',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 头像选择
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedAvatarFile != null 
                          ? FileImage(_selectedAvatarFile!) 
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty 
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null),
                      child: (_selectedAvatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            )
                          : _isUploadingAvatar 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: _isUploadingAvatar ? null : _showImageSourceOptions,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 昵称输入
              _buildInputField(
                label: '昵称',
                controller: _nicknameController,
                icon: Icons.person_outline,
                hintText: '请输入您的昵称',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入昵称';
                  }
                  if (value.trim().length < 2) {
                    return '昵称至少需要2个字符';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 性别选择
              _buildGenderSelector(),

              const SizedBox(height: 20),

              // 年龄输入
              _buildInputField(
                label: '年龄',
                controller: _ageController,
                icon: Icons.cake_outlined,
                hintText: '请输入您的年龄',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入年龄';
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null || age < 1 || age > 120) {
                    return '请输入有效的年龄';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 职业输入
              _buildInputField(
                label: '职业',
                controller: _professionController,
                icon: Icons.work_outline,
                hintText: '请输入您的职业',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入职业';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isFirstTime ? '完成设置' : '保存修改',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              if (!widget.isFirstTime) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = '男'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedGender == '男' 
                          ? const Color(0xFF6C63FF) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          color: _selectedGender == '男' 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '男',
                          style: TextStyle(
                            color: _selectedGender == '男' 
                              ? Colors.white 
                              : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = '女'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedGender == '女' 
                          ? const Color(0xFF6C63FF) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: _selectedGender == '女' 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '女',
                          style: TextStyle(
                            color: _selectedGender == '女' 
                              ? Colors.white 
                              : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedGender.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              '请选择性别',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}