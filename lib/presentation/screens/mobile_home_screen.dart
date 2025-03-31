import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewer_viewmodel.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';
import '../../presentation/viewmodels/pdf_file_viewmodel.dart';
import '../widgets/pdf_grid_item.dart';
import '../widgets/pdf_list_item.dart';
import '../models/pdf_file_info.dart';
import 'package:pdf_document/pdf_document.dart';

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
    final pdfFileViewModel = Provider.of<PdfFileViewModel>(context);
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
            pdfFileViewModel.pdfFiles.where((file) {
              if (_searchQuery.isEmpty) return true;
              return file.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  file.title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList(),
          ),
          
          // 최근 조회 탭
          _buildDocumentsTab(
            pdfFileViewModel.pdfFiles.where((file) {
              if (_searchQuery.isEmpty) return true;
              return file.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  file.title.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList()
              ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt)),
          ),
          
          // 북마크 탭
          _buildBookmarksTab(pdfViewModel),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'mobile_home_add',
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 문서 목록/그리드 탭 구현
  Widget _buildDocumentsTab(List<PdfFileInfo> documents) {
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
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final pdfFile = documents[index];
              return PdfGridItem(
                pdfFile: pdfFile,
                onTap: (file) => _openPdf(context, file),
                onFavoriteToggle: (file) => _toggleFavorite(file),
                onDelete: (file) => _showDeleteDialog(file),
                key: ValueKey('pdf_grid_${pdfFile.id}'),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final pdfFile = documents[index];
              return PdfListItem(
                pdfFile: pdfFile,
                onTap: (file) => _openPdf(context, file),
                onFavoriteToggle: (file) => _toggleFavorite(file),
                onDelete: (file) => _showDeleteDialog(file),
                key: ValueKey('pdf_${pdfFile.id}'),
              );
            },
          );
  }

  // PDF 열기
  void _openPdf(BuildContext context, PdfFileInfo file) {
    try {
      // PdfFileInfo를 PDFDocument로 변환
      final pdfDocument = PDFDocument(
        id: file.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : file.id,
        title: file.title.isEmpty ? file.name : file.title,
        filePath: file.path,
        pageCount: file.pageCount,
        size: file.size,
        fileSize: file.fileSize,
        thumbnailUrl: file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty 
            ? file.thumbnailPath 
            : '',
      );

      // PDF 뷰어 페이지로 이동
      Navigator.pushNamed(
        context,
        '/pdf_viewer',
        arguments: {
          'pdfDocument': pdfDocument,
          'initialPage': 0,
        },
      );

      // 파일 접근 시간 업데이트
      final updatedFile = file.updateLastAccessed();
      final viewModel = Provider.of<PdfFileViewModel>(context, listen: false);
      
      // 해당 파일의 상태 업데이트
      viewModel.updateFile(updatedFile);
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 파일을 열 수 없습니다: $e')),
      );
    }
  }

  // 즐겨찾기 토글
  void _toggleFavorite(PdfFileInfo file) {
    final pdfFileViewModel = Provider.of<PdfFileViewModel>(context, listen: false);
    pdfFileViewModel.toggleFavorite(file.path);
  }

  // 삭제 확인 대화상자
  void _showDeleteDialog(PdfFileInfo file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF 삭제'),
        content: Text('${file.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePdf(file);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // PDF 삭제
  void _deletePdf(PdfFileInfo file) async {
    final pdfFileViewModel = Provider.of<PdfFileViewModel>(context, listen: false);
    try {
      await pdfFileViewModel.deleteFile(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.name} 삭제됨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  // 북마크 탭 구현
  Widget _buildBookmarksTab(PdfViewerViewModel pdfViewModel) {
    final bookmarkedFiles = Provider.of<PdfFileViewModel>(context)
        .pdfFiles
        .where((file) => file.isFavorite)
        .toList();
    
    if (bookmarkedFiles.isEmpty) {
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
              '북마크한 PDF가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildDocumentsTab(bookmarkedFiles);
  }

  // 추가 옵션 다이얼로그 표시
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('기기에서 PDF 열기'),
            onTap: () {
              Navigator.pop(context);
              _pickPDF();
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('URL에서 PDF 열기'),
            onTap: () {
              Navigator.pop(context);
              _openUrlDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('샘플 PDF 열기'),
            onTap: () async {
              Navigator.pop(context);
              final pdfViewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
              try {
                await pdfViewModel.openSampleDocument();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('샘플 PDF를 열었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('샘플 PDF 열기 실패: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
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