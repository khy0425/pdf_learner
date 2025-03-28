import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_learner_v2/core/utils/web_utils.dart';
// pdf_render 패키지가 pubspec.yaml에 없어서 오류 발생
// import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:http/http.dart' as http;
import 'package:pdf_learner_v2/services/storage/storage_service.dart';
import 'package:get_it/get_it.dart';

/// 썸네일 관련 기능 인터페이스
abstract class ThumbnailService {
  /// PDF 문서에서 특정 페이지의 썸네일 생성
  Future<Uint8List> generateThumbnail(String documentId, int pageNumber, {int width = 200, int height = 200});
  
  /// 썸네일 저장
  Future<bool> saveThumbnail(String documentId, int pageNumber, Uint8List thumbnailData);
  
  /// 썸네일 로드
  Future<Uint8List?> loadThumbnail(String documentId, int pageNumber);
  
  /// 썸네일 삭제
  Future<bool> deleteThumbnail(String documentId, int pageNumber);
  
  /// 문서의 모든 썸네일 삭제
  Future<bool> deleteAllThumbnails(String documentId);
}

/// 썸네일 서비스 구현
class ThumbnailServiceImpl implements ThumbnailService {
  final StorageService _storageService;
  static const int _thumbnailWidth = 200; // 썸네일 너비
  static const double _thumbnailQuality = 0.5; // 썸네일 품질
  late final WebUtils _webUtils;
  
  ThumbnailServiceImpl(this._storageService) {
    // GetIt에서 WebUtils 인스턴스를 가져오거나, 없으면 생성하여 등록
    try {
      _webUtils = GetIt.instance.get<WebUtils>();
    } catch (e) {
      _webUtils = WebUtils();
      WebUtils.registerSingleton();
    }
  }

  @override
  Future<Uint8List> generateThumbnail(String documentId, int pageNumber, {int width = 200, int height = 200}) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 먼저 확인
        final cacheKey = 'thumbnail_${documentId}_$pageNumber';
        final cachedThumbnail = _webUtils.loadFromLocalStorage(cacheKey);
        
        if (cachedThumbnail != null) {
          try {
            return _webUtils.base64ToBytes(cachedThumbnail);
          } catch (e) {
            debugPrint('캐시된 썸네일 변환 실패: $e');
          }
        }
        
        // 캐시가 없으면 새로 생성
        final color = _generateColorFromFileName(documentId);
        final image = await _createColorThumbnailImage(
          title: 'Page $pageNumber',
          color: color,
        );
        
        // 생성된 썸네일 캐싱
        if (image.isNotEmpty) {
          try {
            final base64Image = _webUtils.bytesToBase64(image);
            _webUtils.saveToLocalStorage(cacheKey, base64Image);
          } catch (e) {
            debugPrint('웹 썸네일 캐싱 실패: $e');
          }
        }
        
