import 'dart:convert';

/// 사용자 모델 클래스
class UserModel {
  /// 사용자 고유 ID
  final String id;
  
  /// 사용자 이메일
  final String email;
  
  /// 사용자 이름
  final String displayName;
  
  /// 사용자 프로필 이미지 URL
  final String photoURL;
  
  /// 생성일시
  final DateTime? createdAt;
  
  /// 사용자 설정
  final UserSettings settings;
  
  /// 프리미엄 사용자 여부
  final bool isPremium;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoURL,
    this.createdAt,
    required this.settings,
    this.isPremium = false,
  });

  /// JSON에서 UserModel 객체 생성
  factory UserModel.fromJson(String source) => 
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// UserModel 객체를 JSON으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt?.toIso8601String(),
      'settings': settings.toMap(),
      'isPremium': isPremium,
    };
  }

  String toJson() => json.encode(toMap());

  /// 게스트 모드 유저 생성
  factory UserModel.guest() {
    return UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@example.com',
      displayName: '게스트',
      photoURL: '',
      createdAt: DateTime.now(),
      settings: UserSettings.createDefault(),
      isPremium: false,
    );
  }

  /// 새로운 UserModel 생성
  factory UserModel.createDefault() {
    return UserModel(
      id: '',
      email: '',
      displayName: '사용자',
      photoURL: '',
      createdAt: DateTime.now(),
      settings: UserSettings.createDefault(),
      isPremium: false,
    );
  }
  
  /// 복사본 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    UserSettings? settings,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoURL == photoURL &&
      other.createdAt == createdAt &&
      other.settings == settings &&
      other.isPremium == isPremium;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoURL.hashCode ^
      createdAt.hashCode ^
      settings.hashCode ^
      isPremium.hashCode;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoURL: map['photoURL'] as String,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      settings: map['settings'] != null 
          ? UserSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : UserSettings.createDefault(),
      isPremium: map['isPremium'] as bool? ?? false,
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
  factory UserSettings.fromJson(String source) => 
      UserSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  /// UserSettings 객체를 JSON으로 변환
  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  String toJson() => json.encode(toMap());

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

  @override
  String toString() => 
      'UserSettings(theme: $theme, language: $language, notificationsEnabled: $notificationsEnabled)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserSettings &&
      other.theme == theme &&
      other.language == language &&
      other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode => 
      theme.hashCode ^ language.hashCode ^ notificationsEnabled.hashCode;

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return UserSettings.createDefault();
    }
    
    return UserSettings(
      theme: map['theme'] as String? ?? 'light',
      language: map['language'] as String? ?? 'ko',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }
} 