import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/pdf_document.dart';
import '../viewmodels/document_list_viewmodel.dart';
import '../viewmodels/document_actions_viewmodel.dart';
import '../services/dialog_service.dart';
import '../widgets/pdf_card.dart';
import 'pdf_viewer_page.dart';
import 'settings_page.dart';
import '../services/auth_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/platform_ad_widget.dart';
import '../services/subscription_service.dart';
import '../views/components/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearchActive = false;
  late TabController _tabController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 문서 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final documentListViewModel = Provider.of<DocumentListViewModel>(context, listen: false);
      documentListViewModel.loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listViewModel = context.watch<DocumentListViewModel>();
    final actionViewModel = context.read<DocumentActionsViewModel>();
    final dialogService = context.read<DialogService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final isPremium = subscriptionService.isPremium;
    
    return WillPopScope(
      onWillPop: () async {
        return true; // 뒤로가기 허용
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(context, listViewModel, dialogService),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentList(),
                  _buildFavoritesList(),
                ],
              ),
            ),
            if (!isPremium)
              Container(
                height: 50,
                color: Colors.grey[200],
                child: const Center(
                  child: Text('광고 영역'),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, dialogService),
        drawer: _buildDrawer(context),
      ),
    );
  }

  // 앱바 구성
  PreferredSizeWidget _buildAppBar(
    BuildContext context, 
    DocumentListViewModel viewModel,
    DialogService dialogService,
  ) {
    if (_isSearchActive) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '문서 검색...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                viewModel.clearSearch();
              },
            ),
          ),
          onChanged: viewModel.setSearchQuery,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearchActive = false;
              _searchController.clear();
              viewModel.clearSearch();
            });
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '내 문서'),
            Tab(text: '즐겨찾기'),
          ],
        ),
      );
    }
    
    return AppBar(
      title: const Text('PDF 학습 도구'),
      actions: [
        // 검색 버튼
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchActive = true;
            });
          },
        ),
        // 정렬 버튼
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => dialogService.showSortOptions(context),
        ),
        // 더보기 메뉴
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
                break;
              case 'add_sample':
                dialogService.addSamplePdf(context);
                break;
            }
          },
          itemBuilder: (context) => [
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
            const PopupMenuItem(
              value: 'add_sample',
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file),
                  SizedBox(width: 8),
                  Text('샘플 PDF 추가'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '내 문서'),
          Tab(text: '즐겨찾기'),
        ],
      ),
    );
  }

  // 본문 구성
  Widget _buildBody(DocumentListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다: ${viewModel.errorMessage}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.loadDocuments,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    final documents = viewModel.filteredDocuments;
    
    if (documents.isEmpty) {
      return _buildEmptyState();
    }
    
    // 스태거드 그리드 뷰 사용
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: _calculateColumnCount(context),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentCard(context, documents[index]);
        },
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _isSearchActive 
                ? '검색 결과가 없습니다' 
                : 'PDF 문서가 없습니다',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearchActive 
                ? '다른 검색어를 시도해보세요' 
                : '오른쪽 하단의 버튼을 눌러 PDF를 추가하세요',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 문서 카드 위젯
  Widget _buildDocumentCard(BuildContext context, PDFDocument document) {
    final actionViewModel = context.read<DocumentActionsViewModel>();
    final dialogService = context.read<DialogService>();
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _onDocumentTap(context, document),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3/4,
                  child: _buildThumbnail(document),
                ),
                // 문서 페이지 수
                if (document.pageCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${document.pageCount}페이지',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 문서 정보
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '마지막 열람: ${DateFormatter.formatDate(document.lastOpened)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // 액션 버튼
            ButtonBar(
              buttonPadding: EdgeInsets.zero,
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '이름 변경',
                  onPressed: () => dialogService.showRenameDialog(
                    context,
                    document.id,
                    document.title,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '삭제',
                  onPressed: () => dialogService.showDeleteConfirmDialog(
                    context,
                    document.id,
                    document.title,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 썸네일 위젯
  Widget _buildThumbnail(PDFDocument document) {
    if (kIsWeb) {
      // 웹 환경에서는 기본 이미지 표시
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.picture_as_pdf,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // 썸네일 경로가 있으면 이미지 표시
    if (document.thumbnailPath.isNotEmpty) {
      return Image.file(
        File(document.thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return _buildDefaultThumbnail();
        },
      );
    }
    
    return _buildDefaultThumbnail();
  }

  // 기본 썸네일 위젯
  Widget _buildDefaultThumbnail() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  // 플로팅 액션 버튼
  Widget _buildFloatingActionButton(BuildContext context, DialogService dialogService) {
    return FloatingActionButton(
      onPressed: () => dialogService.showAddPdfOptions(context),
      tooltip: 'PDF 추가',
      child: const Icon(Icons.add),
    );
  }

  // 드로어 메뉴
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF 학습 도구',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                // 사용자 정보
                Row(
                  children: [
                    CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '게스트 사용자',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('홈'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('설정'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 화면 크기에 따른 열 수 계산
  int _calculateColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  // 파일 크기 포맷팅
  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '크기 불명';
    
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return '방금 전';
        }
        return '${diff.inMinutes}분 전';
      }
      return '${diff.inHours}시간 전';
    }
    
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    
    if (date.year == now.year) {
      return '${date.month}월 ${date.day}일';
    }
    
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// 문서 목록 위젯
  Widget _buildDocumentList() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final documents = viewModel.documents;
        
        if (documents.isEmpty) {
          return NoDocumentsWidget();
        }
        
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return _buildDocumentItem(document);
          },
        );
      },
    );
  }
  
  /// 즐겨찾기 목록 위젯
  Widget _buildFavoritesList() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        final documents = viewModel.documents;
        
        // 즐겨찾기가 있는 문서만 필터링
        final favoriteDocuments = documents.where((doc) => doc.favorites.isNotEmpty).toList();
        
        if (favoriteDocuments.isEmpty) {
          return const Center(
            child: Text('즐겨찾기가 없습니다.'),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '즐겨찾기',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: favoriteDocuments.length,
                itemBuilder: (context, index) {
                  final document = favoriteDocuments[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 160,
                      child: DocumentCard(
                        document: document,
                        onTap: () => _onDocumentTap(context, document),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 문서 항목 위젯
  Widget _buildDocumentItem(PDFDocument document) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildThumbnail(document),
        title: Text(document.title),
        subtitle: Text('마지막 열람: ${_formatDate(document.lastOpened)}'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showDocumentOptions(document),
        ),
        onTap: () => _onDocumentTap(context, document),
      ),
    );
  }
  
  /// 문서를 탭했을 때 실행되는 함수
  void _onDocumentTap(BuildContext context, PDFDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(document: document),
      ),
    );
  }
  
  /// 문서 옵션 표시
  void _showDocumentOptions(PDFDocument document) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(context);
                // 이름 변경 로직
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('즐겨찾기에 추가'),
              onTap: () {
                Navigator.pop(context);
                // 즐겨찾기 추가 로직
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                // 삭제 로직
              },
            ),
          ],
        );
      },
    );
  }
}

