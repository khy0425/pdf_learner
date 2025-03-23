import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/platform_ad_widget.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
// dart:html는 웹에서만 임포트
import 'dart:html' if (dart.library.io) './web_stub_html.dart' as html;
// ui 네임스페이스도 조건부로 임포트
import 'dart:ui' as ui;
import '../models/pdf_document.dart';
import '../services/subscription_service.dart';
import '../viewmodels/pdf_viewer_viewmodel.dart';

// 광고 유형 정의
enum AdType { banner, interstitial, rewarded }

/// PDF 문서 뷰어 페이지
class PdfViewerPage extends StatefulWidget {
  final PDFDocument document;
  final String? filePath;
  final String? title;
  final bool showAds;
  final bool showRewardButton;
  
  const PdfViewerPage({
    Key? key,
    required this.document,
    this.filePath,
    this.title,
    this.showAds = true,
    this.showRewardButton = false,
  }) : super(key: key);
  
  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerViewModel _viewModel;
  bool _isLoading = true;
  String? _errorMessage;
  String? _viewerId;
  
  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<PdfViewerViewModel>(context, listen: false);
    _initDocument();
    
    if (kIsWeb) {
      _setupWebViewer();
    }
  }
  
  /// 문서 초기화
  Future<void> _initDocument() async {
    await _viewModel.loadDocument(widget.document);
  }
  
  /// 웹 뷰어 설정
  void _setupWebViewer() {
    try {
      // 고유한 ID 생성
      final viewerId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';
      
      if (kIsWeb) {
        String pdfUrl = widget.document.path;
        
        // URL이 유효한지 확인
        if (pdfUrl.isEmpty) {
          setState(() {
            _errorMessage = 'PDF 경로가 유효하지 않습니다.';
            _isLoading = false;
          });
          return;
        }
        
        // PDF URL 로깅
        debugPrint('PDF URL: $pdfUrl');
        
        // Google PDF 뷰어 사용
        final googleViewerUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true';
        
        // iframe 요소 생성
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..src = googleViewerUrl;
        
        // viewType 등록
        ui.platformViewRegistry.registerViewFactory(viewerId, (int viewId) => iframe);
        
        setState(() {
          _viewerId = viewerId;
          _isLoading = false;
        });
      } else {
        setState(() {
          _viewerId = viewerId;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '웹 뷰어 설정 중 오류: $e';
        _isLoading = false;
      });
      debugPrint('웹 뷰어 설정 중 오류: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? widget.document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              _showBookmarksDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showReaderSettingsDialog();
            },
          ),
        ],
      ),
      body: _buildPdfViewer(),
    );
  }
  
  /// PDF 뷰어 구축
  Widget _buildPdfViewer() {
    final isPremium = Provider.of<SubscriptionService>(context).isPremium;
    
    return Center(
      child: Column(
        children: [
          Expanded(
            child: _buildPdfView(),
          ),
          if (!isPremium && widget.showAds)
            Container(
              height: 50,
              color: Colors.grey[200],
              child: const Center(
                child: Text('광고 영역'),
              ),
            ),
        ],
      ),
    );
  }
  
  /// PDF 뷰 구축
  Widget _buildPdfView() {
    // 웹 플랫폼과 네이티브 플랫폼에 따라 다르게 처리
    if (kIsWeb) {
      // 웹에서는 iframe을 사용하여 PDF 표시
      return _buildWebPdfView();
    } else {
      // 네이티브 앱에서는 기본 뷰어 사용
      return _buildNativePdfView();
    }
  }
  
  /// 웹에서 PDF 뷰어 위젯 생성
  Widget _buildWebPdfView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _setupWebViewer();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    if (_viewerId != null) {
      // 웹에서는 HtmlElementView 사용
      if (kIsWeb) {
        return HtmlElementView(viewType: _viewerId!);
      } else {
        return Center(
          child: Text('웹 환경에서만 지원됩니다: ${widget.document.path}'),
        );
      }
    } else {
      return const Center(
        child: Text('웹 뷰어 설정 오류'),
      );
    }
  }
  
  /// 네이티브에서 PDF 뷰어 위젯 생성
  Widget _buildNativePdfView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initDocument();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    try {
      return Center(
        child: Text('네이티브 PDF 뷰어: ${widget.document.path}'),
      );
    } catch (e) {
      return Center(
        child: Text('PDF 로드 오류: $e'),
      );
    }
  }
  
  /// 북마크 대화상자 표시
  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('북마크'),
          content: const SizedBox(
            width: 300,
            height: 300,
            child: Center(
              child: Text('북마크 목록'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
  
  /// 리더 설정 대화상자 표시
  void _showReaderSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('리더 설정'),
          content: const SizedBox(
            width: 300,
            height: 200,
            child: Center(
              child: Text('리더 설정'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
} 