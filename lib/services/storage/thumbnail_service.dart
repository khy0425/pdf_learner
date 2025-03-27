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
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:http/http.dart' as http;
import 'package:pdf_learner_v2/services/storage/storage_service.dart';

/// PDF 썸네일 생성 서비스
abstract class ThumbnailService {
  /// PDF 문서의 썸네일을 생성합니다.
  /// [documentId] 문서 ID
  /// [pageNumber] 썸네일을 생성할 페이지 번호
  /// [width] 썸네일 너비
  /// [height] 썸네일 높이
  /// 성공 시 썸네일 이미지 데이터를 반환합니다.
  Future<List<int>> generateThumbnail(String documentId, int pageNumber, {int width = 200, int height = 200});

  /// 썸네일을 저장합니다.
  /// [documentId] 문서 ID
  /// [pageNumber] 페이지 번호
  /// [thumbnailData] 썸네일 이미지 데이터
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> saveThumbnail(String documentId, int pageNumber, List<int> thumbnailData);

  /// 썸네일을 로드합니다.
  /// [documentId] 문서 ID
  /// [pageNumber] 페이지 번호
  /// 썸네일 이미지 데이터를 반환합니다.
  Future<List<int>> loadThumbnail(String documentId, int pageNumber);

  /// 썸네일을 삭제합니다.
  /// [documentId] 문서 ID
  /// [pageNumber] 페이지 번호
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> deleteThumbnail(String documentId, int pageNumber);

  /// 문서의 모든 썸네일을 삭제합니다.
  /// [documentId] 문서 ID
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> deleteAllThumbnails(String documentId);
}

/// 썸네일 서비스 구현
class ThumbnailServiceImpl implements ThumbnailService {
  final StorageService _storageService;
  final bool _isWeb;

  ThumbnailServiceImpl(this._storageService, {bool isWeb = false}) 
      : _isWeb = isWeb;

  @override
  Future<List<int>> generateThumbnail(String documentId, int pageNumber, {
    int width = 200,
    int height = 200,
  }) async {
    try {
      return _isWeb ? 
          await _generateWebThumbnail(documentId, pageNumber, width, height) :
          await _generateNativeThumbnail(documentId, pageNumber, width, height);
    } catch (e) {
      debugPrint('썸네일 생성 실패: $e');
      rethrow;
    }
  }

  Future<List<int>> _generateWebThumbnail(
    String documentId,
    int pageNumber,
    int width,
    int height,
  ) async {
    // 웹 구현
    throw UnimplementedError('웹 썸네일 생성은 아직 구현되지 않았습니다.');
  }

  Future<List<int>> _generateNativeThumbnail(
    String documentId,
    int pageNumber,
    int width,
    int height,
  ) async {
    // 네이티브 구현
    throw UnimplementedError('네이티브 썸네일 생성은 아직 구현되지 않았습니다.');
  }

  @override
  Future<bool> saveThumbnail(String documentId, int pageNumber, List<int> thumbnailData) async {
    try {
      final path = _getThumbnailPath(documentId, pageNumber);
      return await _storageService.saveFile(path, thumbnailData);
    } catch (e) {
      debugPrint('썸네일 저장 실패: $e');
      return false;
    }
  }

