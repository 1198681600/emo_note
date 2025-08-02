import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/avatar_upload_widget.dart';

class ProfileScreenExample extends StatefulWidget {
  const ProfileScreenExample({Key? key}) : super(key: key);

  @override
  State<ProfileScreenExample> createState() => _ProfileScreenExampleState();
}

class _ProfileScreenExampleState extends State<ProfileScreenExample> {
  String? _avatarUrl;
  bool _isLoading = true;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  String _gender = '';
  int _age = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  // 加载用户资料
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getProfile();
      if (response.isSuccess && response.data != null) {
        final userData = response.data!;
        setState(() {
          _avatarUrl = userData['avatar'];
          _nicknameController.text = userData['nickname'] ?? '';
          _gender = userData['gender'] ?? '';
          _age = userData['age'] ?? 0;
          _professionController.text = userData['profession'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取用户信息失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 更新用户资料
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.updateProfile(
        nickname: _nicknameController.text,
        gender: _gender,
        age: _age,
        profession: _professionController.text,
        avatar: _avatarUrl,
      );

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新资料成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新资料出错: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 头像上传成功回调
  void _onAvatarUploaded(String newAvatarUrl) {
    setState(() {
      _avatarUrl = newAvatarUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 头像上传组件
                  AvatarUploadWidget(
                    currentAvatarUrl: _avatarUrl,
                    onAvatarUploaded: _onAvatarUploaded,
                  ),
                  const SizedBox(height: 24),
                  
                  // 用户资料表单
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 性别选择
                  DropdownButtonFormField<String>(
                    value: _gender.isEmpty ? null : _gender,
                    decoration: const InputDecoration(
                      labelText: '性别',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '男', child: Text('男')),
                      DropdownMenuItem(value: '女', child: Text('女')),
                      DropdownMenuItem(value: '其他', child: Text('其他')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _gender = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 年龄选择
                  Row(
                    children: [
                      const Text('年龄: '),
                      Expanded(
                        child: Slider(
                          value: _age.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _age.toString(),
                          onChanged: (value) {
                            setState(() {
                              _age = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(_age.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 职业
                  TextFormField(
                    controller: _professionController,
                    decoration: const InputDecoration(
                      labelText: '职业',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 保存按钮
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('保存资料'),
                  ),
                ],
              ),
            ),
    );
  }
}

// 使用示例
// 在您的应用程序中，可以这样导航到个人资料页面：
/*
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const ProfileScreenExample(),
  ),
);
*/