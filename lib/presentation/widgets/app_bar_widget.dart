import 'package:flutter/material.dart';
import 'package:pdf_learner_v2/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:pdf_learner_v2/data/models/user_model.dart';
import 'package:pdf_learner_v2/services/auth_service.dart';
import 'package:pdf_learner_v2/presentation/screens/login_page.dart';
import 'package:pdf_learner_v2/presentation/screens/profile/user_profile_page.dart';
import 'package:pdf_learner_v2/presentation/screens/subscription/subscription_page.dart';
import 'package:pdf_learner_v2/core/utils/subscription_badge.dart';

/// UPDF 스타일의 앱바 위젯
class PDFAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PDFAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
        ),
      ),
      backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      foregroundColor: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
      elevation: elevation,
      centerTitle: centerTitle,
      leading: showBackButton && Navigator.canPop(context)
          ? leading ?? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// UPDF 스타일의 검색 앱바
class PDFSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String hintText;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autoFocus;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PDFSearchAppBar({
    Key? key,
    required this.searchController,
    this.hintText = '검색어를 입력하세요',
    this.onBackPressed,
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.autoFocus = true,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      foregroundColor: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded, 
          size: 20,
          color: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: TextField(
        controller: searchController,
        autofocus: autoFocus,
        style: TextStyle(
          color: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : AppTheme.neutral500,
            fontSize: 16,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          isDense: true,
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : AppTheme.neutral500,
                  ),
                  onPressed: () {
                    searchController.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// UPDF 스타일의 햄버거 메뉴 앱바
class PDFMenuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback onMenuPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PDFMenuAppBar({
    Key? key,
    required this.title,
    required this.onMenuPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
        ),
      ),
      backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      foregroundColor: foregroundColor ?? (isDark ? Colors.white : AppTheme.neutral900),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      actions: actions,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 앱 전체에서 재사용 가능한 AppBar 위젯
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLoginButton;
  final bool showProfileButton;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    Key? key,
    this.title = '나의 PDF 학습기',
    this.actions,
    this.showLoginButton = true,
    this.showProfileButton = true,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 1,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final isLoggedIn = authService.isLoggedIn;
        final user = authService.user;
        
        List<Widget> allActions = [];
        
        // 기본 액션 버튼들 추가
        if (actions != null) {
          allActions.addAll(actions!);
        }
        
        // 로그인 사용자의 경우 프로필 버튼 추가
        if (isLoggedIn && showProfileButton && user != null) {
          allActions.add(_buildUserProfileButton(context, user));
        } 
        // 비로그인 사용자의 경우 로그인 버튼 추가
        else if (!isLoggedIn && showLoginButton) {
          allActions.add(_buildLoginButton(context));
        }
        
        return AppBar(
          title: Text(title),
          backgroundColor: backgroundColor ?? colorScheme.surface,
          foregroundColor: foregroundColor ?? colorScheme.onSurface,
          elevation: elevation,
          leading: leading != null ? leading : (onBackPressed != null ? 
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            ) : null),
          actions: allActions,
        );
      },
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// 로그인 버튼 생성
  Widget _buildLoginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('로그인'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
      ),
    );
  }

  /// 사용자 프로필 버튼 생성
  Widget _buildUserProfileButton(BuildContext context, UserModel user) {
    final subscriptionTier = user.subscriptionTier;
    final badge = SubscriptionBadge.getBadgeForTier(subscriptionTier);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 사용자 프로필 버튼
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: user.photoURL != null && user.photoURL!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.photoURL!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    user.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
            tooltip: '프로필',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfilePage()),
              );
            },
          ),
          
          // 구독 배지 (프로필 우측 상단에 표시)
          if (subscriptionTier != 'free')
            Positioned(
              top: 8,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: badge.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: badge.textColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 