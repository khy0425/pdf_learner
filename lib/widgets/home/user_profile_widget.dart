import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

/// 사용자 프로필 위젯
/// 로그인 상태에 따라 프로필 또는 로그인 버튼을 표시합니다.
class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({Key? key}) : super(key: key);

  // 사용자 초성(이니셜) 가져오기
  String _getUserInitials(UserModel? user) {
    if (user == null || (user.displayName.isEmpty && (user.email.isEmpty))) {
      return '?';
    }
    
    if (user.displayName.isNotEmpty) {
      final nameParts = user.displayName.split(' ');
      if (nameParts.length > 1) {
        // 이름이 여러 단어로 구성된 경우 첫 글자만 사용
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
        // 이름이 한 단어인 경우 첫 두 글자 사용
        return nameParts[0].length > 1 
            ? nameParts[0].substring(0, 2).toUpperCase()
            : nameParts[0][0].toUpperCase();
      }
    }
    
    // 이름이 없는 경우 이메일 첫 글자 사용
    return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
  }

  // 사용자 표시 이름 가져오기
  String _getUserDisplayName(UserModel? user) {
    if (user == null) return '게스트';
    
    if (user.displayName.isNotEmpty) {
      return user.displayName;
    } else if (user.email.isNotEmpty) {
      // 이메일에서 @ 앞부분 사용
      return user.email.split('@')[0];
    } else {
      return '게스트';
    }
  }

  // 사용자 아바타 위젯 생성
  Widget _buildUserAvatar(UserModel? user) {
    if (user != null && user.photoURL != null && user.photoURL!.isNotEmpty) {
      // 프로필 이미지가 있는 경우
      return CircleAvatar(
        backgroundImage: NetworkImage(user.photoURL!),
        radius: 20,
      );
    } else {
      // 프로필 이미지가 없는 경우 이니셜 사용
      return CircleAvatar(
        backgroundColor: Colors.blue.shade700,
        radius: 20,
        child: Text(
          _getUserInitials(user),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  // 사용자 프로필 다이얼로그 표시
  void _showUserProfileDialog(BuildContext context, UserModel? user, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 프로필'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserAvatar(user),
            const SizedBox(height: 16),
            Text(
              _getUserDisplayName(user),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user?.email != null && user!.email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (authService.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  authService.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('로그아웃'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('로그인'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final UserModel? user = authService.user;
    
    return GestureDetector(
      onTap: () => _showUserProfileDialog(context, user, authService),
      child: Row(
        children: [
          _buildUserAvatar(user),
          const SizedBox(width: 8),
          Text(
            authService.isLoggedIn 
                ? '환영합니다, ${_getUserDisplayName(user)}님' 
                : '로그인하세요',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 