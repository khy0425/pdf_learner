import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/pdf_document.dart';
import '../models/sort_option.dart';
import '../viewmodels/document_list_viewmodel.dart';
import '../viewmodels/document_actions_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../services/dialog_service.dart';
import '../widgets/pdf_card.dart';
import 'pdf_viewer_page.dart';
import 'settings_page.dart';
import '../services/auth_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/platform_ad_widget.dart';
import '../services/subscription_service.dart';
import '../views/components/app_drawer.dart';
import '../services/thumbnail_service.dart';
import '../utils/color_generator.dart';
import '../repositories/pdf_repository.dart';
import '../services/file_picker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면별 ViewModel 관리를 위한 MultiProvider
    return MultiProvider(
      providers: [
        // 문서 목록 ViewModel
        ChangeNotifierProvider<DocumentListViewModel>(
          create: (context) {
            final viewModel = DocumentListViewModel(
              repository: context.read<PDFRepository>(),
            );
            // 문서 목록 로드 - 생성 직후 자동 호출
            viewModel.loadDocuments();
            return viewModel;
          },
        ),
        
        // 문서 액션 ViewModel (문서 목록 ViewModel에 의존)
        ChangeNotifierProxyProvider<DocumentListViewModel, DocumentActionsViewModel>(
          create: (context) => DocumentActionsViewModel(
            repository: context.read<PDFRepository>(),
            listViewModel: context.read<DocumentListViewModel>(),
            filePickerService: context.read<FilePickerService>(),
          ),
          update: (context, listViewModel, previous) => 
            previous ?? DocumentActionsViewModel(
              repository: context.read<PDFRepository>(), 
              listViewModel: listViewModel,
              filePickerService: context.read<FilePickerService>(),
            ),
        ),
        
        // 필요 시 설정 ViewModel
        FutureProvider<SettingsViewModel>(
          create: (_) async {
            // SharedPreferences로부터 설정 로드
            final prefs = await SharedPreferences.getInstance();
            return SettingsViewModel(prefs);
          },
          initialData: SettingsViewModel(null),
          lazy: false,
        ),
      ],
      child: Builder(
        builder: (context) {
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
        
        // 메뉴 버튼
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortOptions(context),
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
  
  // 문서 목록 탭 빌드
  Widget _buildDocumentList() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.filteredDocuments.isEmpty) {
          return _buildEmptyState(
            '문서가 없습니다',
            '오른쪽 하단의 + 버튼을 눌러 문서를 추가하세요',
          );
        }
        
        return _buildDocumentGrid(viewModel.filteredDocuments, false);
      },
    );
  }
  
  // 즐겨찾기 탭 빌드
  Widget _buildFavoritesList() {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final favorites = viewModel.documents.where(
          (doc) => doc.favorites.isNotEmpty
        ).toList();
        
        if (favorites.isEmpty) {
          return _buildEmptyState(
            '즐겨찾기가 없습니다',
            '문서 보기에서 별표 아이콘을 눌러 즐겨찾기에 추가하세요',
          );
        }
        
        return _buildDocumentGrid(favorites, true);
      },
    );
  }
  
  // PDF 카드 그리드 빌드
  Widget _buildDocumentGrid(List<PDFDocument> documents, bool isFavorites) {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFavorites ? Icons.favorite_border : Icons.description,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isFavorites ? '즐겨찾기한 문서가 없습니다' : '문서가 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFavorites
                      ? 'PDF 뷰어에서 별표를 눌러 추가하세요'
                      : '+를 눌러 PDF를 추가하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MasonryGridView.count(
                crossAxisCount: _calculateColumns(context),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return _buildPDFCard(documents[index], context);
                },
              ),
            ),
            if (!Provider.of<SubscriptionService>(context).isPremium)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PlatformAdWidget(),
              ),
          ],
        );
      },
    );
  }
  
  // 화면 크기에 따른 그리드 컬럼 계산
  int _calculateColumns(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
  
  // 빈 상태 표시 위젯
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // PDF 카드 빌드
  Widget _buildPDFCard(PDFDocument document, BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(documentId: document.id),
            ),
          );
        },
        onLongPress: () {
          _showDocumentOptions(document, context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 영역
            AspectRatio(
              aspectRatio: 3/4,
              child: Container(
                color: Colors.grey[200],
                child: document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty
                    ? Image.network(
                        document.thumbnailPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            // 문서 정보 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 날짜
                  Text(
                    DateFormatter.formatDate(document.lastOpened),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 페이지 수
                  Row(
                    children: [
                      Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "${document.pageCount}페이지",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (document.favorites.isNotEmpty) ...[
                        const Spacer(),
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // PDF 옵션 메뉴 표시
  void _showDocumentOptions(PDFDocument document, BuildContext context) {
    final actionsViewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('열기'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerPage(documentId: document.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(context);
                dialogService.showRenameDialog(context, document.id, document.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('공유'),
              onTap: () {
                Navigator.pop(context);
                actionsViewModel.shareDocument(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('다운로드'),
              onTap: () {
                Navigator.pop(context);
                actionsViewModel.downloadDocument(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                dialogService.showDeleteConfirmDialog(context, document.id, document.title);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 정렬 메뉴 표시
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('이름 (A-Z)'),
                leading: const Icon(Icons.sort_by_alpha),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.nameAZ);
                },
              ),
              ListTile(
                title: const Text('이름 (Z-A)'),
                leading: const Icon(Icons.sort_by_alpha),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.nameZA);
                },
              ),
              ListTile(
                title: const Text('최근 본 순'),
                leading: const Icon(Icons.access_time),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.dateNewest);
                },
              ),
              ListTile(
                title: const Text('오래된 본 순'),
                leading: const Icon(Icons.access_time),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.dateOldest);
                },
              ),
              ListTile(
                title: const Text('페이지 수 많은 순'),
                leading: const Icon(Icons.filter_list),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.pageCountDesc);
                },
              ),
              ListTile(
                title: const Text('페이지 수 적은 순'),
                leading: const Icon(Icons.filter_list),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.pageCountAsc);
                },
              ),
              ListTile(
                title: const Text('추가한 날짜 최신순'),
                leading: const Icon(Icons.date_range),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.addedNewest);
                },
              ),
              ListTile(
                title: const Text('추가한 날짜 오래된순'),
                leading: const Icon(Icons.date_range),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setSortOption(SortOption.addedOldest);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 플로팅 액션 버튼 (문서 추가)
  Widget _buildFloatingActionButton(BuildContext context, DialogService dialogService) {
    final actionViewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    
    return FloatingActionButton(
      onPressed: () => _showAddDocumentOptions(context),
      child: const Icon(Icons.add),
    );
  }
  
  // 문서 추가 옵션 다이얼로그
  void _showAddDocumentOptions(BuildContext context) {
    final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    final dialogService = Provider.of<DialogService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('기기에서 PDF 선택'),
                  onTap: () async {
                    Navigator.pop(context);
                    final isSuccess = await viewModel.addDocumentFromDevice();
                    if (!isSuccess && context.mounted) {
                      dialogService.showErrorDialog(
                        context,
                        title: '오류',
                        message: viewModel.errorMessage ?? '문서 업로드 중 오류가 발생했습니다',
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('URL에서 PDF 추가'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddFromUrlDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('샘플 PDF 추가'),
                  onTap: () async {
                    Navigator.pop(context);
                    final isSuccess = await viewModel.addSamplePdf();
                    if (!isSuccess && context.mounted) {
                      dialogService.showErrorDialog(
                        context,
                        title: '오류',
                        message: viewModel.errorMessage ?? '샘플 PDF 추가 중 오류가 발생했습니다',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// URL 입력 다이얼로그 표시
  void _showAddFromUrlDialog(BuildContext context) {
    final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    final dialogService = Provider.of<DialogService>(context, listen: false);
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL에서 PDF 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'PDF URL',
                hintText: 'https://example.com/document.pdf',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '문서 이름 (선택사항)',
                hintText: '문서 이름을 입력하세요',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final name = nameController.text.trim();
              
              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL을 입력해주세요')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              bool isSuccess;
              if (name.isNotEmpty) {
                isSuccess = await viewModel.addPdfFromUrl(url, name);
              } else {
                isSuccess = await viewModel.addDocumentFromUrl(url);
              }
              
              if (!isSuccess && context.mounted) {
                dialogService.showErrorDialog(
                  context,
                  title: '오류',
                  message: viewModel.errorMessage ?? 'PDF 추가 중 오류가 발생했습니다',
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
  
  // 앱 드로워 빌드
  Widget _buildDrawer(BuildContext context) {
    return AppDrawer();
  }
} 