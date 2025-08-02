# MoodTrace 后端 API 文档

## 基本信息

- **服务地址**: http://localhost:8080
- **API 前缀**: `/api`
- **认证方式**: Bearer Token (请求头: `Authorization: Bearer <token>`)

## 响应格式

所有 API 响应都采用统一格式：

```json
{
    "code": 200,
    "message": "操作成功",
    "data": {}
}
```

## 认证相关 API

### 1. 发送邮箱验证码

**接口地址**: `POST /api/auth/send-code`

**请求参数**:
```json
{
    "email": "user@example.com"
}
```

**响应示例**:
```json
{
    "code": 200,
    "message": "验证码已发送"
}
```

**说明**: 验证码固定为 `111111`，有效期15分钟

---

### 2. 用户注册

**接口地址**: `POST /api/auth/register`

**请求参数**:
```json
{
    "email": "user@example.com",
    "code": "111111"
}
```

**参数说明**:
- `email`: 邮箱地址，必须是有效邮箱格式
- `code`: 邮箱验证码

**响应示例**:
```json
{
    "code": 200,
    "message": "注册成功"
}
```

---

### 3. 验证邮箱

**接口地址**: `POST /api/auth/verify-email`

**请求参数**:
```json
{
    "email": "user@example.com",
    "code": "111111"
}
```

**响应示例**:
```json
{
    "code": 200,
    "message": "邮箱验证成功"
}
```

---

### 4. 用户登录

**接口地址**: `POST /api/auth/login`

**请求参数**:
```json
{
    "email": "user@example.com",
    "code": "111111"
}
```

**参数说明**:
- `email`: 邮箱地址
- `code`: 邮箱验证码

**响应示例**:
```json
{
    "code": 200,
    "message": "登录成功",
    "data": {
        "token": "a1b2c3d4e5f6...",
        "user": {
            "id": 1,
            "email": "user@example.com",
            "is_email_verified": true,
            "avatar": "",
            "nickname": "",
            "gender": "",
            "age": 0,
            "profession": "",
            "created_at": "2025-01-01T12:00:00Z",
            "updated_at": "2025-01-01T12:00:00Z"
        }
    }
}
```

**说明**: 
- 使用邮箱验证码登录，无需密码
- Token 有效期24小时
- 请将 token 保存并在后续请求中使用

---

## 需要认证的 API

以下接口需要在请求头中携带 `Authorization: Bearer <token>`

### 5. 获取用户信息

**接口地址**: `GET /api/profile`

**请求头**:
```
Authorization: Bearer <your_token>
```

**响应示例**:
```json
{
    "code": 200,
    "message": "获取用户信息成功",
    "data": {
        "id": 1,
        "email": "user@example.com",
        "is_email_verified": true,
        "avatar": "",
        "nickname": "",
        "gender": "",
        "age": 0,
        "profession": "",
        "created_at": "2025-01-01T12:00:00Z",
        "updated_at": "2025-01-01T12:00:00Z"
    }
}
```

---

### 6. 退出登录

**接口地址**: `POST /api/logout`

**请求头**:
```
Authorization: Bearer <your_token>
```

**响应示例**:
```json
{
    "code": 200,
    "message": "退出登录成功"
}
```

**说明**: 退出登录后 token 将失效

---

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权/token无效 |
| 500 | 服务器内部错误 |

## 常见错误响应

### 参数错误
```json
{
    "code": 400,
    "message": "请求参数错误"
}
```

### 用户已存在
```json
{
    "code": 400,
    "message": "用户已存在"
}
```

### 验证码错误
```json
{
    "code": 400,
    "message": "验证码无效或已过期"
}
```

### 用户不存在
```json
{
    "code": 400,
    "message": "用户不存在"
}
```

### 邮箱未验证
```json
{
    "code": 400,
    "message": "请先验证邮箱"
}
```


### Token无效
```json
{
    "code": 401,
    "message": "token无效或已过期"
}
```

## 使用流程示例

### 完整注册登录流程

#### 注册流程
1. **发送验证码**
   ```bash
   curl -X POST http://localhost:8080/api/auth/send-code \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}'
   ```

2. **用户注册**（使用验证码）
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","code":"111111"}'
   ```

#### 登录流程
1. **发送验证码**
   ```bash
   curl -X POST http://localhost:8080/api/auth/send-code \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}'
   ```

2. **用户登录**（使用验证码）
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","code":"111111"}'
   ```

5. **获取用户信息**
   ```bash
   curl -X GET http://localhost:8080/api/profile \
     -H "Authorization: Bearer your_token_here"
   ```

6. **退出登录**
   ```bash
   curl -X POST http://localhost:8080/api/logout \
     -H "Authorization: Bearer your_token_here"
   ```

## 数据库表结构

### Users 表
- `id`: 用户ID (主键)
- `email`: 邮箱地址 (唯一索引)
- `is_email_verified`: 邮箱是否已验证
- `avatar`: 头像URL
- `nickname`: 昵称
- `gender`: 性别
- `age`: 年龄
- `profession`: 职业
- `created_at`: 创建时间
- `updated_at`: 更新时间

### Email Verifications 表
- `id`: 记录ID (主键)
- `email`: 邮箱地址
- `verification_code`: 验证码
- `is_used`: 是否已使用
- `expires_at`: 过期时间
- `created_at`: 创建时间

### User Sessions 表
- `id`: 会话ID (主键)
- `user_id`: 用户ID (外键)
- `token`: 会话token
- `expires_at`: 过期时间
- `created_at`: 创建时间