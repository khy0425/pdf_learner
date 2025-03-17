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
import '../widgets/pdf_list_item.dart';
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
    // 인증 상태 확인
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isLoggedIn = authViewModel.isLoggedIn;
    
    if (isLoggedIn) {
      // 사용자가 로그인한 경우 PDF 목록 로드
      await _loadPdfFiles();
    }
  }

  // PDF 파일 목록 로드
  Future<void> _loadPdfFiles() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final pdfViewModel = Provider.of<PdfFileViewModel>(context, listen: false);
      
      final currentUser = authViewModel.currentUser;
      if (currentUser != null) {
        debugPrint('PDF 파일 목록 로드 시작: ${currentUser.uid}');
        await pdfViewModel.loadPdfFiles(currentUser.uid);
      } else {
        debugPrint('로그인된 사용자 없음: 게스트 모드로 진행');
        // 로그인 화면으로 이동하지 않고 게스트 모드로 진행
        // 게스트 모드에서는 PDF 목록이 비어있는 상태로 표시됨
      }
    } catch (e) {
      debugPrint('PDF 파일 목록 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 목록을 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Learner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadPdfFiles,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer2<AuthViewModel, PdfFileViewModel>(
      builder: (context, authViewModel, pdfViewModel, child) {
        if (authViewModel.isLoading || pdfViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!authViewModel.isLoggedIn) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyStateView(
                icon: Icons.account_circle,
                title: '게스트 모드',
                message: '로그인하면 PDF 파일을 저장하고 관리할 수 있습니다',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
                child: const Text('로그인하기'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showUploadOptions,
                child: const Text('게스트 모드로 PDF 업로드하기'),
              ),
            ],
          );
        }
        
        if (pdfViewModel.pdfFiles.isEmpty) {
          return const EmptyStateView(
            icon: Icons.upload_file,
            title: 'PDF 파일이 없습니다',
            message: '+ 버튼을 눌러 PDF 파일을 업로드하세요',
          );
        }
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: pdfViewModel.pdfFiles.length,
            itemBuilder: (context, index) {
              final pdf = pdfViewModel.pdfFiles[index];
              return PDFListItem(
                pdfFile: pdf,
                onTap: () => _openPdfViewer(pdf),
              );
            },
          ),
        );
      },
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('파일에서 업로드'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('URL에서 업로드'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromUrl();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadFromFile() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final pdfViewModel = Provider.of<PdfFileViewModel>(context, listen: false);
      final currentUser = authViewModel.currentUser;
      
      if (currentUser == null) {
        debugPrint('로그인되지 않은 상태: 게스트 모드로 파일 업로드');
        // 게스트 모드에서는 임시 ID 생성
        const guestId = 'guest_user';
        await pdfViewModel.uploadPdfFromFilePicker(guestId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게스트 모드에서 파일이 업로드되었습니다. 파일을 저장하려면 로그인하세요.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      await pdfViewModel.uploadPdfFromFilePicker(currentUser.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 업로드가 완료되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('파일 업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 업로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _uploadFromUrl() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.currentUser;
      final String userId = currentUser?.uid ?? 'guest_user';
      
      if (currentUser == null) {
        debugPrint('로그인되지 않은 상태: 게스트 모드로 URL 업로드');
      }
      
      final TextEditingController urlController = TextEditingController();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('URL에서 PDF 업로드'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'https://example.com/document.pdf',
              labelText: 'PDF URL',
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (urlController.text.isNotEmpty) {
                  try {
                    final pdfViewModel = Provider.of<PdfFileViewModel>(context, listen: false);
                    pdfViewModel.uploadPdfFromUrl(
                      urlController.text,
                      userId,
                    );
                    
                    final message = currentUser == null
                        ? '게스트 모드에서 URL 업로드가 시작되었습니다. 파일을 저장하려면 로그인하세요.'
                        : 'URL에서 PDF 업로드가 시작되었습니다';
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  } catch (e) {
                    debugPrint('URL 업로드 오류: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('URL 업로드 중 오류가 발생했습니다: $e')),
                    );
                  }
                }
              },
              child: const Text('업로드'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('URL 업로드 다이얼로그 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _openPdfViewer(PdfFileInfo pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(pdf: pdf),
      ),
    );
  }
} 