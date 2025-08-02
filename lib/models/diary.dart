class Diary {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int userId;
  final DateTime date;
  final String content;

  Diary({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.userId,
    required this.date,
    required this.content,
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['ID'] is int ? json['ID'] as int : int.parse(json['ID'].toString()),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      deletedAt: json['DeletedAt'] != null ? DateTime.parse(json['DeletedAt'] as String) : null,
      userId: json['UserID'] is int ? json['UserID'] as int : int.parse(json['UserID'].toString()),
      date: DateTime.parse(json['Date'] as String),
      content: json['Content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'DeletedAt': deletedAt?.toIso8601String(),
      'UserID': userId,
      'Date': date.toIso8601String(),
      'Content': content,
    };
  }

  Diary copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? userId,
    DateTime? date,
    String? content,
  }) {
    return Diary(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      content: content ?? this.content,
    );
  }

  @override
  String toString() {
    return 'Diary{id: $id, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, userId: $userId, date: $date, content: $content}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt &&
          userId == other.userId &&
          date == other.date &&
          content == other.content;

  @override
  int get hashCode =>
      id.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode ^
      userId.hashCode ^
      date.hashCode ^
      content.hashCode;
}