/// 문서가 없을 때 표시되는 위젯
class NoDocumentsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 PDF 문서가 없습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '하단의 + 버튼을 눌러 PDF를 추가해보세요.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (kIsWeb) {
                // 웹 환경에서는 샘플 PDF 추가
                Provider.of<DocumentActionsViewModel>(context, listen: false)
                    .addSamplePdf();
              } else {
                Provider.of<DocumentActionsViewModel>(context, listen: false)
                    .addDocumentFromDevice();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(kIsWeb ? '샘플 PDF 추가' : 'PDF 추가하기'),
          ),
        ],
      ),
    );
  }
}

/// 문서 그리드 뷰
class DocumentGridView extends StatelessWidget {
  final List<PDFDocument> documents;
  final Function(PDFDocument) onDocumentTap;
  
  const DocumentGridView({
    Key? key,
    required this.documents,
    required this.onDocumentTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onTap: () => onDocumentTap(document),
        );
      },
    );
  }
}

/// 문서 카드 위젯
class DocumentCard extends StatelessWidget {
  final PDFDocument document;
  final VoidCallback onTap;
  
  const DocumentCard({
    Key? key,
    required this.document,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildThumbnail(),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                    '${document.pageCount} 페이지',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '최근 열람: ${_formatDate(document.lastOpened)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
  
  Widget _buildThumbnail() {
    if (kIsWeb) {
      // 웹 환경에서는 기본 이미지 표시
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.picture_as_pdf,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // 썸네일 경로가 있으면 이미지 표시
    if (document.thumbnailPath.isNotEmpty) {
      return Image.file(
        File(document.thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return _buildDefaultThumbnail();
        },
      );
    }
    
    return _buildDefaultThumbnail();
  }
  
  Widget _buildDefaultThumbnail() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}.${dateTime.month}.${dateTime.day}';
    }
  }
} 