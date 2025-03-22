import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document.dart' as model;
import 'dart:io' if (dart.library.html) 'dart:html' as html;

/// PDF 관련 기능을 플랫폼 특화적으로 처리하는 서비스
class PlatformSpecificPdfService {
  static final PlatformSpecificPdfService _instance = PlatformSpecificPdfService._internal();
  
  factory PlatformSpecificPdfService() => _instance;
  
  PlatformSpecificPdfService._internal();
  
  /// PDF 문서 불러오기 (URL에서)
  Future<Uint8List?> loadPdfFromUrl(String url) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서 CORS 문제를 방지하기 위한 접근법
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint('PDF 로드 실패: ${response.statusCode}');
          return null;
        }
      } else {
        // 네이티브 환경에서의 구현
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint('PDF 로드 실패: ${response.statusCode}');
          return null;
        }
      }
    } catch (e) {
      debugPrint('PDF 로드 중 오류: $e');
      return null;
    }
  }
  
  /// PDF 문서 불러오기 (로컬 파일에서)
  Future<Uint8List?> loadPdfFromFile(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 시스템 직접 접근이 불가능하므로
        // 이전에 캐시된 데이터를 확인하거나 사용자에게 다시 파일 선택을 요청
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('cached_pdf_$filePath');
        
        if (cachedData != null) {
          // 캐시된 데이터가 있으면 base64 디코딩
          return base64Decode(cachedData);
        } else {
          // 캐시된 데이터가 없으면 null 반환
          // 호출자는 파일 선택 다이얼로그를 표시해야 함
          return null;
        }
      } else {
        // 네이티브 환경에서는 파일 시스템에서 직접 읽기
        final file = File(filePath);
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('PDF 파일 로드 중 오류: $e');
      return null;
    }
  }
  
  /// 파일 선택 대화상자 표시
  Future<Uint8List?> pickAndLoadPdf() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서 파일 선택
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        
        if (result != null && result.files.isNotEmpty) {
          final fileBytes = result.files.first.bytes;
          
          if (fileBytes != null) {
            // 선택한 파일을 캐시에 저장 (식별자로 파일 이름 사용)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'cached_pdf_${result.files.first.name}',
              base64Encode(fileBytes),
            );
            
            return fileBytes;
          }
        }
        return null;
      } else {
        // 네이티브 환경에서 파일 선택
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        
        if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
          final file = File(result.files.first.path!);
          return await file.readAsBytes();
        }
        return null;
      }
    } catch (e) {
      debugPrint('PDF 파일 선택 중 오류: $e');
      return null;
    }
  }
  
  /// PDF 텍스트 추출
  Future<String> extractTextFromPdf(Uint8List pdfData) async {
    try {
      // 이 부분은 웹과 네이티브 환경 모두에서 작동
      final document = PdfDocument(inputBytes: pdfData);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      final buffer = StringBuffer();
      
      for (int i = 0; i < document.pages.count; i++) {
        String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        buffer.write(text);
        buffer.write('\n\n');
      }
      
      document.dispose();
      return buffer.toString();
    } catch (e) {
      debugPrint('PDF 텍스트 추출 중 오류: $e');
      return '';
    }
  }
  
  /// PDF 요약 생성 (추출된 텍스트를 기반으로)
  Future<String> generateSummary(String pdfText) async {
    try {
      // 여기에 요약 생성 로직 구현
      // 실제로는 AI 서비스나 백엔드 서버 호출이 필요
      
      // 예시: 첫 500자를 요약으로 사용
      if (pdfText.length > 500) {
        return '${pdfText.substring(0, 500)}... (요약 계속)';
      } else {
        return pdfText;
      }
    } catch (e) {
      debugPrint('PDF 요약 생성 중 오류: $e');
      return '요약을 생성할 수 없습니다.';
    }
  }
  
  /// PDF 기반 퀴즈 생성
  Future<List<Map<String, dynamic>>> generateQuizzes(String pdfText) async {
    try {
      // 여기에 퀴즈 생성 로직 구현
      // 실제로는 AI 서비스나 백엔드 서버 호출이 필요
      
      // 예시: 간단한 퀴즈 더미 데이터 반환
      return [
        {
          'question': '이 문서는 어떤 주제에 관한 것인가요?',
          'options': ['주제 A', '주제 B', '주제 C', '주제 D'],
          'correctIndex': 0
        },
        {
          'question': '문서에서 가장 중요한 개념은 무엇인가요?',
          'options': ['개념 1', '개념 2', '개념 3', '개념 4'],
          'correctIndex': 1
        }
      ];
    } catch (e) {
      debugPrint('퀴즈 생성 중 오류: $e');
      return [];
    }
  }
  
  /// PDF 저장 (웹에서는 다운로드)
  Future<bool> savePdf(Uint8List pdfData, String fileName) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 다운로드 수행
        final blob = html.Blob([pdfData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
          
        html.document.body?.children.add(anchor);
        anchor.click();
        
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        return true;
      } else {
        // 네이티브 환경에서는 파일로 저장
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfData);
        return true;
      }
    } catch (e) {
      debugPrint('PDF 저장 중 오류: $e');
      return false;
    }
  }
  
  /// PDF 문서 정보 추출
  Future<model.PdfDocument> extractPdfInfo(Uint8List pdfData, String fileName) async {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final pageCount = document.pages.count;
      final title = fileName.replaceAll('.pdf', '');
      final fileSize = pdfData.length;
      
      document.dispose();
      
      return model.PdfDocument(
        id: id,
        title: title,
        fileName: fileName,
        fileSize: fileSize,
        pageCount: pageCount,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        accessCount: 1,
        bookmarks: [],
        annotations: [],
      );
    } catch (e) {
      debugPrint('PDF 정보 추출 중 오류: $e');
      throw Exception('PDF 정보를 추출할 수 없습니다: $e');
    }
  }
  
  /// 썸네일 생성
  Future<Uint8List?> generateThumbnail(Uint8List pdfData) async {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      
      if (document.pages.count > 0) {
        // 첫 번째 페이지를 썸네일로 사용
        final image = await document.pages[0].render(
          width: 200,
          height: 300,
        );
        
        document.dispose();
        return image?.buffer.asUint8List();
      }
      
      document.dispose();
      return null;
    } catch (e) {
      debugPrint('썸네일 생성 중 오류: $e');
      return null;
    }
  }
} 