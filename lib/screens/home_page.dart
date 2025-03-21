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
import '../services/api_key_service.dart';
import '../models/pdf_file_info.dart';
import '../widgets/home/user_profile_widget.dart';
import '../widgets/home/api_key_status_widget.dart';
import '../widgets/home/pdf_list_widget.dart';
import '../view_models/auth_view_model.dart';

/// 홈 화면 위젯
/// MVVM 패턴에서 View 역할을 담당합니다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // 애니메이션 시작
    _animationController.forward();
    
    // 화면 초기화 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// 초기화 및 데이터 로드
  Future<void> _initializeAndLoadData() async {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    
    // API 키 상태 확인
    await viewModel.checkApiKeyStatus(context);
    
    // PDF 파일 목록 로드
    await viewModel.loadPDFs(context);
    
    // 첫 로드 완료
    viewModel.isInitialized = true;
  }
  
  /// 새로고침 처리
  Future<void> _handleRefresh() async {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    await viewModel.loadPDFs(context);
    return;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 앱바
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PDF 학습도우미',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    // 버전 정보 표시
                    const SizedBox(width: 8),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 물결 배경
                    CustomPaint(
                      painter: WavePainter(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        waveAmplitude: 15.0,
                        frequency: 0.25,
                        phase: 0,
                      ),
                    ),
                    CustomPaint(
                      painter: WavePainter(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                        waveAmplitude: 20.0,
                        frequency: 0.2,
                        phase: math.pi,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // 사용자 프로필 위젯
                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    if (!authViewModel.isLoggedIn) {
                      return TextButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('로그인'),
                        onPressed: () => Navigator.pushNamed(context, '/auth'),
                      );
                    }
                    
                    return Consumer<HomeViewModel>(
                      builder: (context, viewModel, child) {
                        return UserProfileWidget(
                          user: authViewModel.currentUser!,
                          homeViewModel: viewModel,
                        );
                      }
                    );
                  }
                ),
                const SizedBox(width: 12),
              ],
            ),
            
            // API 키 상태 카드
            SliverToBoxAdapter(
              child: Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  return Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return ApiKeyStatusWidget(
                        isCheckingApiKey: viewModel.isCheckingApiKey,
                        hasValidApiKey: viewModel.hasValidApiKey,
                        isPremiumUser: viewModel.isPremiumUser,
                        maskedApiKey: viewModel.maskedApiKey,
                      );
                    }
                  );
                }
              ),
            ),
            
            // PDF 목록 또는 빈 상태 화면
            Consumer<HomeViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                return Consumer<PDFProvider>(
                  builder: (context, pdfProvider, child) {
                    if (pdfProvider.pdfFiles.isEmpty) {
                      return SliverFillRemaining(
                        child: Consumer<AuthViewModel>(
                          builder: (context, authViewModel, child) {
                            return EmptyStateView(
                              isLoggedIn: authViewModel.isLoggedIn,
                              onUploadPressed: () => viewModel.pickPDF(context),
                            );
                          }
                        ),
                      );
                    }
                    
                    return SliverToBoxAdapter(
                      child: PdfListWidget(
                        pdfFiles: pdfProvider.pdfFiles,
                        onDelete: (pdfFile) => viewModel.deletePDF(
                          context, 
                          pdfProvider, 
                          pdfFile
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<PDFProvider>(
        builder: (context, pdfProvider, child) {
          // PDF가 없을 때는 표시하지 않음 (EmptyStateView에서 별도 버튼 제공)
          if (pdfProvider.pdfFiles.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: FloatingActionButton(
              onPressed: () => Provider.of<HomeViewModel>(context, listen: false).pickPDF(context),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
} 