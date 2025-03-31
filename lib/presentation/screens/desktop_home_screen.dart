import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pdf_viewer_viewmodel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 데스크톱 홈 화면
class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({Key? key}) : super(key: key);

  @override
  _DesktopHomeScreenState createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  int _selectedIndex = 0;
  final List<String> _sectionTitles = ['홈', 'PDF 목록', '최근 문서', '설정'];

  Future<void> _pickPDF() async {
    // PDF 파일 선택 및 열기 로직
    try {
      // 파일 선택 로직 (웹, 데스크톱, 모바일 등 플랫폼에 따라 다름)
      if (kIsWeb) {
        // 웹 환경에서의 파일 선택
        // TODO: 웹 환경에서의 파일 선택 구현
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹 환경에서 파일 선택은 아직 구현되지 않았습니다.')),
        );
      } else {
        // 네이티브 환경에서의 파일 선택
        // TODO: 파일 피커 등을 사용하여 구현
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네이티브 환경에서 파일 선택은 아직 구현되지 않았습니다.')),
        );
      }
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
    final currentUser = authViewModel.currentUser;

    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onSelectedIndexChange: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.book),
          label: 'PDF 목록',
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          label: '최근 문서',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: '설정',
        ),
      ],
      appBar: AppBar(
        title: Text(_sectionTitles[_selectedIndex]),
        actions: [
          // 파일 열기 버튼
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'PDF 파일 열기',
            onPressed: _pickPDF,
          ),
          // URL에서 열기 버튼
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'URL에서 열기',
            onPressed: _openUrlDialog,
          ),
          // 프로필 메뉴
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? Text(currentUser?.email?.substring(0, 1).toUpperCase() ?? '?')
                  : null,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(currentUser?.email ?? '로그인 필요'),
                enabled: false,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('프로필 설정'),
                onTap: () {
                  // TODO: 프로필 설정 페이지로 이동
                },
              ),
              PopupMenuItem(
                child: const Text('로그아웃'),
                onTap: () async {
                  await authViewModel.signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: (_) {
        switch (_selectedIndex) {
          case 0:
            return _buildHomeSection();
          case 1:
            return _buildPdfListSection();
          case 2:
            return _buildRecentSection();
          case 3:
            return _buildSettingsSection();
          default:
            return _buildHomeSection();
        }
      },
      bodyRatio: .7,
      secondaryBody: (_) {
        return pdfViewModel.currentDocument != null
            ? _buildPdfViewerSection()
            : _buildSecondaryEmptyState();
      },
    );
  }

  // 홈 섹션
  Widget _buildHomeSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.menu_book,
                size: 120,
                color: Colors.blue,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF Learner에 오신 것을 환영합니다',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF 파일을 열어서 학습을 시작하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('PDF 파일 열기'),
                onPressed: _pickPDF,
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('URL에서 열기'),
                onPressed: _openUrlDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PDF 목록 섹션
  Widget _buildPdfListSection() {
    final pdfViewModel = Provider.of<PdfViewerViewModel>(context);
    final documents = pdfViewModel.documents;

    if (documents.isEmpty) {
      return const Center(
        child: Text('PDF 문서가 없습니다. PDF 파일을 추가해주세요.'),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          key: ValueKey('desktop_list_${document.id}'),
          leading: const Icon(Icons.picture_as_pdf),
          title: Text(document.title),
          subtitle: Text('${document.pageCount} 페이지 • ${_formatFileSize(document.fileSize)}'),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 문서 메뉴 구현
            },
          ),
          onTap: () async {
            await pdfViewModel.openDocument(document);
          },
        );
      },
    );
  }

  // 최근 문서 섹션
  Widget _buildRecentSection() {
    final pdfViewModel = Provider.of<PdfViewerViewModel>(context);
    final documents = pdfViewModel.documents;

    if (documents.isEmpty) {
      return const Center(
        child: Text('최근에 본 문서가 없습니다.'),
      );
    }

    // 최근 조회 시간순으로 정렬
    final sortedDocuments = [...documents]
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          AppLocalizations.of(context)!.recentDocuments,
          color: Colors.blueGrey.shade700,
        ),
        const SizedBox(height: 12),
        if (sortedDocuments.isEmpty)
          _buildEmptyState(
            message: AppLocalizations.of(context)!.noRecentDocuments,
            icon: Icons.history,
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedDocuments.length,
              itemBuilder: (context, index) {
                final document = sortedDocuments[index];
                return Container(
                  key: ValueKey('desktop_recent_${document.id}'),
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildDocumentCard(document),
                );
              },
            ),
          ),
      ],
    );
  }

  // 설정 섹션
  Widget _buildSettingsSection() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('계정 설정'),
          subtitle: const Text('이메일 및 프로필 관리'),
          onTap: () {
            // TODO: 계정 설정 페이지로 이동
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('테마 설정'),
          subtitle: const Text('앱 테마 및 색상 설정'),
          onTap: () {
            // TODO: 테마 설정 페이지로 이동
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('언어 설정'),
          subtitle: const Text('앱 언어 변경'),
          onTap: () {
            // TODO: 언어 설정 페이지로 이동
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('고급 설정'),
          subtitle: const Text('앱 성능 및 저장 공간 설정'),
          onTap: () {
            // TODO: 고급 설정 페이지로 이동
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('앱 정보'),
          subtitle: const Text('버전, 라이선스, 개인정보처리방침'),
          onTap: () {
            // TODO: 앱 정보 페이지로 이동
          },
        ),
      ],
    );
  }

  // PDF 뷰어 섹션
  Widget _buildPdfViewerSection() {
    final pdfViewModel = Provider.of<PdfViewerViewModel>(context);
    final document = pdfViewModel.currentDocument;

    if (document == null) {
      return _buildSecondaryEmptyState();
    }

    // PDF 뷰어 구현
    return Column(
      children: [
        // PDF 문서 제목 및 컨트롤 바
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                tooltip: '북마크 추가',
                onPressed: () {
                  // TODO: 북마크 추가 다이얼로그 구현
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                tooltip: '확대',
                onPressed: pdfViewModel.zoomIn,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                tooltip: '축소',
                onPressed: pdfViewModel.zoomOut,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '닫기',
                onPressed: pdfViewModel.closeDocument,
              ),
            ],
          ),
        ),
        
        // PDF 뷰어 영역
        Expanded(
          child: Center(
            child: Text('PDF 뷰어 영역 (${document.fileName})'),
            // TODO: 실제 PDF 뷰어 구현
          ),
        ),
        
        // 페이지 탐색 컨트롤
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '이전 페이지',
                onPressed: pdfViewModel.previousPage,
              ),
              Text('${pdfViewModel.currentPage + 1} / ${document.pageCount}'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: '다음 페이지',
                onPressed: pdfViewModel.nextPage,
              ),
            ],
          ),
        ),
      ],
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

  // 보조 영역 빈 상태 위젯
  Widget _buildSecondaryEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'PDF 문서를 선택하세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '왼쪽 패널에서 문서를 선택하면\n이 영역에 표시됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.black,
      ),
    );
  }

  Widget _buildEmptyState({String? message, IconData? icon}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon ?? Icons.error,
          size: 80,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          message ?? '데이터를 불러오는 중 오류가 발생했습니다',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            document.thumbnailUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${document.pageCount} 페이지 • ${_formatFileSize(document.fileSize)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 