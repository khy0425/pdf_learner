import '../models/user_model.dart';

/// 사용자 저장소 인터페이스
abstract class UserRepository {
  /// 사용자 정보 조회
  Future<UserModel?> getUser(String userId);

  /// 사용자 생성
  Future<void> createUser(UserModel user);

  /// 사용자 정보 업데이트
  Future<void> updateUser(UserModel user);

  /// 사용자 삭제
  Future<void> deleteUser(String userId);

  /// 사용자 정보 스트림
  Stream<UserModel?> userStream(String userId);

  /// 사용자 검색
  Future<List<UserModel>> searchUsers(String query);

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? photoURL,
    String? bio,
  });

  /// 사용자 설정 업데이트
  Future<void> updateUserSettings(
    String userId, {
    bool? emailNotifications,
    bool? pushNotifications,
    String? language,
    String? theme,
  });

  /// 친구 추가
  Future<void> addUserFriend(String userId, String friendId);

  /// 친구 제거
  Future<void> removeUserFriend(String userId, String friendId);

  /// 친구 목록 조회
  Future<List<UserModel>> getUserFriends(String userId);
} 