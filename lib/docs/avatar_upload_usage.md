# 头像上传功能使用指南

本文档介绍如何在应用中实现和使用头像上传功能。

## 功能实现概述

头像上传功能基于以下流程：

1. 客户端向服务器请求预签名上传URL
2. 服务器生成临时上传URL和最终访问URL，返回给客户端
3. 客户端使用预签名URL直接上传图片到云存储
4. 上传成功后，客户端使用返回的文件URL更新用户头像

## 使用方法

### 1. 依赖添加

确保在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  image_picker: ^1.0.7
  http: ^1.2.0
```

然后运行 `flutter pub get` 安装依赖。

### 2. 权限配置

#### Android (在 android/app/src/main/AndroidManifest.xml 文件中添加)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

#### iOS (在 ios/Runner/Info.plist 文件中添加)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>我们需要访问您的相册来选择头像</string>
<key>NSCameraUsageDescription</key>
<string>我们需要使用您的相机来拍摄头像</string>
```

### 3. 使用头像上传组件

在您的个人资料页面中，只需添加 `AvatarUploadWidget` 组件：

```dart
import '../widgets/avatar_upload_widget.dart';

// 在你的页面中
AvatarUploadWidget(
  currentAvatarUrl: userAvatarUrl,  // 可选，当前头像URL
  onAvatarUploaded: (newUrl) {
    // 处理上传成功后的回调
    setState(() {
      userAvatarUrl = newUrl;
    });
  },
),
```

### 4. 完整使用示例

参考 `lib/screens/profile_screen_example.dart` 文件，其中包含了完整的个人资料页面示例，展示了如何集成头像上传功能。

## API服务说明

### 1. 获取上传URL

```dart
// 获取预签名上传URL
final uploadData = await ApiService.generateUploadUrl('image/jpeg');
if (uploadData != null && uploadData.isSuccess && uploadData.data != null) {
  final uploadUrl = uploadData.data!['upload_url'] as String;
  final fileUrl = uploadData.data!['file_url'] as String;
  // 使用这些URL进行上传
}
```

### 2. 上传图片

```dart
// 使用http库直接上传到预签名URL
final response = await http.put(
  Uri.parse(uploadUrl),
  headers: {'Content-Type': 'image/jpeg'},
  body: imageBytes,
);

// 检查上传是否成功
if (response.statusCode >= 200 && response.statusCode < 300) {
  // 上传成功，使用fileUrl更新用户头像
}
```

### 3. 更新用户头像

```dart
// 更新用户资料中的头像URL
await ApiService.updateProfile(
  // 其他资料字段...
  avatar: fileUrl,
);
```

## 完整流程封装

使用 `AvatarUploadService` 可以简化整个上传流程：

```dart
import '../services/avatar_upload_service.dart';

// 直接上传图片文件
final file = File('path/to/image.jpg');
final success = await AvatarUploadService.uploadAvatar(file);

if (success) {
  // 上传成功，用户资料已更新
}
```

## 故障排除

### 常见问题与解决方案

1. **上传失败**
   - 检查网络连接
   - 确认API服务器是否正常运行
   - 验证token是否有效
   - 检查上传文件类型是否被支持

2. **上传成功但图片无法显示**
   - 确认上传的图片格式是否正确
   - 检查文件URL是否能够访问
   - 验证图片大小是否合适

3. **上传超时**
   - 可能是图片过大，尝试压缩图片
   - 检查网络连接速度

## 后续改进计划

1. 添加图片裁剪功能
2. 实现上传进度显示
3. 支持更多文件类型
4. 添加图片大小限制和自动压缩