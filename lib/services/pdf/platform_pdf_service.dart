import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_learner_v2/config/platform_config.dart';
import 'package:pdf_learner_v2/models/pdf_document.dart';
import 'package:pdf_learner_v2/services/api_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// 플랫폼별 PDF 관련 기능을 제공하는 서비스
class PlatformPdfService {
  final ApiService _apiService = ApiService();
  
  /// 캐시에 저장된 PDF 목록 키
  static const String _cachedPdfsKey = 'cached_pdfs';
  
  /// URL에서 PDF 로드
  Future<Uint8List?> loadPdfFromUrl(String url) async {
    try {
      if (kDebugMode) {
        print('PDF URL에서 로드 시도: $url');
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        if (kDebugMode) {
          print('PDF 로드 실패: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF URL 로드 중 오류: $e');
      }
      return null;
    }
  }
  
  /// 파일에서 PDF 로드
  Future<Uint8List?> loadPdfFromFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 경로를 직접 사용할 수 없음
        return null;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        if (kDebugMode) {
          print('PDF 파일이 존재하지 않음: $filePath');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF 파일 로드 중 오류: $e');
      }
      return null;
    }
  }
  
  /// 파일 선택하기
  Future<PdfDocument?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: PlatformConfig.getSupportedPdfExtensions(),
      );
      
      if (result != null) {
        final file = result.files.first;
        final fileName = file.name;
        
        if (kIsWeb) {
          // 웹에서는 바이트 데이터 직접 사용
          if (file.bytes != null) {
            // 캐시에 파일 정보 저장
            await _cachePdfMetadata(fileName, null, file.bytes!.length);
            
            return PdfDocument(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: fileName,
              fileName: fileName,
              filePath: null,
              fileBytes: file.bytes,
              totalPages: await _countPdfPages(file.bytes!),
              fileSize: file.bytes!.length,
              lastOpened: DateTime.now(),
              isBookmarked: false,
              isLocal: true,
            );
          }
        } else {
          // 네이티브 앱에서는 파일 경로 사용
          if (file.path != null) {
            final filePath = file.path!;
            final fileBytes = await File(filePath).readAsBytes();
            
            // 캐시에 파일 정보 저장
            await _cachePdfMetadata(fileName, filePath, fileBytes.length);
            
            return PdfDocument(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: fileName,
              fileName: fileName,
              filePath: filePath,
              fileBytes: fileBytes,
              totalPages: await _countPdfPages(fileBytes),
              fileSize: fileBytes.length,
              lastOpened: DateTime.now(),
              isBookmarked: false,
              isLocal: true,
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('PDF 파일 선택 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF URL에서 문서 생성
  Future<PdfDocument?> createPdfDocumentFromUrl(String url, {String? title}) async {
    try {
      final bytes = await loadPdfFromUrl(url);
      
      if (bytes != null) {
        final fileName = title ?? path.basename(url);
        
        // 캐시에 파일 정보 저장
        await _cachePdfMetadata(fileName, url, bytes.length);
        
        return PdfDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title ?? fileName,
          fileName: fileName,
          filePath: url,
          fileBytes: bytes,
          totalPages: await _countPdfPages(bytes),
          fileSize: bytes.length,
          lastOpened: DateTime.now(),
          isBookmarked: false,
          isLocal: false,
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('URL에서 PDF 문서 생성 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF 파일에서 문서 생성
  Future<PdfDocument?> createPdfDocumentFromFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 경로를 직접 사용할 수 없음
        return null;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = path.basename(filePath);
        
        // 캐시에 파일 정보 저장
        await _cachePdfMetadata(fileName, filePath, bytes.length);
        
        return PdfDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName,
          fileName: fileName,
          filePath: filePath,
          fileBytes: bytes,
          totalPages: await _countPdfPages(bytes),
          fileSize: bytes.length,
          lastOpened: DateTime.now(),
          isBookmarked: false,
          isLocal: true,
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('파일에서 PDF 문서 생성 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF에서 텍스트 추출
  Future<String?> extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      final document = SyncfusionPdfDocument(inputBytes: pdfBytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      final pageCount = document.pages.count;
      final List<String> textPages = [];
      
      for (int i = 1; i <= pageCount; i++) {
        final text = extractor.extractText(startPageIndex: i - 1, endPageIndex: i - 1);
        textPages.add(text);
      }
      
      // 모든 페이지의 텍스트 합치기
      return textPages.join('\n\n--- 페이지 구분선 ---\n\n');
    } catch (e) {
      if (kDebugMode) {
        print('PDF에서 텍스트 추출 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF에서 요약 생성
  Future<String?> generateSummaryFromPdf(Uint8List pdfBytes) async {
    try {
      // 텍스트 추출
      final extractedText = await extractTextFromPdf(pdfBytes);
      if (extractedText == null || extractedText.isEmpty) {
        return null;
      }
      
      // API 서비스를 통해 요약 생성
      return await _apiService.generatePdfSummary(extractedText);
    } catch (e) {
      if (kDebugMode) {
        print('PDF 요약 생성 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF에서 퀴즈 생성
  Future<List<Map<String, dynamic>>?> generateQuizFromPdf(Uint8List pdfBytes) async {
    try {
      // 텍스트 추출
      final extractedText = await extractTextFromPdf(pdfBytes);
      if (extractedText == null || extractedText.isEmpty) {
        return null;
      }
      
      // API 서비스를 통해 퀴즈 생성
      return await _apiService.generatePdfQuiz(extractedText);
    } catch (e) {
      if (kDebugMode) {
        print('PDF 퀴즈 생성 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF 페이지 수 계산
  Future<int> _countPdfPages(Uint8List pdfBytes) async {
    try {
      final document = SyncfusionPdfDocument(inputBytes: pdfBytes);
      final pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      if (kDebugMode) {
        print('PDF 페이지 수 계산 중 오류: $e');
      }
      return 0;
    }
  }
  
  /// PDF 메타데이터 캐싱
  Future<void> _cachePdfMetadata(String fileName, String? filePath, int fileSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 기존 캐시 데이터 가져오기
      final List<String> cachedPdfs = prefs.getStringList(_cachedPdfsKey) ?? [];
      
      // 새 메타데이터 생성
      final Map<String, dynamic> metadata = {
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'lastOpened': DateTime.now().toIso8601String(),
      };
      
      // JSON 문자열로 변환
      final String metadataJson = jsonEncode(metadata);
      
      // 기존 캐시에 없으면 추가
      if (!cachedPdfs.any((item) {
        final Map<String, dynamic> itemData = jsonDecode(item);
        return itemData['fileName'] == fileName;
      })) {
        cachedPdfs.add(metadataJson);
        await prefs.setStringList(_cachedPdfsKey, cachedPdfs);
      } else {
        // 기존 항목 업데이트
        final updatedCache = cachedPdfs.map((item) {
          final Map<String, dynamic> itemData = jsonDecode(item);
          if (itemData['fileName'] == fileName) {
            return metadataJson;
          }
          return item;
        }).toList();
        
        await prefs.setStringList(_cachedPdfsKey, updatedCache);
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF 메타데이터 캐싱 중 오류: $e');
      }
    }
  }
  
  /// 캐시된 모든 PDF 메타데이터 가져오기
  Future<List<Map<String, dynamic>>> getCachedPdfMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cachedPdfs = prefs.getStringList(_cachedPdfsKey) ?? [];
      
      return cachedPdfs.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        print('캐시된 PDF 메타데이터 가져오기 중 오류: $e');
      }
      return [];
    }
  }
  
  /// PDF 파일을 로컬에 저장
  Future<String?> savePdfToLocal(String fileName, Uint8List bytes) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 시스템에 직접 저장할 수 없음
        // 대신 캐시에 바이트 데이터를 저장하거나 다운로드 API 사용 필요
        return null;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // 캐시에 파일 정보 저장
      await _cachePdfMetadata(fileName, filePath, bytes.length);
      
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('PDF 파일 저장 중 오류: $e');
      }
      return null;
    }
  }
  
  /// 에셋에서 PDF 로드
  Future<Uint8List?> loadPdfFromAsset(String assetPath) async {
    try {
      return await rootBundle.load(assetPath).then((data) => data.buffer.asUint8List());
    } catch (e) {
      if (kDebugMode) {
        print('에셋에서 PDF 로드 중 오류: $e');
      }
      return null;
    }
  }
  
  /// Base64 문자열에서 PDF 로드
  Uint8List? loadPdfFromBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      if (kDebugMode) {
        print('Base64에서 PDF 로드 중 오류: $e');
      }
      return null;
    }
  }
  
  /// PDF를 Base64 문자열로 변환
  String? convertPdfToBase64(Uint8List bytes) {
    try {
      return base64Encode(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('PDF를 Base64로 변환 중 오류: $e');
      }
      return null;
    }
  }
} 