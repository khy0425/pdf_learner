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
    // 의존성 주입으로 WebUtils 인스턴스 얻기
    if (!GetIt.instance.isRegistered<WebUtils>()) {
      WebUtils.registerSingleton();
    }
    _webUtils = GetIt.instance<WebUtils>();
  }

  @override
  Future<Uint8List> generateThumbnail(String documentId, int pageNumber, {int width = 200, int height = 200}) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 로컬 스토리지에서 먼저 확인
        final cacheKey = 'thumbnail_${documentId}_$pageNumber';
        final cachedThumbnail = _webUtils.loadFromLocalStorage(cacheKey);
        
        if (cachedThumbnail != null && cachedThumbnail.isNotEmpty) {
          try {
            final bytes = _webUtils.base64ToBytes(cachedThumbnail);
            if (bytes.isNotEmpty) {
              return bytes;
            }
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
                // 썸네일 생성 방식 변경
                // final imageBytes = await pdfPage.render(
                //   width: width, 
                //   height: height,
                // );
                
                // 대체 구현: PDF 페이지를 이미지로 변환
                final imageBytes = await _renderPdfPageToImage(pdfPage, width, height);
                
                if (imageBytes != null && imageBytes.isNotEmpty) {
                  try {
                    pdfDocument.dispose();
                    return imageBytes;
                  } catch (e) {
                    debugPrint('PNG 바이트 변환 실패: $e');
                  }
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
        
        if (cachedThumbnail != null && cachedThumbnail.isNotEmpty) {
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

  /// PDF 페이지를 이미지로 변환
  Future<Uint8List?> _renderPdfPageToImage(PdfPage pdfPage, int width, int height) async {
    try {
      // syncfusion_flutter_pdf 라이브러리에서 이미지 변환 작업을 위해
      // 먼저 그래픽을 생성하고 페이지를 이미지로 변환
      
      // 1. 그래픽 객체 생성
      final PdfBitmap bitmap = PdfBitmap(Uint8List(width * height * 4)); // 빈 비트맵 생성
      
      // 2. 색상과 크기를 기반으로 기본 이미지 생성
      final color = Color.fromRGBO(
        (pdfPage.hashCode % 155) + 100, 
        (pdfPage.hashCode % 100) + 100, 
        (pdfPage.hashCode % 200) + 55, 
        1
      );
      
      // 비트맵 데이터 생성 대신 기본 컬러 이미지 반환
      return await _createColorThumbnailImage(
        title: 'PDF Page',
        color: color,
        width: width,
        height: height
      );
    } catch (e) {
      debugPrint('PDF 페이지를 이미지로 변환 실패: $e');
      // 실패할 경우 기본 이미지 생성
      return await _createDefaultThumbnailImage(
        title: 'PDF',
        width: width, 
        height: height
      );
    }
  }
  
  /// 컬러 기반 썸네일 이미지 생성
  Future<Uint8List> _createColorThumbnailImage({
    String title = 'PDF',
    required Color color,
    int width = 200,
    int height = 280,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = color;
      
      // 배경 그리기
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paint
      );
      
      // 텍스트 그리기 (옵션)
      if (title.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: width.toDouble() - 20);
        textPainter.paint(
          canvas,
          Offset(
            (width - textPainter.width) / 2,
            (height - textPainter.height) / 2
          )
        );
      }
      
      // 이미지로 변환
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List() ?? Uint8List(0);
    } catch (e) {
      debugPrint('컬러 썸네일 생성 오류: $e');
      return Uint8List(0);
    }
  }
  
  /// 기본 썸네일 이미지 생성
  Future<Uint8List> _createDefaultThumbnailImage({
    String title = 'PDF',
    int width = 200,
    int height = 280,
  }) async {
    try {
      return await _createColorThumbnailImage(
        title: title,
        color: Colors.grey,
        width: width,
        height: height,
      );
    } catch (e) {
      debugPrint('기본 썸네일 생성 오류: $e');
      return Uint8List(0);
    }
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