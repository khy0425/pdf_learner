import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;
import '../view_models/auth_view_model.dart';
import '../view_models/pdf_view_model.dart';
import '../models/pdf_model.dart';
import '../widgets/home/empty_state_view.dart';
import '../widgets/home/pdf_list_item.dart';
import '../widgets/common/wave_painter.dart';
import 'pdf_viewer_screen.dart';

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
        curve: Curves.easeInOut,
      ),
    );
    
    // 애니메이션 시작
    _animationController.forward();
    
    // PDF 파일 목록 로드
    _checkUserAndLoadPDFs();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 사용자 정보 확인 후 필요한 경우에만 PDF 로드
  Future<void> _checkUserAndLoadPDFs() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // 로그인된 사용자가 있는 경우에만 PDF 로드
      if (authViewModel.isLoggedIn) {
        debugPrint('로그인된 사용자: ${authViewModel.user?.uid} - PDF 로드 시작');
        await pdfViewModel.loadPdfs(authViewModel.user!.uid);
      } else {
        debugPrint('로그인되지 않은 사용자: PDF 로드 건너뜀');
      }
    } catch (e) {
      debugPrint('사용자 정보 확인 중 오류: $e');
    }
  }

  /// PDF 파일 선택
  void _pickPDF(BuildContext context) async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      if (!authViewModel.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF를 업로드하려면 로그인이 필요합니다.')),
        );
        return;
      }
      
      // TODO: PDF 파일 선택 및 업로드 구현
      // 파일 선택 다이얼로그 표시
      // 선택된 파일을 PdfViewModel을 통해 업로드
    } catch (e) {
      debugPrint('PDF 파일 선택 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 파일을 선택할 수 없습니다: $e')),
      );
    }
  }

  /// PDF 파일 삭제
  void _deletePDF(PdfModel pdf) async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      if (!authViewModel.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF를 삭제하려면 로그인이 필요합니다.')),
        );
        return;
      }
      
      // 삭제 확인 다이얼로그 표시
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF 삭제'),
          content: Text('${pdf.name} 파일을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await pdfViewModel.deletePdf(pdf.id, authViewModel.user!.uid);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF 파일이 삭제되었습니다.')),
          );
        }
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일을 삭제할 수 없습니다: $e')),
        );
      }
    }
  }

  /// PDF 파일 열기
  void _openPdf(PdfModel pdf) async {
    try {
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      
      // PDF 선택
      pdfViewModel.selectPdf(pdf);
      
      // PDF 뷰어 화면으로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(pdf: pdf),
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일을 열 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage 빌드 호출됨');
    
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
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _checkUserAndLoadPDFs,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickPDF(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // 로그인 버튼
  Widget _buildLoginButton(ColorScheme colorScheme) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isLoggedIn) {
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
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: Icon(Icons.person, color: Colors.white, size: 16),
              label: Text(
                '프로필',
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
        }
        
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
  
  // 앱 정보 다이얼로그
  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Learner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF 파일을 분석하고 학습하는 앱입니다.'),
            SizedBox(height: 8),
            Text('버전: 1.0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  // 본문 위젯
  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer2<AuthViewModel, PdfViewModel>(
      builder: (context, authViewModel, pdfViewModel, _) {
        // 로딩 화면
        if (pdfViewModel.isLoading) {
          return _buildLoadingView(colorScheme);
        }
        
        // 오류 화면
        if (pdfViewModel.error != null) {
          return _buildErrorView(colorScheme, pdfViewModel.error!);
        }
        
        // 로그인되지 않은 경우
        if (!authViewModel.isLoggedIn) {
          return _buildNotLoggedInView(colorScheme);
        }
        
        // PDF 목록이 비어있는 경우
        if (pdfViewModel.pdfs.isEmpty) {
          return EmptyStateView(
            onAddPdf: () => _pickPDF(context),
          );
        }
        
        // PDF 목록 표시
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildPdfListView(pdfViewModel.pdfs, colorScheme),
        );
      },
    );
  }
  
  // 로딩 화면
  Widget _buildLoadingView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'PDF 파일을 불러오는 중...',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // 오류 화면
  Widget _buildErrorView(ColorScheme colorScheme, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checkUserAndLoadPDFs,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
  
  // 로그인되지 않은 경우 화면
  Widget _buildNotLoggedInView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'PDF 파일을 관리하려면 로그인이 필요합니다',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            icon: const Icon(Icons.login),
            label: const Text('로그인'),
          ),
        ],
      ),
    );
  }
  
  // PDF 목록 화면
  Widget _buildPdfListView(List<PdfModel> pdfs, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, bottom: 80),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PdfListItem(
            pdf: pdf,
            onTap: () => _openPdf(pdf),
            onDelete: () => _deletePDF(pdf),
          ),
        );
      },
    );
  }
} 