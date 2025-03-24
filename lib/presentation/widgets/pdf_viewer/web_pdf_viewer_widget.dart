import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:js/js_util.dart' as js_util;
import 'dart:ui' as ui;
import '../../viewmodels/pdf_viewer_viewmodel.dart';
import '../../models/pdf_document.dart';
import 'loading_widget.dart';

/// 웹 PDF 뷰어 위젯
class WebPdfViewerWidget extends StatefulWidget {
  final String filePath;
  final PdfViewerViewModel viewModel;
  final Function(dynamic) onMessageHandler;
  final Function(String) sendPdfMessage;
  
  const WebPdfViewerWidget({
    Key? key,
    required this.filePath,
    required this.viewModel,
    required this.onMessageHandler,
    required this.sendPdfMessage,
  }) : super(key: key);
  
  @override
  State<WebPdfViewerWidget> createState() => _WebPdfViewerWidgetState();
}

class _WebPdfViewerWidgetState extends State<WebPdfViewerWidget> {
  @override
  void initState() {
    super.initState();
    _initializePdfViewer();
  }

  void _initializePdfViewer() {
    // PDF.js 초기화
    final script = '''
      <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
      <script>
        pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
      </script>
    ''';
    
    // PDF 뷰어 iframe 생성
    final iframe = '''
      <iframe
        id="pdf-viewer"
        style="width: 100%; height: 100%; border: none;"
        src="data:application/pdf;base64,${widget.filePath}"
      ></iframe>
    ''';

    // HTML 컨텐츠 생성
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <title>PDF Viewer</title>
          $script
        </head>
        <body style="margin: 0; padding: 0;">
          $iframe
        </body>
      </html>
    ''';

    // HTML 컨텐츠를 base64로 인코딩
    final base64Content = base64Encode(utf8.encode(htmlContent));
    
    // PDF 뷰어 초기화
    widget.sendPdfMessage('initialize:$base64Content');
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// 웹 PDF 메시지 유틸리티 클래스
class WebPdfMessageUtil {
  /// PDF 메시지 처리
  static void handlePdfMessage(html.Event event, PdfViewerViewModel viewModel) {
    if (event is html.MessageEvent) {
      final message = event.data.toString();
      debugPrint('PDF 메시지 수신: $message');
      
      try {
        // JSON 형식 메시지 처리
        if (message.startsWith('{') && message.endsWith('}')) {
          final data = jsonDecode(message);
          if (data is Map && data.containsKey('type')) {
            if (data['type'] == 'pagechange' || data['type'] == 'pageinfo') {
              final currentPage = data['page'] as int? ?? 1;
              final totalPages = data['total'] as int? ?? 1;
              
              viewModel.updateCurrentPage(currentPage, totalPages);
              debugPrint('PDF 페이지 업데이트: $currentPage / $totalPages');
            }
          }
        }
        // 기존 형식 메시지 처리
        else if (message.startsWith('pdfInfo:')) {
          final parts = message.split(':');
          if (parts.length == 3) {
            try {
              final currentPage = int.parse(parts[1]);
              final totalPages = int.parse(parts[2]);
              
              viewModel.updateCurrentPage(currentPage, totalPages);
              debugPrint('PDF 페이지 업데이트(레거시): $currentPage / $totalPages');
            } catch (e) {
              debugPrint('PDF 정보 파싱 오류: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('PDF 메시지 처리 오류: $e');
      }
    }
  }
  
  /// PDF iframe에 메시지 전송
  static void sendPdfMessage(String message, String documentId) {
    if (kIsWeb) {
      try {
        // 해당 문서의 고유 ID를 사용하여 iframe 요소 찾기
        final docIdHash = documentId.hashCode.abs().toString();
        final iframeId = 'pdf-js-frame-$docIdHash';
        
        // ID로 iframe 찾기
        final iframe = html.document.getElementById(iframeId);
        debugPrint('PDF 메시지 전송 시도: $message, iframe ID: $iframeId, iframe 존재: ${iframe != null}');
        
        if (iframe != null && iframe is html.IFrameElement) {
          // 명령어 변환
          String js;
          if (message.startsWith('goToPage:')) {
            final pageNum = message.substring(9);
            js = 'PDFViewerApplication.page = $pageNum;';
          } else if (message == 'previousPage') {
            js = 'PDFViewerApplication.page--;';
          } else if (message == 'nextPage') {
            js = 'PDFViewerApplication.page++;';
          } else if (message == 'zoomIn') {
            js = 'PDFViewerApplication.zoomIn();';
          } else if (message == 'zoomOut') {
            js = 'PDFViewerApplication.zoomOut();';
          } else {
            js = '';
          }
          
          // 명령 전송 전 초기화 상태 확인
          js = '''
            if (typeof PDFViewerApplication !== 'undefined' && 
                PDFViewerApplication.initialized) {
              try {
                $js
                return true;
              } catch(e) {
                console.error('PDF 명령 실행 오류:', e);
                return false;
              }
            } else {
              console.warn('PDF 뷰어가 초기화되지 않았습니다');
              return false;
            }
          ''';
          
          if (js.isNotEmpty && iframe.contentWindow != null) {
            try {
              // 직접 JavaScript 실행
              final result = js_util.callMethod(iframe.contentWindow!, 'eval', [js]);
              debugPrint('PDF 명령 실행 결과: $result');
              if (result == true) {
                return; // 성공적으로 실행되면 종료
              }
            } catch (e) {
              debugPrint('PDF iframe 직접 실행 오류: $e, 대체 방법 시도');
            }
          }
        }
          
        // iframe을 직접 찾을 수 없거나 실행 오류가 있는 경우 모든 iframe 검사
        _sendMessageToAllPdfIframes(message);
      } catch (e) {
        debugPrint('PDF 메시지 전송 오류: $e');
      }
    }
  }
  
  // 모든 PDF.js iframe에 메시지 전송 시도
  static void _sendMessageToAllPdfIframes(String message) {
    try {
      // PDF.js 명령어 변환
      String command;
      if (message.startsWith('goToPage:')) {
        final pageNum = message.substring(9);
        command = 'PDFViewerApplication.page = $pageNum;';
      } else if (message == 'previousPage') {
        command = 'PDFViewerApplication.page--;';
      } else if (message == 'nextPage') {
        command = 'PDFViewerApplication.page++;';
      } else if (message == 'zoomIn') {
        command = 'PDFViewerApplication.zoomIn();';
      } else if (message == 'zoomOut') {
        command = 'PDFViewerApplication.zoomOut();';
      } else {
        command = '';
      }
      
      if (command.isEmpty) return;
      
      // 모든 iframe을 대상으로 명령 실행 시도
      final jsAllIframes = '''
        (function() {
          console.log('[PDF 컨트롤러] 모든 iframe 탐색 시작');
          var iframes = document.getElementsByTagName('iframe');
          
          for (var i = 0; i < iframes.length; i++) {
            var iframe = iframes[i];
            console.log('[PDF 컨트롤러] iframe ' + i + ' 확인:', iframe.src);
            
            if (iframe.src && iframe.src.includes("mozilla.github.io/pdf.js")) {
              console.log('[PDF 컨트롤러] PDF.js iframe 발견');
              
              try {
                if (iframe.contentWindow) {
                  var script = 'if (typeof PDFViewerApplication !== "undefined" && PDFViewerApplication.initialized) { ' + 
                    'try { $command return true; } catch(e) { console.error(e); return false; } } else { return false; }';
                  var result = iframe.contentWindow.eval(script);
                  console.log('[PDF 컨트롤러] 명령 실행 결과:', result);
                  if (result === true) {
                    return true;
                  }
                }
              } catch (e) {
                console.error('[PDF 컨트롤러] 오류:', e);
              }
            }
          }
          
          return false;
        })();
      '''.replaceAll('\$command', command);
      
      // 모든 iframe 대상 스크립트 실행
      final result = js_util.callMethod(html.window, 'eval', [jsAllIframes]);
      debugPrint('PDF 메시지 모든 iframe 전송 결과: $result');
    } catch (e) {
      debugPrint('PDF 메시지 전송 오류 (iframe 검색): $e');
    }
  }
} 