import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'simple_pdf_viewer.dart';
import '../view_models/home_view_model.dart';
import '../widgets/home/empty_state_view.dart';
import '../widgets/home/stats_card.dart';
import '../widgets/home/pdf_list_item.dart';
import '../widgets/common/wave_painter.dart';
import '../main.dart';  // AppLogger 사용을 위한 import
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './simple_pdf_viewer.dart';
import './pdf_viewer_screen.dart'; // PDFViewerScreen 클래스 import 추가
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kDebugMode;
import '../views/auth/gemini_api_tutorial_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late HomeViewModel _viewModel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // 디버그 로그
    AppLogger.log('HomePage 초기화 시작');
    
    // 애니메이션 시작
    _animationController.forward();
    
    // PDF 파일 목록 로드 (지연 시간 제거)
    _checkUserAndLoadPDFs();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Provider 초기화 확인
    if (!_viewModel.isInitialized) {
      _viewModel.isInitialized = true;
      
      AppLogger.log('HomePage 의존성 초기화');
      
      // Provider가 준비되었는지 확인
      try {
        final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
        AppLogger.log('PDFProvider 상태: ${pdfProvider.pdfFiles.length} 파일');
      } catch (e) {
        AppLogger.error('Provider 초기화 오류', e);
        
        setState(() {
          _viewModel.hasError = true;
          _viewModel.errorMessage = 'Provider 초기화 중 오류 발생: $e';
          _viewModel.isLoading = false;
        });
      }
    }
  }

  /// PDF 파일 목록 로드
  Future<void> _loadPDFs() async {
    if (mounted) {
      return _viewModel.loadPDFs(context);
    }
  }

  /// PDF 파일 선택
  void _pickPDF(BuildContext context) {
    _viewModel.pickPDF(context);
  }

  /// PDF 파일 삭제
  void _deletePDF(PdfFileInfo pdfFile) {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
    _viewModel.deletePDF(context, pdfProvider, pdfFile);
  }

  /// PDF 파일 열기
  void _openPdf(PdfFileInfo pdfFile) async {
    try {
      if (kDebugMode) {
        print('[HomePage] PDF 열기 - ${pdfFile.fileName}');
        print('[HomePage] PDF 유형 - isWeb: ${pdfFile.isWeb}, isLocal: ${pdfFile.isLocal}, hasBytes: ${pdfFile.hasBytes}');
      }
      
      // 로딩 표시
      setState(() => _isLoading = true);
      
      // PDF 데이터 미리 로드 시도 (오류 방지)
      if (!pdfFile.hasBytes) {
        try {
          if (kDebugMode) {
            print('[HomePage] PDF 바이트 데이터 미리 로드 시도');
          }
          
          // bytes 데이터 로드 (오류 방지용, PDF 뷰어 화면에서 실제 활용)
          final bytes = await pdfFile.readAsBytes();
          
          // bytes 데이터로 새 PdfFileInfo 객체 생성 (기존 객체는 불변이라 수정 불가)
          final updatedPdfFile = PdfFileInfo(
            id: pdfFile.id,
            fileName: pdfFile.fileName,
            url: pdfFile.url,
            file: pdfFile.file,
            createdAt: pdfFile.createdAt,
            fileSize: pdfFile.fileSize,
            bytes: bytes, // 로드한 bytes 데이터 설정
            userId: pdfFile.userId,
            firestoreId: pdfFile.firestoreId,
          );
          
          if (kDebugMode) {
            print('[HomePage] PDF 바이트 데이터 로드 성공: ${bytes.length} 바이트');
          }
          
          // 현재 선택된 PDF 업데이트
          context.read<PDFProvider>().setCurrentPDF(updatedPdfFile);
          
          // PDF 뷰어 화면으로 이동
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(pdfFile: updatedPdfFile),
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('[HomePage] PDF 바이트 데이터 로드 실패: $e');
          }
          // 오류 발생 시 원래 파일 정보로 계속 진행
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
              ),
            );
          }
        }
      } else {
        // 이미 bytes 데이터가 있는 경우 바로 PDF 뷰어 화면으로 이동
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[HomePage] PDF 열기 실패: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일을 열 수 없습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 사용자 정보 확인 후 필요한 경우에만 PDF 로드
  Future<void> _checkUserAndLoadPDFs() async {
    try {
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 로그인된 사용자가 있는 경우에만 PDF 로드
      if (authService.isLoggedIn) {
        AppLogger.log('로그인된 사용자: ${authService.user?.uid} - PDF 로드 시작');
        await _loadPDFs();
      } else {
        AppLogger.log('로그인되지 않은 사용자: PDF 로드 건너뜀');
      }
    } catch (e) {
      AppLogger.error('사용자 정보 확인 중 오류', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('HomePage 빌드 호출됨');
    
    // 지역화 지원
    final t = AppLocalizations.of(context);
    final title = t?.appTitle ?? 'PDF Learner';
    
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    
    // 스캐폴드 반환
    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C7EF8), // 밝은 파란색
                Color(0xFF2563EB), // 약간 더 진한 파란색
              ],
              stops: [0.0, 0.8],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_stories, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // 로그인 버튼 추가
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildLoginButton(colorScheme),
          ),
          _buildInfoButton(),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _loadPDFs,
            color: colorScheme.primary,
            backgroundColor: Colors.white,
            strokeWidth: 3,
            displacement: 60,
            edgeOffset: 20,
            child: _buildBody(),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fadeAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildFloatingActionButton(colorScheme),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  // 로그인 버튼
  Widget _buildLoginButton(ColorScheme colorScheme) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.user;
        
        // 로그인된 경우 프로필 표시
        if (user != null) {
          debugPrint('로그인된 사용자 UI 표시: ${user.uid}');
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showUserProfile(context),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (user.photoURL != null)
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(user.photoURL!),
                      )
                    else
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          user.displayName.isNotEmpty 
                            ? user.displayName[0].toUpperCase()
                            : user.email[0].toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : user.email.split('@')[0],
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // 로그인되지 않은 경우 로그인 버튼 표시
        debugPrint('로그인되지 않은 사용자 UI 표시');
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            icon: Icon(Icons.login, color: Colors.white, size: 16),
            label: Text(
              '로그인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // 정보 버튼
  Widget _buildInfoButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
        onPressed: () => _showAppInfo(context),
        tooltip: '앱 정보',
      ),
    );
  }
  
  // Floating Action Button
  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _pickPDF(context),
        backgroundColor: Colors.transparent,
        icon: const Icon(Icons.add, color: Colors.white, size: 22),
        label: const Text('PDF 추가', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
          )
        ),
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  /// 앱 정보 모달 표시
  void _showAppInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            _buildInfoIcon(colorScheme),
            const SizedBox(height: 28),
            Text(
              'PDF Learner 정보',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '비로그인 사용자는 최대 3개의 PDF 파일(5MB 이하)을 추가할 수 있습니다. 더 많은 기능을 사용하려면, 로그인하세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeaturesList(colorScheme),
            const SizedBox(height: 40),
            _buildConfirmButton(colorScheme),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
  
  // 정보 아이콘
  Widget _buildInfoIcon(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.3),
                  colorScheme.tertiary.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
        );
      },
    );
  }
  
  // 기능 목록
  Widget _buildFeaturesList(ColorScheme colorScheme) {
    final features = [
      {
        'icon': Icons.upload_file,
        'title': 'PDF 업로드',
        'description': '최대 5MB 크기의 PDF 파일을 업로드할 수 있습니다.',
      },
      {
        'icon': Icons.cloud_done,
        'title': '클라우드 동기화',
        'description': '로그인 시 모든 기기에서 PDF 파일을 동기화합니다.',
      },
      {
        'icon': Icons.bookmark,
        'title': '북마크 기능',
        'description': '중요한 페이지를 북마크하여 빠르게 접근할 수 있습니다.',
      },
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: features.map((feature) => 
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ),
    );
  }
  
  // 확인 버튼
  Widget _buildConfirmButton(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    AppLogger.log('HomePage 본문 빌드: 로딩=${_viewModel.isLoading}, 오류=${_viewModel.hasError}');
    
    final colorScheme = Theme.of(context).colorScheme;
    
    // 디버깅용 래퍼 (릴리즈 모드에서는 표시하지 않음)
    Widget buildDebugWrapper(Widget child) {
      if (!kDebugMode) return child;
      
      return Stack(
        children: [
          child,
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.black.withOpacity(0.7),
              child: Text(
                '로딩: ${_viewModel.isLoading}, 오류: ${_viewModel.hasError}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      );
    }
    
    // 오류 화면
    if (_viewModel.hasError) {
      return buildDebugWrapper(
        _buildErrorView(colorScheme),
      );
    }

    // 로딩 화면
    if (_viewModel.isLoading) {
      return buildDebugWrapper(
        _buildLoadingView(colorScheme),
      );
    }

    // 안전하게 Provider 접근
    try {
      // PDF 목록 표시
      return buildDebugWrapper(
        Consumer<PDFProvider>(
          builder: (context, pdfProvider, child) {
            AppLogger.log('PDFProvider 소비자 빌드: ${pdfProvider.pdfFiles.length} 파일');
            
            if (pdfProvider.pdfFiles.isEmpty) {
              return EmptyStateView(
                onAddPdf: () => _pickPDF(context),
              );
            }
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPdfListView(pdfProvider, colorScheme),
            );
          },
        ),
      );
    } catch (e) {
      AppLogger.error('Consumer 빌드 중 오류', e);
      
      // 오류 발생 시 기본 UI 표시
      return buildDebugWrapper(
        _buildErrorMessageView(e, colorScheme),
      );
    }
  }
  
  // 오류 화면
  Widget _buildErrorView(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildErrorAnimation(colorScheme),
            const SizedBox(height: 24),
            Text(
              'PDF 파일 로드 중 오류 발생',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadPDFs(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 오류 애니메이션
  Widget _buildErrorAnimation(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 50, color: colorScheme.error),
          ),
        );
      }
    );
  }
  
  // 로딩 화면
  Widget _buildLoadingView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
            children: [
          // 로딩 애니메이션
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'PDF 파일을 불러오는 중...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          // 로딩 취소 버튼 추가 (20초 이상 로딩 시)
          StatefulBuilder(
            builder: (context, setState) {
              // 로딩이 오래 걸릴 경우 취소 버튼 표시
              return FutureBuilder(
                future: Future.delayed(const Duration(seconds: 10), () => true),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TextButton.icon(
                      onPressed: () {
                        // 로딩 중단 및 상태 초기화
                        _viewModel.isLoading = false;
                        setState(() {});
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('로딩 취소'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  // PDF 목록 화면
  Widget _buildPdfListView(PDFProvider pdfProvider, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 통계 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StatsCard(pdfProvider: pdfProvider),
          ),
          
          const SizedBox(height: 24),
          
          // 파일 목록 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildFileListHeader(colorScheme),
          ),
          
          const SizedBox(height: 16),
          
          // PDF 목록
          Expanded(
            child: _buildPdfList(pdfProvider),
          ),
        ],
      ),
    );
  }
  
  // 파일 목록 헤더
  Widget _buildFileListHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_outlined,
                color: colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '최근 PDF 파일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ],
        ),
        _buildSortButton(colorScheme),
      ],
    );
  }
  
  // 정렬 버튼
  Widget _buildSortButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () {
          // 정렬 옵션 보여주기 기능
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('정렬 옵션을 준비 중입니다.'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: '확인',
                onPressed: () {},
              ),
            ),
          );
        },
        icon: Icon(
          Icons.sort,
          size: 16,
          color: colorScheme.primary,
        ),
        label: Text(
          '최신순',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  // PDF 목록
  Widget _buildPdfList(PDFProvider pdfProvider) {
    return ListView.builder(
      itemCount: pdfProvider.pdfFiles.length,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100), // FAB 공간 확보
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final pdfFile = pdfProvider.pdfFiles[index];
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = 0.2 + (index * 0.1);
            final animationValue = _animationController.value > delay 
                ? (_animationController.value - delay) / (1 - delay) 
                : 0.0;
            
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animationValue)),
              child: Opacity(
                opacity: animationValue,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PdfListItem(
              pdfFile: pdfFile,
              onOpen: _openPdf,
              onDelete: _deletePDF,
            ),
          ),
        );
      },
    );
  }
  
  // 오류 메시지 화면
  Widget _buildErrorMessageView(dynamic error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '데이터 로드 중 문제가 발생했습니다.',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onBackground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
              Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '오류 내용: $error',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPDFs,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 사용자 프로필 표시
  void _showUserProfile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AuthService>(
          builder: (context, authService, _) {
            final user = authService.user;
            if (user == null) {
              Navigator.of(context).pop();
              return const SizedBox.shrink();
            }
            
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                '사용자 정보',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정보 표시
                  ListTile(
                    leading: user.photoURL != null
                      ? CircleAvatar(backgroundImage: NetworkImage(user.photoURL!))
                      : CircleAvatar(child: Text(user.displayName[0].toUpperCase())),
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                  ),
                  const Divider(),
                  // 구독 정보
                  ListTile(
                    leading: const Icon(Icons.workspace_premium),
                    title: Text('구독 상태: ${user.subscriptionTier}'),
                  ),
                  // API 키 정보
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('API 키'),
                    subtitle: Text(user.apiKey != null ? '설정됨' : '회원님은 API 키를 입력하지 않았습니다.'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // API 키 설정 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GeminiApiTutorialView(
                              onClose: null,
                            ),
                          ),
                        );
                      },
                      child: const Text('API 키 설정'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await authService.signOut();
                  },
                  child: const Text('로그아웃'),
                ),
            ],
          );
        },
        );
      },
    );
  }
} 