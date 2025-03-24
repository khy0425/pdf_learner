import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/reward_ad_button.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../services/api_key_service.dart';
import '../widgets/loading_indicator.dart';

/// 설정 화면
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // 화면별 ViewModel 관리
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularLoader(size: 30),
            ),
          );
        }
        
        // SharedPreferences 인스턴스를 가져왔을 때 ViewModel 생성
        final prefs = snapshot.data!;
        
        return ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(prefs),
          child: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('설정'),
                ),
                body: ListView(
                  children: [
                    // 테마 설정
                    _buildThemeSection(context),
                    
                    // 계정 설정
                    _buildAccountSection(context),
                    
                    // API 키 설정
                    _buildApiKeySection(context),
                    
                    // 앱 정보
                    _buildAboutSection(context),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }
  
  /// 테마 섹션
  Widget _buildThemeSection(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return _buildSettingsSection(
      title: '앱 테마',
      icon: Icons.palette,
      children: [
        ListTile(
          title: const Text('다크 모드'),
          subtitle: const Text('어두운 테마 사용'),
          trailing: Switch(
            value: themeService.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeService.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// 계정 섹션
  Widget _buildAccountSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return _buildSettingsSection(
      title: '계정',
      icon: Icons.account_circle,
      children: [
        ListTile(
          title: const Text('로그아웃'),
          subtitle: const Text('계정에서 로그아웃'),
          onTap: () => _confirmLogout(context, authService),
        ),
      ],
    );
  }
  
  /// API 키 섹션
  Widget _buildApiKeySection(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        final apiKeyService = Provider.of<ApiKeyService>(context);
        final hasApiKey = apiKeyService.hasApiKey;
        
        return _buildSettingsSection(
          title: 'API 키 설정',
          icon: Icons.key,
          children: [
            ListTile(
              title: const Text('Google AI API 키'),
              subtitle: Text(
                hasApiKey ? '설정됨' : '설정되지 않음',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showApiKeyDialog(context, apiKeyService),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 앱 정보 섹션
  Widget _buildAboutSection(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        return _buildSettingsSection(
          title: '앱 정보',
          icon: Icons.info_outline,
          children: [
            ListTile(
              title: const Text('버전'),
              subtitle: Text(viewModel.appVersion),
            ),
            ListTile(
              title: const Text('개인정보 처리방침'),
              onTap: () => viewModel.openPrivacyPolicy(),
            ),
            ListTile(
              title: const Text('이용약관'),
              onTap: () => viewModel.openTermsOfService(),
            ),
            ListTile(
              title: const Text('오픈소스 라이선스'),
              onTap: () => _showLicensePage(context),
            ),
          ],
        );
      },
    );
  }
  
  /// 설정 섹션 위젯 빌드
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
  
  /// API 키 입력 다이얼로그
  void _showApiKeyDialog(BuildContext context, ApiKeyService apiKeyService) {
    final controller = TextEditingController(
      text: apiKeyService.getApiKey('google_ai') ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google AI API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API 키를 입력하세요. API 키는 Google 콘솔에서 생성할 수 있습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API 키',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final apiKey = controller.text.trim();
              apiKeyService.setApiKey('google_ai', apiKey);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  /// 로그아웃 확인 다이얼로그
  void _confirmLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              authService.signOut();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
  
  /// 라이선스 페이지 표시
  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'PDF 학습 도구',
      applicationVersion: Provider.of<SettingsViewModel>(
        context,
        listen: false,
      ).appVersion,
      applicationLegalese: '© 2024 PDF Learner Team',
    );
  }
} 