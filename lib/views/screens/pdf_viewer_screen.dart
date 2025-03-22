import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/pdf_view_model.dart';
import '../../models/pdf_document.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// PDF 뷰어 화면
class PdfViewerScreen extends StatefulWidget {
  final PdfDocument document;

  const PdfViewerScreen({Key? key, required this.document}) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isToolbarVisible = true;
  bool _isBookmarkPanelOpen = false;
  bool _isAnnotationPanelOpen = false;
  final TextEditingController _bookmarkTitleController = TextEditingController();
  final TextEditingController _annotationTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // PDF 문서 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
      pdfViewModel.openDocument(widget.document);
    });
  }

  @override
  void dispose() {
    _bookmarkTitleController.dispose();
    _annotationTextController.dispose();
    super.dispose();
  }

  // 툴바 토글
  void _toggleToolbar() {
    setState(() {
      _isToolbarVisible = !_isToolbarVisible;
    });
  }

  // 북마크 패널 토글
  void _toggleBookmarkPanel() {
    setState(() {
      _isBookmarkPanelOpen = !_isBookmarkPanelOpen;
      if (_isBookmarkPanelOpen) {
        _isAnnotationPanelOpen = false;
      }
    });
  }

  // 주석 패널 토글
  void _toggleAnnotationPanel() {
    setState(() {
      _isAnnotationPanelOpen = !_isAnnotationPanelOpen;
      if (_isAnnotationPanelOpen) {
        _isBookmarkPanelOpen = false;
      }
    });
  }

  // 북마크 추가 다이얼로그
  Future<void> _showAddBookmarkDialog() async {
    final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
    _bookmarkTitleController.text = '페이지 ${pdfViewModel.currentPage + 1}';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('북마크 추가'),
          content: TextField(
            controller: _bookmarkTitleController,
            decoration: const InputDecoration(labelText: '북마크 제목'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('추가'),
              onPressed: () {
                if (_bookmarkTitleController.text.isNotEmpty) {
                  // 북마크 추가
                  pdfViewModel.addBookmark(_bookmarkTitleController.text);
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('북마크가 추가되었습니다: ${_bookmarkTitleController.text}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 주석 추가 다이얼로그
  Future<void> _showAddAnnotationDialog() async {
    final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
    _annotationTextController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('주석 추가'),
          content: TextField(
            controller: _annotationTextController,
            decoration: const InputDecoration(labelText: '주석 내용'),
            autofocus: true,
            maxLines: 5,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('추가'),
              onPressed: () {
                if (_annotationTextController.text.isNotEmpty) {
                  // 주석 추가
                  pdfViewModel.addAnnotation(
                    _annotationTextController.text,
                    const Rect.fromLTWH(100, 100, 200, 100), // 임시 위치
                    Colors.yellow,
                  );
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주석이 추가되었습니다')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfViewModel = Provider.of<PdfViewModel>(context);
    final document = pdfViewModel.currentDocument ?? widget.document;

    return Scaffold(
      appBar: _isToolbarVisible
          ? AppBar(
              title: Text(document.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // 북마크 버튼
                IconButton(
                  icon: Icon(
                    _isBookmarkPanelOpen
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _isBookmarkPanelOpen ? Colors.yellow : null,
                  ),
                  tooltip: '북마크',
                  onPressed: _toggleBookmarkPanel,
                ),
                
                // 주석 버튼
                IconButton(
                  icon: Icon(
                    _isAnnotationPanelOpen
                        ? Icons.comment
                        : Icons.comment_outlined,
                    color: _isAnnotationPanelOpen ? Colors.yellow : null,
                  ),
                  tooltip: '주석',
                  onPressed: _toggleAnnotationPanel,
                ),
                
                // 검색 버튼
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '검색',
                  onPressed: () {
                    // TODO: 검색 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검색 기능은 아직 구현되지 않았습니다')),
                    );
                  },
                ),
                
                // 더보기 메뉴
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      // 공유 기능
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('공유 기능은 아직 구현되지 않았습니다')),
                      );
                    } else if (value == 'print') {
                      // 인쇄 기능
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('인쇄 기능은 아직 구현되지 않았습니다')),
                      );
                    } else if (value == 'info') {
                      // 문서 정보
                      _showDocumentInfo();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('공유하기'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'print',
                      child: Text('인쇄하기'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'info',
                      child: Text('문서 정보'),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // PDF 뷰어 영역
            GestureDetector(
              onTap: _toggleToolbar,
              child: _buildPdfViewer(context, pdfViewModel, document),
            ),
            
            // 북마크 패널
            if (_isBookmarkPanelOpen)
              _buildBookmarkPanel(context, pdfViewModel, document),
            
            // 주석 패널
            if (_isAnnotationPanelOpen)
              _buildAnnotationPanel(context, pdfViewModel, document),
            
            // 하단 네비게이션 바
            if (_isToolbarVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNavigationBar(context, pdfViewModel, document),
              ),
          ],
        ),
      ),
      floatingActionButton: _isToolbarVisible
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 북마크 추가 버튼
                FloatingActionButton(
                  heroTag: 'bookmark_fab',
                  onPressed: _showAddBookmarkDialog,
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.bookmark_add),
                ),
                const SizedBox(width: 16),
                
                // 주석 추가 버튼
                FloatingActionButton(
                  heroTag: 'annotation_fab',
                  onPressed: _showAddAnnotationDialog,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add_comment),
                ),
              ],
            )
          : null,
    );
  }

  // PDF 뷰어 위젯
  Widget _buildPdfViewer(
      BuildContext context, PdfViewModel pdfViewModel, PdfDocument document) {
    // TODO: 실제 PDF 뷰어 구현
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${document.fileName} - 페이지 ${pdfViewModel.currentPage + 1}/${document.pageCount}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          const Text('PDF 뷰어 영역 (실제 구현 필요)'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pdfViewModel.currentPage > 0
                    ? pdfViewModel.previousPage
                    : null,
                child: const Text('이전 페이지'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: pdfViewModel.currentPage < document.pageCount - 1
                    ? pdfViewModel.nextPage
                    : null,
                child: const Text('다음 페이지'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 북마크 패널 위젯
  Widget _buildBookmarkPanel(
      BuildContext context, PdfViewModel pdfViewModel, PdfDocument document) {
    final bookmarks = document.bookmarks;

    return Positioned(
      top: 0,
      right: 0,
      bottom: _isToolbarVisible ? 60 : 0,
      width: 280,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  const Text(
                    '북마크',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleBookmarkPanel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (bookmarks.isEmpty)
              Expanded(
                child: const Center(
                  child: Text('북마크가 없습니다'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return ListTile(
                      title: Text(bookmark.title),
                      subtitle: Text('페이지 ${bookmark.pageNumber + 1}'),
                      leading: const Icon(Icons.bookmark),
                      onTap: () {
                        pdfViewModel.goToPage(bookmark.pageNumber);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          pdfViewModel.removeBookmark(bookmark);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('북마크가 삭제되었습니다')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 주석 패널 위젯
  Widget _buildAnnotationPanel(
      BuildContext context, PdfViewModel pdfViewModel, PdfDocument document) {
    final annotations = document.annotations;

    return Positioned(
      top: 0,
      right: 0,
      bottom: _isToolbarVisible ? 60 : 0,
      width: 280,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  const Text(
                    '주석',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleAnnotationPanel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (annotations.isEmpty)
              Expanded(
                child: const Center(
                  child: Text('주석이 없습니다'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: annotations.length,
                  itemBuilder: (context, index) {
                    final annotation = annotations[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.comment, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '페이지 ${annotation.pageNumber + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () {
                                    pdfViewModel.removeAnnotation(annotation);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('주석이 삭제되었습니다')),
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(annotation.text),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(annotation.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 하단 네비게이션 바
  Widget _buildBottomNavigationBar(
      BuildContext context, PdfViewModel pdfViewModel, PdfDocument document) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // 이전 페이지 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: pdfViewModel.currentPage > 0
                ? pdfViewModel.previousPage
                : null,
          ),
          
          // 페이지 슬라이더
          Expanded(
            child: Slider(
              value: (pdfViewModel.currentPage + 1).toDouble(),
              min: 1,
              max: document.pageCount.toDouble(),
              divisions: document.pageCount > 1 ? document.pageCount - 1 : 1,
              label: '${pdfViewModel.currentPage + 1}',
              onChanged: (value) {
                pdfViewModel.goToPage(value.toInt() - 1);
              },
            ),
          ),
          
          // 다음 페이지 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: pdfViewModel.currentPage < document.pageCount - 1
                ? pdfViewModel.nextPage
                : null,
          ),
          
          // 페이지 번호 텍스트
          Text(
            '${pdfViewModel.currentPage + 1} / ${document.pageCount}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 문서 정보 다이얼로그
  void _showDocumentInfo() {
    final pdfViewModel = Provider.of<PdfViewModel>(context, listen: false);
    final document = pdfViewModel.currentDocument ?? widget.document;

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

  // 정보 행 위젯
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