import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/document_list_viewmodel.dart';
import '../models/pdf_document.dart';
import 'pdf_viewer_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadDocuments() {
    final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    viewModel.loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<DocumentListViewModel>(context);
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF 학습기',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchBar(context),
            tooltip: '검색',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
            tooltip: '설정',
          ),
          if (authService.isLoggedIn)
            IconButton(
              icon: CircleAvatar(
                backgroundImage: NetworkImage(authService.currentUser!.photoURL ?? ''),
                radius: 14,
                backgroundColor: Colors.grey[300],
                child: authService.currentUser!.photoURL == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('${authService.currentUser!.displayName}님'),
                    content: const Text('로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          authService.signOut();
                          Navigator.pop(context);
                        },
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('로그인'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPdfOptions(context, Provider.of<DocumentListViewModel>(context, listen: false)),
        tooltip: 'PDF 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    viewModel.clearError();
                    _loadDocuments();
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        
        if (!viewModel.hasDocuments) {
          return _buildEmptyState();
        }
        
        return Column(
          children: [
            _buildViewToggle(viewModel),
            Expanded(
              child: _isGridView 
                ? _buildGridView(viewModel) 
                : _buildListView(viewModel),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Text(
              '아직 PDF 문서가 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Text(
              'PDF 파일을 추가하여 시작하세요',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: ElevatedButton.icon(
              onPressed: () => _showAddPdfOptions(context, Provider.of<DocumentListViewModel>(context, listen: false)),
              icon: const Icon(Icons.add),
              label: const Text('PDF 추가'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewToggle(DocumentListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '총 ${viewModel.documents.length}개의 문서',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _isGridView 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = true;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.view_list,
                  color: !_isGridView 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(DocumentListViewModel viewModel) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.documents.length,
      itemBuilder: (context, index) {
        final document = viewModel.documents[index];
        return _buildDocumentCard(document, viewModel);
      },
    );
  }
  
  Widget _buildListView(DocumentListViewModel viewModel) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = viewModel.documents[index];
        return _buildDocumentListItem(document, viewModel);
      },
    );
  }
  
  Widget _buildDocumentCard(PDFDocument document, DocumentListViewModel viewModel) {
    return GestureDetector(
      onTap: () => _navigateToPdfViewer(context, document),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: document.thumbnailPath != null
                    ? Image.file(
                        File(document.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.pageCount}페이지 · ${_formatFileSize(document.fileSize)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(document.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentListItem(PDFDocument document, DocumentListViewModel viewModel) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: document.thumbnailPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(document.thumbnailPath!),
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${document.pageCount}페이지 · ${_formatFileSize(document.fileSize)} · ${_formatDate(document.updatedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, document, viewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 18),
                  SizedBox(width: 8),
                  Text('열기'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('이름 변경'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text('삭제'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToPdfViewer(context, document),
      ),
    );
  }
  
  void _handleMenuAction(String action, PDFDocument document, DocumentListViewModel viewModel) {
    switch (action) {
      case 'open':
        _navigateToPdfViewer(context, document);
        break;
      case 'rename':
        _showRenameDialog(context, document, viewModel);
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 기능은 곧 추가될 예정입니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, document, viewModel);
        break;
    }
  }
  
  void _showDeleteConfirmDialog(BuildContext context, PDFDocument document, DocumentListViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 삭제'),
        content: Text('${document.title} 문서를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.deleteDocument(document.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${document.title} 문서가 삭제되었습니다'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
  
  void _showRenameDialog(BuildContext context, PDFDocument document, DocumentListViewModel viewModel) {
    final titleController = TextEditingController(text: document.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 이름 변경'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '문서 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context);
                
                final updatedDocument = document.copyWith(
                  title: titleController.text,
                  updatedAt: DateTime.now(),
                );
                
                final success = await viewModel.updateDocument(updatedDocument);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('문서 이름이 변경되었습니다'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToPdfViewer(BuildContext context, PDFDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(filePath: document.filePath),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }
  }
  
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  void _showSearchBar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final viewModel = Provider.of<DocumentListViewModel>(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'PDF 문서 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    viewModel.setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('정렬: '),
                    const SizedBox(width: 8),
                    DropdownButton<SortOption>(
                      value: viewModel.sortOption,
                      onChanged: (SortOption? option) {
                        if (option != null) {
                          viewModel.setSortOption(option);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: SortOption.nameAZ,
                          child: Row(
                            children: [
                              const Icon(Icons.sort_by_alpha, size: 18),
                              const SizedBox(width: 4),
                              const Text('이름 (A-Z)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.nameZA,
                          child: Row(
                            children: [
                              const Icon(Icons.sort_by_alpha, size: 18),
                              const SizedBox(width: 4),
                              const Text('이름 (Z-A)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.dateNewest,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 4),
                              const Text('최신순'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.dateOldest,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 4),
                              const Text('오래된순'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showAddPdfOptions(BuildContext context, DocumentListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_open),
            title: const Text('기기에서 PDF 파일 선택'),
            subtitle: kIsWeb 
                ? const Text('웹에서는 현재 제한적으로 지원됩니다', style: TextStyle(fontSize: 12, color: Colors.red))
                : null,
            onTap: () {
              Navigator.pop(context);
              _pickPdfFile(context, viewModel);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('URL에서 PDF 가져오기'),
            onTap: () {
              Navigator.pop(context);
              _showUrlInputDialog(context, viewModel);
            },
          ),
          if (kIsWeb)
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('샘플 PDF 사용'),
              subtitle: const Text('테스트용 샘플 PDF를 추가합니다'),
              onTap: () {
                Navigator.pop(context);
                _addSamplePdf(context, viewModel);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickPdfFile(BuildContext context, DocumentListViewModel viewModel) async {
    try {
      setState(() => _isLoading = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final document = await viewModel.addPdfFromFile(filePath);
        
        if (document != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF 파일이 추가되었습니다: ${document.title}'),
              action: SnackBarAction(
                label: '보기',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewerPage(filePath: document.filePath),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 추가 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUrlInputDialog(BuildContext context, DocumentListViewModel viewModel) {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL에서 PDF 추가'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'PDF URL',
            hintText: 'https://example.com/sample.pdf',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                await _addPdfFromUrl(context, viewModel, url);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPdfFromUrl(
    BuildContext context,
    DocumentListViewModel viewModel,
    String url,
  ) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    
    try {
      setState(() => _isLoading = true);
      
      final document = await viewModel.addPdfFromUrl(url);
      
      if (document != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 파일이 추가되었습니다: ${document.title}'),
            action: SnackBarAction(
              label: '보기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(filePath: document.filePath),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL에서 PDF 추가 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _addSamplePdf(BuildContext context, DocumentListViewModel viewModel) async {
    // 샘플 PDF URL 목록 (CORS 정책이 허용된 URL)
    final sampleUrls = [
      'https://cors-anywhere.herokuapp.com/https://www.africau.edu/images/default/sample.pdf',  // Proxy 서버 사용
      'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',  // Mozilla PDF.js 샘플
      'https://raw.githubusercontent.com/mozilla/pdf.js/master/examples/learning/helloworld.pdf',  // GitHub Raw Content
    ];
    
    try {
      setState(() => _isLoading = true);
      
      // 두 번째 샘플 URL 사용 (Mozilla PDF.js 샘플)
      final document = await viewModel.addPdfFromUrl(sampleUrls[1]);
      
      if (document != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('샘플 PDF 파일이 추가되었습니다: ${document.title}'),
            action: SnackBarAction(
              label: '보기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(filePath: document.filePath),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('샘플 PDF 추가 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
} 