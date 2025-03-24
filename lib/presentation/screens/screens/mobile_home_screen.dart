import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../widgets/pdf_grid_item.dart';
import '../widgets/pdf_list_item.dart';

/// 모바일 홈 화면
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({Key? key}) : super(key: key);

  @override
  _MobileHomeScreenState createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickPDF() async {
    // PDF 파일 선택 로직 구현
    try {
      // TODO: 파일 피커 구현
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일 선택 기능은 아직 구현되지 않았습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 오류: $e')),
      );
    }
  }

  Future<void> _openUrlDialog() async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL에서 PDF 열기'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(urlController.text),
            child: const Text('열기'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final pdfViewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
      try {
        await pdfViewModel.openDocumentFromUrl(result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL에서 PDF 열기 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final pdfViewModel = Provider.of<PdfViewerViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('PDF Learner')
            : TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '검색...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
        actions: [
          // 검색 아이콘
          IconButton(
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.close),
            onPressed: () {
              setState(() {
                if (_searchQuery.isNotEmpty) {
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  // 검색 모드 활성화
                  FocusScope.of(context).requestFocus(FocusNode());
                  _searchController.clear();
                }
              });
            },
          ),
          // 뷰 전환 아이콘
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // 더보기 메뉴
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      themeViewModel.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    Text(themeViewModel.isDarkMode ? '라이트 모드' : '다크 모드'),
                  ],
                ),
                onTap: () {
                  themeViewModel.toggleTheme();
                },
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('설정'),
                  ],
                ),
              ),
              if (currentUser != null)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('로그아웃'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) async {
              if (value == 'settings') {
                // 설정 화면으로 이동
                // TODO: 네비게이션 구현
              } else if (value == 'logout') {
                await authViewModel.signOut();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '모든 PDF'),
            Tab(text: '최근 조회'),
            Tab(text: '북마크'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 모든 PDF 탭
          _buildDocumentsTab(
            pdfViewModel.documents.where((doc) {
              if (_searchQuery.isEmpty) return true;
              return doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList(),
          ),
          
          // 최근 조회 탭
          _buildDocumentsTab(
            pdfViewModel.documents.where((doc) {
              if (_searchQuery.isEmpty) return true;
              return doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList()
              ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt)),
          ),
          
          // 북마크 탭
          _buildBookmarksTab(pdfViewModel),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 문서 목록/그리드 탭 구현
  Widget _buildDocumentsTab(List<dynamic> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'PDF 문서가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '오른쪽 하단의 + 버튼을 눌러\nPDF 파일을 추가해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return PdfGridItem(
                document: document,
                onTap: () async {
                  final pdfViewModel =
                      Provider.of<PdfViewerViewModel>(context, listen: false);
                  await pdfViewModel.openDocument(document);
                  
                  // TODO: PDF 뷰어 화면으로 이동
                },
                onMorePressed: () {
                  _showDocumentOptions(document);
                },
              );
            },
          )
        : ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return PdfListItem(
                document: document,
                onTap: () async {
                  final pdfViewModel =
                      Provider.of<PdfViewerViewModel>(context, listen: false);
                  await pdfViewModel.openDocument(document);
                  
                  // TODO: PDF 뷰어 화면으로 이동
                },
                onMorePressed: () {
                  _showDocumentOptions(document);
                },
              );
            },
          );
  }

  // 북마크 탭 구현
  Widget _buildBookmarksTab(PdfViewerViewModel pdfViewModel) {
    // 모든 문서에서 북마크가 있는 것들만 가져옴
    final bookmarkedDocs = pdfViewModel.documents
        .where((doc) => doc.bookmarks.isNotEmpty)
        .toList();

    if (bookmarkedDocs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '북마크가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'PDF 문서를 열어서 북마크를 추가해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // 북마크 목록 구현
    return ListView.builder(
      itemCount: bookmarkedDocs.length,
      itemBuilder: (context, docIndex) {
        final document = bookmarkedDocs[docIndex];
        
        // 북마크 목록 헤더
        return ExpansionTile(
          title: Text(
            document.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text('${document.bookmarks.length}개의 북마크'),
          leading: const Icon(Icons.picture_as_pdf),
          children: document.bookmarks.map((bookmark) {
            return ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(bookmark.title),
              subtitle: Text('${bookmark.pageNumber + 1}페이지'),
              onTap: () async {
                // 해당 북마크로 문서 열기
                await pdfViewModel.openDocument(document);
                pdfViewModel.goToPage(bookmark.pageNumber);
                
                // TODO: PDF 뷰어 화면으로 이동
              },
            );
          }).toList(),
        );
      },
    );
  }

  // 문서 추가 옵션 다이얼로그
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_open),
                title: const Text('파일에서 열기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('URL에서 열기'),
                onTap: () {
                  Navigator.pop(context);
                  _openUrlDialog();
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.camera_alt),
              //   title: const Text('스캔하기'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // TODO: 스캔 기능 구현
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  // 문서 옵션 다이얼로그
  void _showDocumentOptions(dynamic document) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('열기'),
                onTap: () async {
                  Navigator.pop(context);
                  final pdfViewModel =
                      Provider.of<PdfViewerViewModel>(context, listen: false);
                  await pdfViewModel.openDocument(document);
                  
                  // TODO: PDF 뷰어 화면으로 이동
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('공유하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 공유 기능 구현
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('정보 보기'),
                onTap: () {
                  Navigator.pop(context);
                  _showDocumentInfo(document);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(document);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 문서 정보 다이얼로그
  void _showDocumentInfo(dynamic document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('문서 정보'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('제목', document.title),
                _infoRow('파일명', document.fileName),
                _infoRow('파일 크기', _formatFileSize(document.fileSize)),
                _infoRow('페이지 수', '${document.pageCount} 페이지'),
                _infoRow('북마크 수', '${document.bookmarks.length}개'),
                _infoRow('주석 수', '${document.annotations.length}개'),
                _infoRow('최근 조회', _formatDate(document.lastAccessedAt)),
                _infoRow('조회 횟수', '${document.accessCount}회'),
                _infoRow('생성일', _formatDate(document.createdAt)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  // 문서 정보 행
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation(dynamic document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text('정말로 "${document.title}" 문서를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                final pdfViewModel =
                    Provider.of<PdfViewerViewModel>(context, listen: false);
                await pdfViewModel.deleteDocument(document);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('문서가 삭제되었습니다')),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 파일 크기 포맷 변환
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // 날짜 포맷 변환
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }
} 