import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;
import '../view_models/auth_view_model.dart';
import '../view_models/pdf_file_view_model.dart';
import '../view_models/home_view_model.dart';
import '../models/pdf_file_info.dart';
import '../widgets/home/empty_state_view.dart';
import '../widgets/home/user_profile_widget.dart';
import '../widgets/home/api_key_status_widget.dart';
import '../widgets/home/pdf_list_item.dart';
import '../widgets/common/wave_painter.dart';
import 'pdf_viewer_screen.dart';
import 'auth_screen.dart';
import '../providers/pdf_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home/pdf_list_widget.dart';
import '../widgets/home/user_profile_widget.dart';
import '../widgets/home/api_key_status_widget.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // 애니메이션 시작
    _animationController.forward();
    
    // 홈 화면 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _initializeHome();
      } catch (e) {
        debugPrint('홈 화면 초기화 중 오류 발생: $e');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 홈 화면 초기화
  Future<void> _initializeHome() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      
      // 로그인 상태 확인
      if (authViewModel.isLoggedIn) {
        // API 키 상태 확인
        await homeViewModel.checkApiKeyStatus(context);
        // PDF 파일 로드
        await _loadPdfFiles();
      } else {
        // 게스트 모드 PDF 파일 로드
        await _loadPdfFiles();
      }
    } catch (e) {
      debugPrint('홈 화면 초기화 중 오류 발생: $e');
    }
  }

  // PDF 파일 목록 로드
  Future<void> _loadPdfFiles() async {
    try {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      await homeViewModel.loadPDFs(context);
    } catch (e) {
      debugPrint('PDF 파일 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일을 로드하는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadPdfFiles,
          child: _buildBody(context),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'PDF Learner',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      actions: [
        // 프로필 아이콘
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            if (!authViewModel.isLoggedIn) {
              return TextButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('로그인'),
                onPressed: () => Navigator.pushNamed(context, '/auth'),
              );
            }
            
            return IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  Provider.of<HomeViewModel>(context).getUserInitial(authViewModel.currentUser!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Consumer<HomeViewModel>(
          builder: (context, homeViewModel, child) {
            // 로딩 상태
            if (homeViewModel.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('로딩 중...'),
                  ],
                ),
              );
            }

            // 오류 발생
            if (homeViewModel.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(homeViewModel.errorMessage),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPdfFiles,
                      child: Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            return Consumer<PDFProvider>(
              builder: (context, pdfProvider, child) {
                // 게스트 모드이고 PDF가 없는 경우
                if (!authViewModel.isLoggedIn && pdfProvider.pdfFiles.isEmpty) {
                  return _buildGuestModeMessage();
                }

                // PDF 목록 표시
                return pdfProvider.pdfFiles.isEmpty 
                  ? _buildEmptyState() 
                  : _buildPdfList(pdfProvider.pdfFiles);
              }
            );
          },
        );
      },
    );
  }

  Widget _buildPdfList(List<PdfFileInfo> pdfFiles) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내 PDF 목록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final pdf = pdfFiles[index];
                return PdfListItem(
                  pdfInfo: pdf,
                  onOpen: () => _openPdf(context, pdf),
                  onDelete: (pdf) => _deletePdf(context, pdf),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_state.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF 파일이 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF 파일을 추가하여 AI 학습을 시작하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('PDF 추가하기'),
            onPressed: () => _pickPdf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestModeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/guest_mode.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          const Text(
            '게스트 모드입니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '로그인하여 모든 기능을 사용해보세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('로그인하기'),
            onPressed: () => Navigator.pushNamed(context, '/auth'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('게스트로 사용하기'),
            onPressed: () => _pickPdf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, child) {
        return FloatingActionButton.extended(
          onPressed: () => homeViewModel.pickPDF(context),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'PDF 업로드',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  // 정렬 옵션 다이얼로그
  void _showSortOptionsDialog(BuildContext context) {
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('정렬 방식 선택'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                // 이름순 정렬 (오름차순)
                // 이미 pdfProvider에 정렬 메소드가 없으므로 여기서는 삭제
                setState(() {
                  // 상태 업데이트만 수행
                });
              },
              child: const Text('이름순 정렬 (A-Z)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                // 날짜순 정렬 (최신순)
                setState(() {
                  // 상태 업데이트만 수행
                });
              },
              child: const Text('날짜순 정렬 (최신순)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                // 크기순 정렬 (큰 것부터)
                setState(() {
                  // 상태 업데이트만 수행
                });
              },
              child: const Text('크기순 정렬 (큰 것부터)'),
            ),
          ],
        );
      },
    );
  }

  // PDF 파일 열기
  void _openPdf(BuildContext context, PdfFileInfo pdfFile) {
    // PDF 뷰어 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdf: pdfFile),
      ),
    );
  }
  
  // PDF 파일 삭제
  void _deletePdf(BuildContext context, PdfFileInfo pdfFile) {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
    homeViewModel.deletePDF(context, pdfProvider, pdfFile);
  }
  
  // PDF 파일 선택
  void _pickPdf(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    homeViewModel.pickPDF(context);
  }
} 