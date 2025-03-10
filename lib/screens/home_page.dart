import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_list_item.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:js' as js;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadPDFs();
    _getUserInfo();
  }
  
  void _getUserInfo() {
    if (kIsWeb) {
      try {
        // JavaScript에서 현재 로그인된 사용자 확인
        final user = js.context.callMethod('getCurrentFirebaseUser', []);
        if (user != null && user != '') {
          setState(() {
            _userId = user.toString();
          });
          return;
        }
        
        // 저장된 사용자 정보 확인
        final storedUserInfo = _getStoredUserInfo();
        if (storedUserInfo != null && storedUserInfo['userId'] != null) {
          final storedUserId = storedUserInfo['userId'].toString();
          
          if (mounted) {
            setState(() {
              _userId = storedUserId;
            });
          }
        }
      } catch (e) {
        debugPrint('로그인 상태 확인 오류: $e');
      }
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
      }
    }
  }
  
  // 로컬 스토리지에서 사용자 정보 가져오기
  dynamic _getStoredUserInfo() {
    try {
      return js.context.callMethod('getStoredUserInfo', []);
    } catch (e) {
      debugPrint('저장된 사용자 정보 가져오기 오류: $e');
      return null;
    }
  }
  
  // 로그아웃 기능
  void _logout() {
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (kIsWeb) {
        js.context.callMethod('logoutUser', []);
      } else {
        FirebaseAuth.instance.signOut();
      }
      
      // 상태 업데이트
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _userId = '로그아웃됨';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPDFs() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      await context.read<PDFProvider>().loadSavedPDFs(context);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'PDF 파일 로드 중 오류 발생: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Learner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('PDF 파일 로드 중 오류 발생', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPDFs,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF 파일을 불러오는 중...'),
          ],
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final pdfProvider = Provider.of<PDFProvider>(context);

    return Column(
      children: [
        // 사용자 정보 영역
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '로그인 ID: $_userId',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '총 PDF 파일: ${pdfProvider.pdfFiles.length}개',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => pdfProvider.pickPDF(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('PDF 업로드'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        Expanded(
          child: pdfProvider.pdfFiles.isEmpty
              ? _buildEmptyState(pdfProvider)
              : _buildPdfList(pdfProvider),
        ),
      ],
    );
  }

  Widget _buildEmptyState(PDFProvider pdfProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'PDF 파일을 업로드해주세요',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '업로드한 PDF 파일을 AI가 분석하여 학습을 도와드립니다',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => pdfProvider.pickPDF(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('PDF 업로드'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfList(PDFProvider pdfProvider) {
    return RefreshIndicator(
      onRefresh: _loadPDFs,
      child: ListView.builder(
        itemCount: pdfProvider.pdfFiles.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          return PDFListItem(
            pdfFile: pdfProvider.pdfFiles[index],
          );
        },
      ),
    );
  }
} 