  @override
  Future<List<int>> loadThumbnail(String documentId, int pageNumber) async {
    try {
      final path = _getThumbnailPath(documentId, pageNumber);
      return await _storageService.readFile(path);
    } catch (e) {
      debugPrint('썸네일 로드 실패: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteThumbnail(String documentId, int pageNumber) async {
    try {
      final path = _getThumbnailPath(documentId, pageNumber);
      return await _storageService.deleteFile(path);
    } catch (e) {
      debugPrint('썸네일 삭제 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAllThumbnails(String documentId) async {
    try {
      // 문서의 모든 썸네일 삭제 로직 구현
      return true;
    } catch (e) {
      debugPrint('모든 썸네일 삭제 실패: $e');
      return false;
    }
  }

  String _getThumbnailPath(String documentId, int pageNumber) {
    return 'thumbnails/$documentId/page_$pageNumber.jpg';
  }
}

class ThumbnailServiceImpl extends ThumbnailService {
  static const int _thumbnailWidth = 200; // 썸네일 너비
  static const double _thumbnailQuality = 0.5; // 썸네일 품질
  static final _uuid = Uuid();
  
  // 웹에서 사용할 메모리 캐시
  static final Map<String, Uint8List> _webThumbnailCache = {};

  /// 썸네일 생성
  /// 네이티브 환경에서는 썸네일을 파일로 저장하고 경로를 반환
  /// 웹 환경에서는 메모리에 저장하고 고유 ID를 반환
  Future<String?> generateThumbnail(Uint8List pdfBytes, String? filePath) async {
    try {
      if (kIsWeb) {
        debugPrint('웹 환경에서 썸네일 생성 중...');
        final thumbnailId = _uuid.v4();
        
        try {
          // 웹 환경에서는 색상 기반 썸네일 생성
          final color = _generateColorFromFileName(filePath ?? '');
          final defaultImage = await _createColorThumbnailImage(
            title: filePath != null ? path.basename(filePath) : '',
            color: color,
          );
          
          _webThumbnailCache[thumbnailId] = defaultImage;
          return thumbnailId;
        } catch (e) {
          debugPrint('웹 환경 썸네일 생성 오류: $e');
          // 모든 시도가 실패하면 기본 썸네일 생성
          final defaultImage = await _createDefaultThumbnailImage(
            title: filePath != null ? path.basename(filePath) : '',
          );
          _webThumbnailCache[thumbnailId] = defaultImage;
          return thumbnailId;
        }
      } else {
        // 네이티브 환경에서는 파일로 저장
        if (filePath == null) {
          debugPrint('파일 경로가 null입니다.');
          return await getDefaultThumbnailPath();
        }
        
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailsDir = Directory('${directory.path}/thumbnails');
        if (!await thumbnailsDir.exists()) {
          await thumbnailsDir.create(recursive: true);
        }
        
        // 파일명 생성 (원본 파일명 기준)
        final fileName = path.basename(filePath);
        final thumbnailPath = '${thumbnailsDir.path}/${path.basenameWithoutExtension(fileName)}_thumb.png';
        
        // 이미 썸네일이 있으면 그대로 반환
        if (await File(thumbnailPath).exists()) {
          return thumbnailPath;
        }
        
        try {
          // 네이티브에서 PDF 렌더링 시도
          // 현재 pdf_render 패키지 API가 변경되었을 수 있으므로
          // 일단 기본 썸네일을 생성하고 나중에 렌더링 코드를 업데이트합니다.
          
          // PDF에서 제목 또는 파일명을 기반으로 고유한 색상 생성
          final defaultIcon = await _createDefaultThumbnailImage(
            title: path.basenameWithoutExtension(fileName),
          );
          final file = File(thumbnailPath);
          await file.writeAsBytes(defaultIcon);
          return thumbnailPath;
          
          /* 나중에 구현할 코드:
          final pdfDocument = await pdf_render.PdfDocument.openData(pdfBytes);
          
          if (pdfDocument.pageCount > 0) {
            // 첫 페이지 가져오기
            final pdfPage = await pdfDocument.getPage(1);
            
            // 페이지 렌더링
            final pageImage = await pdfPage.render(
              width: _thumbnailWidth, 
              height: (_thumbnailWidth * (pdfPage.height / pdfPage.width)).toInt(),
            );
            
            // 이미지 데이터 가져오기 및 저장 (정확한 API 확인 필요)
            // ...
            
            await pdfDocument.dispose();
          }
          */
        } catch (e) {
          debugPrint('네이티브 환경에서 PDF 렌더링 오류: $e');
          // 렌더링 오류 시 기본 썸네일 생성
          final defaultIcon = await _createDefaultThumbnailImage(
            title: path.basenameWithoutExtension(fileName),
          );
          final file = File(thumbnailPath);
          await file.writeAsBytes(defaultIcon);
          return thumbnailPath;
        }
        
        return await getDefaultThumbnailPath();
      }
    } catch (e) {
      debugPrint('썸네일 생성 오류: $e');
      return await getDefaultThumbnailPath();
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
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 4, size.height - 4), 
      shadowPaint
    );
    
    // 페이지 테두리
    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height), 
      borderPaint
    );
    
    // 색상 상단 영역
    final Paint colorPaint = Paint()
      ..color = color;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5), 
      colorPaint
    );
    