        return image;
      } else {
        try {
          // 네이티브 환경에서는 SyncfusionFlutterPdf 활용
          // PDF 파일에서 특정 페이지 추출 시도
          final filePath = await _getDocumentPath(documentId);
          if (filePath != null && await File(filePath).exists()) {
            try {
              final pdfDocument = PdfDocument(inputBytes: await File(filePath).readAsBytes());
              if (pageNumber <= pdfDocument.pages.count) {
                // PDF 페이지에서 이미지 추출
                final pdfPage = pdfDocument.pages[pageNumber - 1];
                final pdfBitmap = pdfPage.createImage(
                  width: width,
                  height: height,
                );
                
                if (pdfBitmap != null) {
                  final bytes = await pdfBitmap.bytes;
                  pdfDocument.dispose();
                  return bytes;
                }
              }
              pdfDocument.dispose();
            } catch (e) {
              debugPrint('PDF 렌더링 오류: $e');
            }
          }
        } catch (e) {
          debugPrint('PDF 썸네일 생성 오류: $e');
        }
        
        // 실패 시 기본 썸네일 반환
        return await _createDefaultThumbnailImage(title: 'Page $pageNumber');
      }
    } catch (e) {
      debugPrint('썸네일 생성 실패: $e');
      return await _createDefaultThumbnailImage();
    }
  }

  /// PDF 문서 경로 가져오기
  Future<String?> _getDocumentPath(String documentId) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfsDir = Directory('${docsDir.path}/pdfs');
      
      if (await pdfsDir.exists()) {
        final files = await pdfsDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains(documentId)) {
            return file.path;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('문서 경로 가져오기 실패: $e');
      return null;
    }
  }

  @override
  Future<bool> saveThumbnail(String documentId, int pageNumber, Uint8List thumbnailData) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에 저장
        final cacheKey = 'thumbnail_${documentId}_$pageNumber';
        final base64Image = _webUtils.bytesToBase64(thumbnailData);
        _webUtils.saveToLocalStorage(cacheKey, base64Image);
        return true;
      } else {
        // 네이티브 환경에서는 파일로 저장
        final path = _getThumbnailPath(documentId, pageNumber);
        await _storageService.saveFile(thumbnailData, path);
        return true;
      }
    } catch (e) {
      debugPrint('썸네일 저장 실패: $e');
      return false;
    }
  }

  @override
  Future<Uint8List?> loadThumbnail(String documentId, int pageNumber) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 로드
        final cacheKey = 'thumbnail_${documentId}_$pageNumber';
        final cachedThumbnail = _webUtils.loadFromLocalStorage(cacheKey);
        
        if (cachedThumbnail != null) {
          try {
            return _webUtils.base64ToBytes(cachedThumbnail);
          } catch (e) {
            debugPrint('캐시된 썸네일 변환 실패: $e');
          }
        }
        
        // 캐시에 없으면 새로 생성
        return await generateThumbnail(documentId, pageNumber);
      } else {
        // 네이티브 환경에서는 파일에서 로드
        final path = _getThumbnailPath(documentId, pageNumber);
        final data = await _storageService.readFile(path);
        
        // 파일이 없으면 새로 생성
        if (data == null || data.isEmpty) {
          return await generateThumbnail(documentId, pageNumber);
        }
        
        return data;
      }
    } catch (e) {
      debugPrint('썸네일 로드 실패: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteThumbnail(String documentId, int pageNumber) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 삭제
        final cacheKey = 'thumbnail_${documentId}_$pageNumber';
        _webUtils.removeFromLocalStorage(cacheKey);
        return true;
      } else {
        // 네이티브 환경에서는 파일 삭제
        final path = _getThumbnailPath(documentId, pageNumber);
        await _storageService.deleteFile(path);
        return true;
      }
    } catch (e) {
      debugPrint('썸네일 삭제 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAllThumbnails(String documentId) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 문서 관련 모든 썸네일 캐시 키 삭제
        for (int i = 1; i <= 1000; i++) { // 적절한 한도 설정 필요
          final cacheKey = 'thumbnail_${documentId}_$i';
          if (_webUtils.loadFromLocalStorage(cacheKey) != null) {
            _webUtils.removeFromLocalStorage(cacheKey);
          } else {
            // 더 이상 캐시 항목이 없으면 종료
            if (i > 10) break;
          }
        }
        return true;
      } else {
        // 네이티브 환경에서는 디렉토리 삭제
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailDir = Directory('${directory.path}/thumbnails/$documentId');
        if (await thumbnailDir.exists()) {
          await thumbnailDir.delete(recursive: true);
        }
        return true;
      }
    } catch (e) {
      debugPrint('모든 썸네일 삭제 실패: $e');
      return false;
    }
  }
  
  String _getThumbnailPath(String documentId, int pageNumber) {
    return 'thumbnails/$documentId/page_$pageNumber.jpg';
  }

  /// 색상 기반 썸네일 이미지 생성
  Future<Uint8List> _createColorThumbnailImage({
    String title = '', 
    Color color = Colors.blue
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 썸네일 크기
    final size = Size(_thumbnailWidth.toDouble(), _thumbnailWidth * 1.4);
    
    // 배경 - 페이지 모양
    final Paint bgPaint = Paint()
      ..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // 페이지 그림자
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withAlpha(26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 2, size.height - 2),
      shadowPaint,
    );
    
    // 색상 배경
    final Paint colorPaint = Paint()
      ..color = color;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.width * 0.1, size.width * 0.8, size.width * 0.8),
      colorPaint,
    );
    
    // 제목 텍스트
    if (title.isNotEmpty) {
      final titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );
      final titleSpan = TextSpan(text: title, style: titleStyle);
      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: size.width * 0.7);
      
      final textX = size.width * 0.1 + (size.width * 0.8 - titlePainter.width) / 2;
      final textY = size.width * 0.1 + (size.width * 0.8 - titlePainter.height) / 2;
      titlePainter.paint(canvas, Offset(textX, textY));
    }
    
    // PDF 아이콘
    final iconPaint = Paint()
      ..color = Colors.white.withAlpha(153);
    final iconSize = size.width * 0.3;
    final iconX = (size.width - iconSize) / 2;
    final iconY = size.height - iconSize - 10;
    
    // PDF 아이콘 그리기 (간단한 문서 모양)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(iconX, iconY, iconSize, iconSize * 1.2),
        Radius.circular(iconSize * 0.1),
      ),
      iconPaint,
    );
    
    // 완료 및 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (pngBytes == null) {
      return Uint8List(0);
    }
    
    return pngBytes.buffer.asUint8List();
  }
  
  /// 기본 썸네일 이미지 생성
  Future<Uint8List> _createDefaultThumbnailImage({String title = ''}) async {
    return _createColorThumbnailImage(
      title: title,
      color: Colors.blueGrey,
    );
  }
  
  /// 파일 이름에서 고유한 색상 생성
  Color _generateColorFromFileName(String fileName) {
    if (fileName.isEmpty) {
      return Colors.blue;
    }
    
    // 간단한 해시 생성
    int hash = 0;
    for (var i = 0; i < fileName.length; i++) {
      hash = fileName.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // HSL 색상 생성 (부드러운 색상용)
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.6).toColor();
  }
}

/// 작은 헬퍼 함수
int min(int a, int b) => a < b ? a : b; 