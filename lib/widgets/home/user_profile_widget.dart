import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../view_models/home_view_model.dart';

/// 사용자 프로필 위젯
/// 로그인 상태에 따라 프로필 또는 로그인 버튼을 표시합니다.
class UserProfileWidget extends StatelessWidget {
  final User user;
  final HomeViewModel homeViewModel;

  const UserProfileWidget({
    super.key,
    required this.user,
    required this.homeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 헤더
            Row(
              children: [
                // 사용자 아바타
                _buildUserAvatar(),
                
                const SizedBox(width: 16),
                
                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeViewModel.getUserDisplayName(user),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email != null) 
                        Text(
                          user.email!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // 프로필 편집 버튼
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  tooltip: '프로필 편집',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // 사용자 통계 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.description,
                  label: 'PDF',
                  value: '0',
                ),
                _buildStatItem(
                  icon: Icons.quiz,
                  label: '퀴즈',
                  value: '0',
                ),
                _buildStatItem(
                  icon: Icons.bookmark,
                  label: '북마크',
                  value: '0',
                ),
                _buildStatItem(
                  icon: Icons.event_note,
                  label: '노트',
                  value: '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.primaryColor,
      child: user.photoURL != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                user.photoURL!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    homeViewModel.getUserInitial(user),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            )
          : Text(
              homeViewModel.getUserInitial(user),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 