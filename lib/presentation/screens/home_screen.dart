import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'document_list_screen.dart';
import 'pdf_viewer_screen.dart';
import '../../core/localization/app_localizations.dart';
import 'package:get_it/get_it.dart';

/// 반응형 홈 스크린
/// 
/// 화면 크기에 따라 모바일/데스크톱 버전을 선택하여 표시합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 탭 인덱스 및 타이틀 관리
  int _selectedTabIndex = 0;
  final List<String> _tabTitles = ['홈', '문서', '북마크', '설정'];
  
  // 탭에 해당하는 화면 목록
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    // 페이지 컨텐츠 초기화
    _pages = [
      const HomeTab(),
      const DocumentListScreen(),
      const Center(child: Text('북마크 화면')),
      const Center(child: Text('설정 화면')),
    ];
    
    // PDF 문서 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
      pdfViewModel.loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 필요한 뷰모델 가져오기
    final authViewModel = Provider.of<AuthViewModel>(context);
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final pdfViewModel = Provider.of<PDFViewModel>(context);
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(_tabTitles[_selectedTabIndex], 
                  style: theme.textTheme.titleLarge),
        actions: [
          // 테마 변경 버튼
          IconButton(
            icon: Icon(
              themeViewModel.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.primary,
            ),
            onPressed: themeViewModel.toggleTheme,
            tooltip: '테마 변경',
          ),
          // 설정 버튼
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.primary),
            onPressed: () {
              setState(() {
                _selectedTabIndex = 3; // 설정 탭으로 이동
              });
            },
            tooltip: '설정',
          ),
        ],
      ),
      // 본문 영역 - 선택된 탭에 따라 다른 화면 표시
      body: _pages[_selectedTabIndex],
      // 하단 네비게이션 바
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: colorScheme.surfaceTint,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.home, color: colorScheme.primary),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.description, color: colorScheme.primary),
            label: '문서',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.bookmarks, color: colorScheme.primary),
            label: '북마크',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            selectedIcon: Icon(Icons.settings, color: colorScheme.primary),
            label: '설정',
          ),
        ],
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_add_pdf',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () async {
          try {
            await pdfViewModel.pickAndAddPDF();
            if (pdfViewModel.error != null && pdfViewModel.error!.isNotEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pdfViewModel.error!),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF 추가 중 오류가 발생했습니다: $e'),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        tooltip: 'PDF 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 홈 탭 위젯
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfViewModel = Provider.of<PDFViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return pdfViewModel.isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색 바
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: colorScheme.surface,
                    shadowColor: colorScheme.shadow.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '문서 검색...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                              ),
                              style: TextStyle(color: colorScheme.onSurface),
                              onSubmitted: (value) {
                                // 검색 기능 실행
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 최근 문서 섹션
                  _buildSectionTitle(context, '최근 문서'),
                  if (pdfViewModel.documents.isEmpty)
                    _buildEmptyState(context, '최근에 열어본 문서가 없습니다', Icons.history_outlined)
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pdfViewModel.documents.length > 5 
                            ? 5 
                            : pdfViewModel.documents.length,
                        itemBuilder: (context, index) {
                          final document = pdfViewModel.documents[index];
                          return Padding(
                            key: ValueKey('recent_${document.id}'),
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildDocumentCard(context, document),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 즐겨찾기 섹션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(context, '즐겨찾기'),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        onPressed: () {
                          // 모든 즐겨찾기 보기
                        },
                        child: const Text('더 보기'),
                      ),
                    ],
                  ),
                  
                  _buildFavoritesList(context, pdfViewModel),
                  
                  const SizedBox(height: 24),
                  
                  // 통계 섹션
                  _buildSectionTitle(context, '나의 학습 통계'),
                  _buildStatisticsCard(context),
                ],
              ),
            ),
          );
  }
  
  // 섹션 제목 위젯
  Widget _buildSectionTitle(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // 문서 없음 상태 위젯
  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // 즐겨찾기 목록 위젯
  Widget _buildFavoritesList(BuildContext context, PDFViewModel viewModel) {
    final List favoriteDocuments = viewModel.documents
        .where((doc) => doc.isFavorite)
        .toList();
    
    if (favoriteDocuments.isEmpty) {
      return _buildEmptyState(
        context, 
        '즐겨찾기한 문서가 없습니다', 
        Icons.favorite_border
      );
    }
    
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: favoriteDocuments.length > 5 ? 5 : favoriteDocuments.length,
        itemBuilder: (context, index) {
          final document = favoriteDocuments[index];
          return Padding(
            key: ValueKey('favorite_${document.id}'),
            padding: const EdgeInsets.only(right: 12),
            child: _buildDocumentCard(context, document),
          );
        },
      ),
    );
  }
  
  // 문서 카드 위젯
  Widget _buildDocumentCard(BuildContext context, dynamic document) {
    final viewModel = Provider.of<PDFViewModel>(context, listen: false);
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () async {
        try {
          viewModel.setSelectedDocument(document);
          final pdfBytes = await viewModel.getPDFBytes(document.filePath);
          
          if (context.mounted && pdfBytes != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(
                  document: document,
                  pdfBytes: pdfBytes,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF 열기 오류: $e')),
            );
          }
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: document.thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            document.thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                document.title ?? '제목 없음',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 통계 카드 위젯
  Widget _buildStatisticsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context, 
                  '읽은 문서', 
                  '12', 
                  Icons.menu_book, 
                  colorScheme.primary
                ),
                _buildStatItem(
                  context, 
                  '북마크', 
                  '36', 
                  Icons.bookmark, 
                  colorScheme.tertiary
                ),
                _buildStatItem(
                  context, 
                  '학습 시간', 
                  '24h', 
                  Icons.timer, 
                  colorScheme.secondary
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.65,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '이번 달 목표의 65% 달성',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 통계 항목 위젯
  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
} 