    // PDF 아이콘
    final TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.picture_as_pdf.codePoint),
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: size.width * 0.3,
          fontFamily: Icons.picture_as_pdf.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        size.height * 0.25 - iconPainter.height / 2,
      ),
    );
    
    // 제목 텍스트 (존재하는 경우)
    if (title.isNotEmpty) {
      final TextPainter titlePainter = TextPainter(
        text: TextSpan(
          text: title.length > 20 ? '${title.substring(0, 17)}...' : title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: size.width * 0.8);
      titlePainter.paint(
        canvas,
        Offset(
          (size.width - titlePainter.width) / 2,
          size.height * 0.7,
        ),
      );
    }
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }
  
  /// URL에서 썸네일 생성
  Future<String?> generateThumbnailFromUrl(String url) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 기본 썸네일 사용
        return await getDefaultThumbnailPath();
      }
      
      // URL에서 다운로드 시도
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Uint8List pdfData = response.bodyBytes;
        return await generateThumbnail(pdfData, url);
      } else {
        debugPrint('URL에서 PDF 다운로드 실패: $url, 상태 코드: ${response.statusCode}');
        return await getDefaultThumbnailPath();
      }
    } catch (e) {
      debugPrint('URL 썸네일 생성 오류: $e');
      return await getDefaultThumbnailPath();
    }
  }
  
  /// 기본 썸네일 경로 가져오기
  Future<String?> getDefaultThumbnailPath() async {
    if (kIsWeb) {
      // 웹에서는 고유 ID 반환
      final defaultId = 'default-thumbnail';
      if (!_webThumbnailCache.containsKey(defaultId)) {
        _webThumbnailCache[defaultId] = Uint8List(0);
      }
      return defaultId;
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailsDir = Directory('${directory.path}/thumbnails');
        if (!await thumbnailsDir.exists()) {
          await thumbnailsDir.create(recursive: true);
        }
        
        final defaultThumbnailPath = '${thumbnailsDir.path}/default_thumbnail.png';
        final defaultFile = File(defaultThumbnailPath);
        
        if (!await defaultFile.exists()) {
          // 기본 썸네일 생성
          final defaultIcon = await _createDefaultThumbnailImage();
          await defaultFile.writeAsBytes(defaultIcon);
        }
        
        return defaultThumbnailPath;
      } catch (e) {
        debugPrint('기본 썸네일 경로 오류: $e');
        return '';
      }
    }
  }
  
  /// 문서 ID로 썸네일 생성
  Future<String?> generateThumbnailForDocument(String documentId, String documentPath) async {
    if (documentPath.isEmpty) {
      return await getDefaultThumbnailPath();
    }
    
    if (kIsWeb) {
      // 웹에서는 ID 기반으로 판단
      if (_webThumbnailCache.containsKey(documentId)) {
        return documentId;
      }
      return await getDefaultThumbnailPath();
    } else {
      try {
        final file = File(documentPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return await generateThumbnail(bytes, documentPath);
        }
      } catch (e) {
        debugPrint('문서 ID 썸네일 생성 오류: $e');
      }
      return await getDefaultThumbnailPath();
    }
  }
  
  /// 캐시된 썸네일 가져오기
  Future<dynamic> getCachedThumbnail(String documentId) async {
    if (kIsWeb) {
      // 웹에서는 메모리 캐시에서 바이트 배열 반환
      return _webThumbnailCache[documentId];
    } else {
      // 네이티브에서는 파일 경로가 이미 documentId에 저장되어 있음
      if (documentId.isNotEmpty) {
        final file = File(documentId);
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    }
  }
  
  /// 기본 썸네일 이미지 생성
  Future<Uint8List> _createDefaultThumbnailImage({String title = ''}) async {
    // 간단한 기본 이미지 생성
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 썸네일 크기
    final size = Size(_thumbnailWidth.toDouble(), _thumbnailWidth * 1.4);
    
    // 배경
    final Paint bgPaint = Paint()
      ..color = Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // PDF 아이콘
    final TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.picture_as_pdf.codePoint),
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: size.width * 0.4,
          fontFamily: Icons.picture_as_pdf.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 3,
      ),
    );
    
    // 제목 텍스트 (존재하는 경우)
    if (title.isNotEmpty) {
      final TextPainter titlePainter = TextPainter(
        text: TextSpan(
          text: title.length > 20 ? '${title.substring(0, 17)}...' : title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: size.width * 0.8);
      titlePainter.paint(
        canvas,
        Offset(
          (size.width - titlePainter.width) / 2,
          size.height * 0.7,
        ),
      );
    }
    
    // 이미지로 변환
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }
  
  /// 메모리 사용량을 줄이기 위해 웹 캐시 정리
  void clearWebCache(List<String> keepIds) {
    if (kIsWeb) {
      final List<String> keysToRemove = [];
      _webThumbnailCache.forEach((key, value) {
        if (!keepIds.contains(key) && key != 'default-thumbnail') {
          keysToRemove.add(key);
        }
      });
      
      for (final key in keysToRemove) {
        _webThumbnailCache.remove(key);
      }
    }
  }

  Future<Uint8List?> generateThumbnailBytes(Uint8List pdfBytes) async {
    try {
      final document = await PdfDocument.openData(pdfBytes);
      if (document.pageCount == 0) return null;

      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: 200,
        height: 200,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#ffffff',
      );

      return pageImage.bytes;
    } catch (e) {
      debugPrint('썸네일 생성 중 오류 발생: $e');
      return null;
    }
  }

  Future<void> deleteThumbnail(String thumbnailPath) async {
    try {
      if (WebUtils.isWeb()) {
        // Web에서는 base64 데이터를 저장소에서 삭제
        WebUtils.removeFromLocalStorage(thumbnailPath);
      } else {
        // 네이티브에서는 파일 삭제
        // TODO: 네이티브 구현
      }
    } catch (e) {
      debugPrint('썸네일 삭제 중 오류 발생: $e');
    }
  }

  String? getThumbnailUrl(String thumbnailPath) {
    try {
      if (WebUtils.isWeb()) {
        final base64Data = WebUtils.loadFromLocalStorage(thumbnailPath);
        if (base64Data == null) return null;
        return 'data:image/jpeg;base64,$base64Data';
      } else {
        // 네이티브에서는 파일 경로 반환
        // TODO: 네이티브 구현
        return null;
      }
    } catch (e) {
      debugPrint('썸네일 URL 가져오기 중 오류 발생: $e');
      return null;
    }
  }
}

/// 작은 헬퍼 함수
int min(int a, int b) => a < b ? a : b; 