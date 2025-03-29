import 'dart:convert';

/// 채팅 메시지 모델
class ChatMessage {
  /// 메시지 ID
  final String id;
  
  /// 메시지 내용
  final String content;
  
  /// 사용자 메시지 여부
  final bool isUser;
  
  /// 오류 메시지 여부
  final bool isError;
  
  /// 생성 시간
  final DateTime timestamp;
  
  /// 메시지 토큰 길이
  final int? tokenCount;
  
  /// 생성자
  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.isError = false,
    DateTime? timestamp,
    this.tokenCount,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 사용자 메시지 생성
  factory ChatMessage.user(String content, {String? id}) {
    final now = DateTime.now();
    return ChatMessage(
      id: id ?? now.millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: now,
    );
  }
  
  /// AI 메시지 생성
  factory ChatMessage.ai(String content, {String? id, int? tokenCount}) {
    final now = DateTime.now();
    return ChatMessage(
      id: id ?? now.millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      tokenCount: tokenCount,
      timestamp: now,
    );
  }
  
  /// 오류 메시지 생성
  factory ChatMessage.error(String errorMessage, {String? id}) {
    final now = DateTime.now();
    return ChatMessage(
      id: id ?? now.millisecondsSinceEpoch.toString(),
      content: errorMessage,
      isUser: false,
      isError: true,
      timestamp: now,
    );
  }
  
  /// JSON에서 ChatMessage 생성
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : null,
      tokenCount: json['tokenCount'] as int?,
    );
  }
  
  /// JSON 문자열에서 ChatMessage 생성
  factory ChatMessage.fromJsonString(String source) {
    return ChatMessage.fromJson(json.decode(source) as Map<String, dynamic>);
  }
  
  /// ChatMessage를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'isError': isError,
      'timestamp': timestamp.toIso8601String(),
      'tokenCount': tokenCount,
    };
  }
  
  /// ChatMessage를 JSON 문자열로 변환
  String toJsonString() {
    return json.encode(toJson());
  }
  
  /// 복사본 생성
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    bool? isError,
    DateTime? timestamp,
    int? tokenCount,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      isError: isError ?? this.isError,
      timestamp: timestamp ?? this.timestamp,
      tokenCount: tokenCount ?? this.tokenCount,
    );
  }
  
  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, isUser: $isUser, isError: $isError, timestamp: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessage &&
      other.id == id &&
      other.content == content &&
      other.isUser == isUser &&
      other.isError == isError &&
      other.timestamp == timestamp &&
      other.tokenCount == tokenCount;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      content.hashCode ^
      isUser.hashCode ^
      isError.hashCode ^
      timestamp.hashCode ^
      (tokenCount?.hashCode ?? 0);
  }
} 