import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/pdf_viewmodel.dart';
import 'pdf_viewer_page.dart';

/// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 렌더링된 후 PDF 목록을 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PDFViewModel>(context, listen: false).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, PDFViewModel>(
      builder: (context, authViewModel, pdfViewModel, child) {
        // 미가입자 모드가 아니고 인증되지 않은 상태이면 로그인 페이지로 이동
        if (!authViewModel.isGuestMode && authViewModel.isUnauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
        
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
        
        // 로딩 상태이면 로딩 인디케이터 표시
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // 인증된 상태 또는 게스트 모드이면 홈 화면 표시
        if (authViewModel.isAuthenticated || authViewModel.isGuestMode) {
          return Scaffold(
            backgroundColor: Color(0xFFF5F7FA), // 배경색 변경 - 연한 회색빛 배경
            // 앱바를 UPDF 스타일로 변경
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SafeArea(
                  child: Row(
                    children: [
                      // 로고 및 앱 이름
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5D5FEF),  // 메인 컬러 - 보라색
                              const Color(0xFF3D6AFF),  // 서브 컬러 - 파란색
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PDF 학습기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          background: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                const Color(0xFF5D5FEF),  
                                const Color(0xFF3D6AFF),
                              ],
                            ).createShader(const Rect.fromLTWH(0, 0, 150, 70)),
                        ),
                      ),
                      const Spacer(),
                      
                      // 기능 버튼들 - UPDF 스타일의 버튼들
                      _buildAppBarButton(
                        icon: Icons.search_rounded,
                        label: '검색',
                        onTap: () {
                          // 검색 기능 구현
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildAppBarButton(
                        icon: Icons.add_rounded,
                        label: '추가',
                        onTap: () {
                          pdfViewModel.pickAndAddPDF();
                        },
                        isPrimary: true,
                      ),
                      const SizedBox(width: 8),
                      
                      // 로그인/계정 정보 버튼
                      if (authViewModel.isAuthenticated && !authViewModel.isGuestMode)
                        // 로그인된 상태일 때 사용자 정보 표시
                        _buildUserProfileButton(context, authViewModel)
                      else
                        // 게스트 모드일 때 로그인 버튼 표시
                        _buildAppBarButton(
                          icon: Icons.login_rounded,
                          label: '로그인',
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                // 게스트 모드 배너 - 더 매력적인 디자인으로 변경
                if (authViewModel.isGuestMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5D5FEF).withOpacity(0.8),
                            const Color(0xFF3D6AFF).withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '체험 모드로 사용 중입니다',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '무료로 기본 기능을 사용해보세요',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            onPressed: () {
                              _showGuestModeRestrictionDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // 상단에 카테고리 선택 바 추가 (구글 드라이브 스타일)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip('전체 문서', true),
                        _buildCategoryChip('최근 문서', false),
                        _buildCategoryChip('즐겨찾기', false),
                        _buildCategoryChip('공유 받은 문서', false),
                      ],
                    ),
                  ),
                ),
                
                // PDF 목록 표시 - 구글 드라이브 스타일의 그리드
                Expanded(
                  child: pdfViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF5D5FEF)),
                      ))
                    : pdfViewModel.documents.isEmpty
                      ? _buildEmptyView(pdfViewModel)
                      : _buildDriveStyleGrid(pdfViewModel, authViewModel),
                ),
              ],
            ),
            // 플로팅 액션 버튼 - 구글 드라이브 스타일 + UPDF 색상
            floatingActionButton: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5D5FEF),
                    const Color(0xFF3D6AFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D5FEF).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  pdfViewModel.pickAndAddPDF();
                },
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          );
        }
        
        // 기본적으로 로딩 인디케이터 표시
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
  
  // 카테고리 선택 칩 위젯
  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF5D5FEF).withOpacity(0.1) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF5D5FEF) 
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? const Color(0xFF5D5FEF) 
                : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  // 빈 문서 상태일 때 표시할 위젯
  Widget _buildEmptyView(PDFViewModel pdfViewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF5D5FEF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file_outlined, 
              size: 80, 
              color: const Color(0xFF5D5FEF)
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '문서가 없습니다',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PDF를 추가해서 시작해보세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('PDF 추가하기', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D5FEF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () {
              pdfViewModel.pickAndAddPDF();
            },
          ),
        ],
      ),
    );
  }
  
  // 구글 드라이브 스타일의 그리드 뷰 구현
  Widget _buildDriveStyleGrid(PDFViewModel pdfViewModel, AuthViewModel authViewModel) {
    // 레이아웃을 좀 더 반응형으로 만들기
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 4 : 2;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: pdfViewModel.documents.length,
      itemBuilder: (context, index) {
        final document = pdfViewModel.documents[index];
        
        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // 게스트 모드에서는 한 번에 한 개의 문서만 볼 수 있음
              if (authViewModel.isGuestMode && pdfViewModel.hasOpenDocument) {
                _showGuestModeRestrictionDialog(context);
              } else {
                // PDF 뷰어로 이동
                pdfViewModel.setOpenDocument(true);
                pdfViewModel.setSelectedDocument(document);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(document: document)
                  ),
                ).then((_) {
                  // 뷰어에서 돌아오면 상태 업데이트
                  pdfViewModel.loadDocuments();
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일 부분 - 구글 드라이브 스타일로 변경
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // PDF 첫 페이지를 썸네일로 사용
                      FutureBuilder<Widget>(
                        future: _getPDFThumbnail(document),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && 
                              snapshot.hasData) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: snapshot.data!,
                            );
                          } else {
                            // 로딩 중이거나 에러 상태일 때의 UI
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: snapshot.connectionState == ConnectionState.waiting
                                    ? CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          const Color(0xFF5D5FEF).withOpacity(0.5),
                                        ),
                                        strokeWidth: 2,
                                      )
                                    : Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 48,
                                        color: const Color(0xFF5D5FEF).withOpacity(0.6),
                                      ),
                              ),
                            );
                          }
                        },
                      ),
                      // 즐겨찾기 아이콘
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (authViewModel.isGuestMode) {
                              _showGuestModeRestrictionDialog(context);
                            } else {
                              pdfViewModel.toggleFavorite(document.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              document.isFavorite ? Icons.star : Icons.star_border,
                              size: 18,
                              color: document.isFavorite ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 문서 정보 - 구글 드라이브 스타일
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${document.pageCount}페이지',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(document.readingProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5D5FEF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 진행률 표시
                      LinearProgressIndicator(
                        value: document.readingProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF5D5FEF)),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // PDF 썸네일을 가져오는 함수
  Future<Widget> _getPDFThumbnail(dynamic document) async {
    try {
      // 파일이 있는지 확인
      final file = File(document.filePath);
      final exists = await file.exists();
      
      if (exists) {
        // 파일 경로가 유효한 경우
        final pdfViewerController = PdfViewerController();
        
        return SfPdfViewer.file(
          file,
          pageSpacing: 0,
          initialPageNumber: 1,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          enableDoubleTapZooming: false,
          enableTextSelection: false,
          interactionMode: PdfInteractionMode.pan,
          controller: pdfViewerController,
          onPageChanged: (PdfPageChangedDetails details) {
            // 첫 페이지만 보여주기
            if (details.newPageNumber != 1) {
              // 직접 컨트롤러 사용
              pdfViewerController.jumpToPage(1);
            }
          },
        );
      } else if (document.thumbnailUrl != null && document.thumbnailUrl!.isNotEmpty) {
        // 썸네일 URL이 있는 경우
        return Image.network(
          document.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackThumbnail(document);
          },
        );
      } else {
        // 둘 다 없는 경우 대체 썸네일
        return _buildFallbackThumbnail(document);
      }
    } catch (e) {
      // 오류 발생 시 대체 썸네일
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
      child: Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
  
  // 게스트 모드 제한 대화상자 표시 - 현대적인 디자인으로 개선
  void _showGuestModeRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('체험 모드 안내'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '체험 모드에서는 다음 기능이 제한됩니다:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.book, '한 번에 최대 1개 PDF 문서 보기'),
            _buildFeatureItem(Icons.zoom_in, '기본 PDF 뷰어 기능만 사용 가능'),
            _buildFeatureItem(Icons.cloud_off, '문서 영구 저장 불가'),
            _buildFeatureItem(Icons.search, '기본 검색 기능만 사용 가능'),
            _buildFeatureItem(Icons.psychology, 'AI 기능 사용 불가'),
            const SizedBox(height: 16),
            const Text('회원가입하시면 모든 기능을 이용하실 수 있습니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }
  
  // 기능 아이템을 표시하는 위젯
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  // UPDF 스타일의 앱바 버튼
  Widget _buildAppBarButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isPrimary 
            ? LinearGradient(
                colors: [
                  const Color(0xFF5D5FEF),
                  const Color(0xFF3D6AFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: isPrimary ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isPrimary)
              BoxShadow(
                color: const Color(0xFF5D5FEF).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 사용자 프로필 정보 버튼
  Widget _buildUserProfileButton(BuildContext context, AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    final userName = user?.displayName ?? '사용자';
    final userEmail = user?.email ?? '';
    
    return InkWell(
      onTap: () {
        _showUserProfileMenu(context, authViewModel);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF5D5FEF).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5D5FEF),
                    const Color(0xFF3D6AFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (userEmail.isNotEmpty)
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 사용자 프로필 메뉴 표시
  void _showUserProfileMenu(BuildContext context, AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    final isPremium = user?.isPremium ?? false; // 프리미엄 여부 확인
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 사용자 정보 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5D5FEF).withOpacity(0.1),
                      const Color(0xFF3D6AFF).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5D5FEF),
                            const Color(0xFF3D6AFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName != null && user!.displayName!.isNotEmpty 
                              ? user.displayName![0].toUpperCase() 
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.displayName ?? '사용자',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFFD700),
                                        const Color(0xFFFFA500),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 메뉴 아이템들
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.grey.shade700),
                title: const Text('프로필 설정'),
                onTap: () {
                  Navigator.pop(context);
                  // 프로필 설정 화면으로 이동
                },
              ),
              if (!isPremium)
                ListTile(
                  leading: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
                  title: const Text('프리미엄으로 업그레이드'),
                  subtitle: const Text('더 많은 기능을 사용해보세요'),
                  onTap: () {
                    Navigator.pop(context);
                    // 프리미엄 구독 화면으로 이동
                  },
                ),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: Colors.grey.shade700),
                title: const Text('설정'),
                onTap: () {
                  Navigator.pop(context);
                  // 설정 화면으로 이동
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.grey.shade700),
                title: const Text('도움말'),
                onTap: () {
                  Navigator.pop(context);
                  // 도움말 화면으로 이동
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  authViewModel.signOut();
                  // 로그아웃 후 로그인 화면으로 이동
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 더보기 메뉴 표시
  void _showMoreMenu(BuildContext context, AuthViewModel authViewModel) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, 60), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: [
        PopupMenuItem(
          child: _buildMenuItem(Icons.person_rounded, '계정 관리'),
          onTap: () {
            if (authViewModel.isGuestMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamed(context, '/login');
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showUserProfileMenu(context, authViewModel);
              });
            }
          },
        ),
        PopupMenuItem(
          child: _buildMenuItem(Icons.settings_rounded, '설정'),
          onTap: () {},
        ),
        PopupMenuItem(
          child: _buildMenuItem(Icons.help_outline_rounded, '도움말'),
          onTap: () {},
        ),
        if (!authViewModel.isGuestMode)
          PopupMenuItem(
            child: _buildMenuItem(Icons.logout_rounded, '로그아웃'),
            onTap: () {
              authViewModel.signOut();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/');
              });
            },
          ),
      ],
    );
  }
  
  // 메뉴 아이템 위젯
  Widget _buildMenuItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
} 