import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

import '../../domain/models/pdf_document.dart';
import '../../domain/models/pdf_bookmark.dart';
import '../widgets/bookmark_dialog.dart';
import '../viewmodels/pdf_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_theme.dart';

/// PDF 문서 뷰어 화면
class PdfViewerScreen extends StatefulWidget {
  /// 표시할 PDF 문서
  final PDFDocument document;
  
  /// PDF 바이트 데이터
  final Uint8List pdfBytes;
  
  /// 생성자
  const PdfViewerScreen({
    Key? key,
    required this.document,
    required this.pdfBytes,
  }) : super(key: key);
  
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  /// PDF 제어 컨트롤러
  late PdfViewerController _pdfViewerController;
  
  /// PDF 뷰어 키 - 정적으로 선언하여 여러 인스턴스 생성 방지
  static final GlobalKey<SfPdfViewerState> _pdfViewerScreenKey = GlobalKey();
  
  /// 현재 페이지
  int _currentPage = 1;
  
  bool _isBookmarksViewVisible = false;
  bool _isAnnotationMode = false;
  bool _isSearchViewVisible = false;
  TextEditingController _searchTextController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    
    // 이전에 읽던 페이지로 이동
    if (widget.document.currentPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfViewerController.jumpToPage(widget.document.currentPage);
      });
    }
  }
  
  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 반응형 디자인을 위한 화면 크기 체크
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200; // 넓은 화면에서만 3단 레이아웃 사용
    
    // 뷰모델 접근
    final pdfViewModel = Provider.of<PDFViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          // 검색 버튼
          IconButton(
            icon: Icon(_isSearchViewVisible ? Icons.close : Icons.search),
            tooltip: '검색',
            onPressed: () {
              setState(() {
                _isSearchViewVisible = !_isSearchViewVisible;
                if (!_isSearchViewVisible) {
                  _pdfViewerController.clearSelection();
                }
              });
            },
          ),
          // 북마크 버튼
          IconButton(
            icon: Icon(_isBookmarksViewVisible 
                ? Icons.bookmark 
                : Icons.bookmark_border),
            tooltip: '북마크',
            onPressed: () {
              setState(() {
                _isBookmarksViewVisible = !_isBookmarksViewVisible;
              });
            },
          ),
          // 주석 모드 버튼
          IconButton(
            icon: Icon(_isAnnotationMode 
                ? Icons.edit_note 
                : Icons.edit_note_outlined),
            tooltip: '주석 모드',
            onPressed: () {
              setState(() {
                _isAnnotationMode = !_isAnnotationMode;
              });
            },
          ),
          // 더보기 버튼
          PopupMenuButton<String>(
            tooltip: '더보기',
            onSelected: (value) {
              switch (value) {
                case 'share':
                  // 공유 기능
                  break;
                case 'download':
                  // 다운로드 기능
                  break;
                case 'print':
                  // 인쇄 기능
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('공유'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('다운로드'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 8),
                    Text('인쇄'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 미회원 만료 정보 배너
          if (pdfViewModel.isGuestUser)
            _buildGuestExpirationBanner(pdfViewModel, authViewModel),
          
          // 검색 뷰
          if (_isSearchViewVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchTextController,
                      decoration: const InputDecoration(
                        hintText: '검색어를 입력하세요',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _pdfViewerController.searchText(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_before),
                    onPressed: () {
                      _pdfViewerController.searchText(
                        _searchTextController.text,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_next),
                    onPressed: () {
                      _pdfViewerController.searchText(
                        _searchTextController.text,
                      );
                    },
                  ),
                ],
              ),
            ),
          
          // PDF 뷰어
          Expanded(
            child: SfPdfViewer.memory(
              widget.pdfBytes,
              key: _pdfViewerScreenKey,
              controller: _pdfViewerController,
              canShowPasswordDialog: true,
              onPageChanged: (PdfPageChangedDetails details) {
                // 현재 페이지 정보 업데이트
                final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
                pdfViewModel.saveLastReadPage(widget.document.id, details.newPageNumber);
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                // PDF 문서 로드 완료 시 처리
                final pageCount = details.document.pages.count;
                final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
                
                if (pageCount != widget.document.pageCount) {
                  // 페이지 수 업데이트
                  final updatedDoc = widget.document.copyWith(pageCount: pageCount);
                  pdfViewModel.setSelectedDocument(updatedDoc);
                }
              },
            ),
          ),
        ],
      ),
      // 하단 페이지 네비게이션 바
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이전 페이지 버튼
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: () {
                if (_pdfViewerController.pageNumber > 1) {
                  _pdfViewerController.previousPage();
                }
              },
            ),
            // 페이지 정보
            Text(
              '${_pdfViewerController.pageNumber} / ${widget.document.pageCount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // 다음 페이지 버튼
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () {
                if (_pdfViewerController.pageNumber < widget.document.pageCount) {
                  _pdfViewerController.nextPage();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// 미회원 만료 정보 배너
  Widget _buildGuestExpirationBanner(PDFViewModel pdfViewModel, AuthViewModel authViewModel) {
    final expirationDays = pdfViewModel.getCurrentDocumentExpirationDays();
    final isExpired = pdfViewModel.isCurrentDocumentExpired();
    
    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Colors.red.shade100,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '이 문서는 만료되었습니다. 회원가입 후 문서를 영구적으로 저장하세요.',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                // TODO: 회원가입 화면 이동 구현
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('회원가입'),
            ),
          ],
        ),
      );
    } else if (expirationDays != null && expirationDays <= 2) {
      // 만료 예정 배너
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '이 문서는 $expirationDays일 후에 삭제됩니다. 회원가입하여 문서를 영구적으로 저장하세요.',
                style: TextStyle(color: Colors.amber.shade800),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                // TODO: 회원가입 화면 이동 구현
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('회원가입'),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // 만료가 멀었거나 회원인 경우 표시하지 않음
    }
  }
} 