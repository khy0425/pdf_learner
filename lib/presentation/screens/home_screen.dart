import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'document_list_screen.dart';
import 'pdf_viewer_screen.dart';
import '../../core/localization/app_localizations.dart';

/// 반응형 홈 스크린
/// 
/// 화면 크기에 따라 모바일/데스크톱 버전을 선택하여 표시합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  
  // 탭 인덱스에 따른 화면들
  final List<Widget> _pages = [
    const DocumentListScreen(),
    const Center(child: Text('검색 화면 - 준비 중')),
    const Center(child: Text('프로필 화면 - 준비 중')),
  ];
  
  // 탭 아이템들
  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.folder),
      label: '문서',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: '검색',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: '프로필',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // PDF 문서 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
      pdfViewModel.loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, PDFViewModel>(
      builder: (context, authViewModel, pdfViewModel, child) {
        // 인증 관련 에러 상태이면 스낵바 표시
        if (authViewModel.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? '인증 오류가 발생했습니다')),
            );
            // 에러 메시지를 표시한 후 상태 초기화
            authViewModel.clearError();
          });
        }
        
        // PDF 관련 에러 상태이면 스낵바 표시
        if (pdfViewModel.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(pdfViewModel.error ?? 'PDF 처리 중 오류가 발생했습니다')),
            );
            // 에러 메시지를 표시한 후 상태 초기화
            pdfViewModel.clearError();
          });
        }
        
        return Scaffold(
          backgroundColor: Color(0xFFF5F7FA), // 배경색 변경 - 연한 회색빛 배경
          appBar: AppBar(
            title: const Text('PDF 학습기'),
            actions: [
              // 언어 선택
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  // 언어 선택 기능
                },
              ),
              // 설정 버튼
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // 설정 화면으로 이동
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 미회원 모드 배너 표시
              if (authViewModel.isGuestMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '미회원 모드로 이용 중입니다. 로그인하면 더 많은 기능을 이용할 수 있습니다.',
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // 로그인 화면으로 이동
                          },
                          child: const Text('로그인'),
                        )
                      ],
                    ),
                  ),
                ),
              
              // 메인 콘텐츠
              Expanded(child: _pages[_selectedTabIndex]),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                await pdfViewModel.pickAndAddPDF();
                if (pdfViewModel.error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(pdfViewModel.error!)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF 추가 중 오류가 발생했습니다: $e')),
                  );
                }
              }
            },
            tooltip: 'PDF 추가',
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            items: _bottomNavItems,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
          ),
        );
      }
    );
  }
  
  void _showAddPdfDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('파일에서 불러오기'),
              onTap: () {
                Navigator.pop(context);
                final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
                pdfViewModel.pickAndAddPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL로 불러오기'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
  
  void _showUrlInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL로 PDF 불러오기'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'PDF URL 입력',
            hintText: 'https://example.com/sample.pdf',
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
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
                pdfViewModel.addPDFFromUrl(url);
                Navigator.pop(context);
              }
            },
            child: const Text('불러오기'),
          ),
        ],
      ),
    );
  }
  
  // PDF 썸네일을 가져오는 함수
  Future<Widget> _getPDFThumbnail(dynamic document) async {
    try {
      final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
      
      // 웹 환경인지 확인
      bool isWeb = kIsWeb;
      
      if (isWeb) {
        // 웹 환경에서는 저장된 썸네일 URL이나 기본 아이콘 사용
        if (document.thumbnailUrl != null && document.thumbnailUrl.isNotEmpty) {
          return Image.network(
            document.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackThumbnail(document);
            },
          );
        } else {
          return _buildFallbackThumbnail(document);
        }
      } else {
        // 네이티브 환경에서는 파일 시스템 접근
        if (document.filePath.isNotEmpty) {
          final file = File(document.filePath);
          final exists = await file.exists();
          
          if (exists) {
            // 썸네일 생성 로직 (실제 구현은 별도로 필요)
            return _buildFallbackThumbnail(document);
          } else if (document.thumbnailUrl != null && document.thumbnailUrl.isNotEmpty) {
            return Image.network(
              document.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackThumbnail(document);
              },
            );
          }
        }
        return _buildFallbackThumbnail(document);
      }
    } catch (e) {
      return _buildFallbackThumbnail(document);
    }
  }
  
  // 대체 썸네일 위젯
  Widget _buildFallbackThumbnail(dynamic document) {
    final colors = [
      const Color(0xFF5D5FEF),
      const Color(0xFFEF5DA8),
      const Color(0xFF5DEFA8),
      const Color(0xFFEFAF5D),
    ];
    
    final random = document.id.hashCode % colors.length;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[random],
            colors[random].withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

// 임시 페이지 위젯 (나중에 별도 파일로 분리)
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            '내 문서 페이지',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('여기에 PDF 문서 목록이 표시됩니다'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // PDF 추가 기능
            },
            child: const Text('PDF 추가하기'),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            '검색 페이지',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('PDF 문서를 검색할 수 있습니다'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            '프로필 페이지',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('여기에 사용자 정보가 표시됩니다'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 로그아웃 기능
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
} 