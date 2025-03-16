import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math' as math;
import '../view_models/auth_view_model.dart';
import '../view_models/pdf_view_model.dart';
import '../view_models/home_view_model.dart';
import '../models/pdf_model.dart';
import '../widgets/home/empty_state_view.dart';
import '../widgets/home/pdf_list_item.dart';
import '../widgets/common/wave_painter.dart';
import 'pdf_viewer_screen.dart';
import 'auth_screen.dart';

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
    
    // 홈 화면 초기화
    _initializeHome();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 홈 화면 초기화
  Future<void> _initializeHome() async {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // 로그인된 사용자가 있는 경우에만 PDF 로드
    if (authViewModel.isLoggedIn) {
      await homeViewModel.loadPDFs(authViewModel.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Learner'),
        actions: [
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              return IconButton(
                icon: Icon(
                  authViewModel.isLoggedIn ? Icons.account_circle : Icons.login,
                ),
                onPressed: () => _showUserProfile(context),
                tooltip: authViewModel.isLoggedIn ? '프로필' : '로그인',
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _refreshPDFs(),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPdfOptions(context),
        child: const Icon(Icons.add),
        tooltip: 'PDF 추가',
      ),
    );
  }

  /// PDF 목록 새로고침
  Future<void> _refreshPDFs() async {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (authViewModel.isLoggedIn) {
      await homeViewModel.loadPDFs(authViewModel.user!.uid);
    }
  }

  /// 메인 화면 구성
  Widget _buildBody() {
    return Consumer3<HomeViewModel, AuthViewModel, PdfViewModel>(
      builder: (context, homeViewModel, authViewModel, pdfViewModel, _) {
        // 로딩 중인 경우
        if (homeViewModel.isLoading || pdfViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 로그인되지 않은 경우
        if (!authViewModel.isLoggedIn) {
          return _buildLoginPrompt();
        }

        // PDF 목록이 비어있는 경우
        if (pdfViewModel.pdfs.isEmpty) {
          return EmptyStateView(
            onAddPdf: () => _showAddPdfOptions(context),
          );
        }

        // PDF 목록 표시
        return _buildPdfList(pdfViewModel.pdfs);
      },
    );
  }

  /// 로그인 프롬프트 화면
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            '로그인이 필요합니다',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('PDF 파일을 관리하려면 로그인해주세요'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showUserProfile(context),
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  /// PDF 목록 화면
  Widget _buildPdfList(List<PdfModel> pdfs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return PdfListItem(
          pdf: pdf,
          onTap: () => _openPdf(pdf),
          onDelete: () => _deletePdf(pdf),
        );
      },
    );
  }

  /// 사용자 프로필 표시
  void _showUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  /// PDF 추가 옵션 표시
  void _showAddPdfOptions(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (!authViewModel.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF를 추가하려면 로그인이 필요합니다')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('파일에서 PDF 업로드'),
            onTap: () {
              Navigator.pop(context);
              homeViewModel.pickPdfFromFile(context, authViewModel.user!.uid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('URL에서 PDF 업로드'),
            onTap: () {
              Navigator.pop(context);
              _showUrlInputDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// URL 입력 다이얼로그 표시
  void _showUrlInputDialog(BuildContext context) {
    final urlController = TextEditingController();
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL에서 PDF 업로드'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'PDF URL',
            hintText: 'https://example.com/document.pdf',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                homeViewModel.pickPdfFromUrl(context, url, authViewModel.user!.uid);
              }
            },
            child: const Text('업로드'),
          ),
        ],
      ),
    );
  }

  /// PDF 열기
  void _openPdf(PdfModel pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdf: pdf),
      ),
    );
  }

  /// PDF 삭제
  void _deletePdf(PdfModel pdf) {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 삭제'),
        content: Text('${pdf.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              homeViewModel.deletePdf(context, pdf.id, authViewModel.user!.uid);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
} 