class User {
  final int id;
  final String email;
  final bool isEmailVerified;
  final String avatar;
  final String nickname;
  final String gender;
  final int age;
  final String profession;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.avatar,
    required this.nickname,
    required this.gender,
    required this.age,
    required this.profession,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      isEmailVerified: json['is_email_verified'] as bool,
      avatar: json['avatar'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      profession: json['profession'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'is_email_verified': isEmailVerified,
      'avatar': avatar,
      'nickname': nickname,
      'gender': gender,
      'age': age,
      'profession': profession,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    bool? isEmailVerified,
    String? avatar,
    String? nickname,
    String? gender,
    int? age,
    String? profession,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      profession: profession ?? this.profession,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (nickname.isNotEmpty) return nickname;
    return email.split('@').first;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, nickname: $nickname, isEmailVerified: $isEmailVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.isEmailVerified == isEmailVerified &&
        other.avatar == avatar &&
        other.nickname == nickname &&
        other.gender == gender &&
        other.age == age &&
        other.profession == profession &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        isEmailVerified.hashCode ^
        avatar.hashCode ^
        nickname.hashCode ^
        gender.hashCode ^
        age.hashCode ^
        profession.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}