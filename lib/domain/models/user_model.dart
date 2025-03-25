import 'dart:convert';

/// 사용자 모델 클래스
class UserModel {
  /// 사용자 고유 ID
  final String id;
  
  /// 사용자 이메일
  final String email;
  
  /// 사용자 이름
  final String? displayName;
  
  /// 사용자 프로필 이미지 URL
  final String? photoURL;
  
  /// 생성일시
  final DateTime createdAt;
  
  /// 수정일시
  final DateTime? updatedAt;
  
  /// 마지막 로그인 시간
  final DateTime? lastLoginAt;
  
  /// 사용자 설정
  final UserSettings settings;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    required this.settings,
  });

  /// JSON에서 UserModel 객체 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String) 
          : null,
      settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  /// UserModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'settings': settings.toJson(),
    };
  }

  /// 새로운 UserModel 생성
  factory UserModel.createDefault() {
    return UserModel(
      id: '',
      email: '',
      createdAt: DateTime.now(),
      settings: UserSettings.createDefault(),
    );
  }
  
  /// 복사본 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserSettings? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      settings: settings ?? this.settings,
    );
  }
}

/// 사용자 설정 클래스
class UserSettings {
  /// 테마 설정
  final String theme;
  
  /// 언어 설정
  final String language;
  
  /// 알림 활성화 여부
  final bool notificationsEnabled;

  const UserSettings({
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
  });

  /// JSON에서 UserSettings 객체 생성
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] as String,
      language: json['language'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
    );
  }

  /// UserSettings 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  /// 기본 설정 생성
  factory UserSettings.createDefault() {
    return const UserSettings(
      theme: 'light',
      language: 'ko',
      notificationsEnabled: true,
    );
  }
  
  /// 복사본 생성
  UserSettings copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
} 