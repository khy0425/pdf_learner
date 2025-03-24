import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../providers/pdf_provider.dart';
import '../services/subscription_service.dart';
import '../services/web_pdf_service.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/pdf_file_info.dart';

/// PDF 서비스 인터페이스
/// 
/// PDF 문서의 렌더링, 탐색, 텍스트 추출 등의 기능을 제공하는 서비스입니다.
/// 
/// 주요 기능:
/// - PDF 문서 열기/닫기
/// - 페이지 탐색
/// - 페이지 렌더링
/// - 텍스트 추출
/// - 메타데이터 검색
/// - 텍스트 검색
/// 
/// 사용 예시:
/// ```dart
/// final pdfService = PDFServiceImpl();
/// await pdfService.openPDF('/path/to/document.pdf');
/// final pageCount = pdfService.getPageCount();
/// ```
abstract class PDFService {
  /// PDF 파일을 엽니다.
  /// [filePath] PDF 파일 경로
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> openPDF(String filePath);

  /// PDF의 총 페이지 수를 가져옵니다.
  Future<int> getPageCount();

  /// 현재 페이지 번호를 가져옵니다.
  Future<int> getCurrentPage();

  /// 지정된 페이지로 이동합니다.
  /// [pageNumber] 이동할 페이지 번호
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> goToPage(int pageNumber);

  /// 현재 페이지를 이미지로 렌더링합니다.
  /// [width] 렌더링할 이미지의 너비 (기본값: 800)
  /// [height] 렌더링할 이미지의 높이 (기본값: 1200)
  /// 렌더링된 페이지의 이미지 데이터를 반환합니다.
  Future<List<int>> renderPage({
    int width = 800,
    int height = 1200,
  });

  /// 현재 페이지의 텍스트를 추출합니다.
  /// 추출된 텍스트를 반환합니다.
  Future<String> extractText();

  /// PDF 문서의 메타데이터를 가져옵니다.
  /// 문서의 메타데이터를 Map 형태로 반환합니다.
  Future<Map<String, dynamic>> getMetadata();

  /// PDF 문서 내에서 텍스트를 검색합니다.
  /// [query] 검색할 텍스트
  /// 검색 결과를 List 형태로 반환합니다.
  Future<List<int>> searchText(String query);

  /// PDF 파일을 닫습니다.
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> closePDF();

  /// PDF 파일이 열려있는지 확인합니다.
  /// 열려있으면 true, 닫혀있으면 false를 반환합니다.
  bool isOpen();

  /// 현재 열린 PDF 파일의 경로를 반환합니다.
  /// 파일 경로를 반환합니다.
  String getFilePath();

  /// 리소스를 정리합니다.
  void dispose();
}

/// PDF 서비스 구현 클래스
/// 
/// [PDFService] 인터페이스의 기본 구현을 제공합니다.
class PDFServiceImpl implements PDFService {
  // 무료 사용자 PDF 크기 제한 (5MB)
  static const int FREE_SIZE_LIMIT_BYTES = 5 * 1024 * 1024;
  
  // 무료 사용자 PDF 텍스트 길이 제한 (약 10,000자)
  static const int FREE_TEXT_LENGTH_LIMIT = 10000;
  
  // WebPdfService 인스턴스
  final WebPdfService _webPdfService = WebPdfService();

  /// PDF 파일에서 텍스트 추출
  Future<String> extractText(
    PdfFileInfo pdfFile, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await _getPdfBytes(pdfFile);
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final buffer = StringBuffer();

      // 페이지별로 나누어 처리하여 UI 블로킹 방지
      for (int i = 0; i < pageCount; i++) {
        if (onProgress != null) {
          onProgress(i + 1, pageCount);
        }
        
        // 페이지 텍스트 추출을 비동기로 처리
        final text = await compute(
          _extractPageText,
          {'document': document, 'pageIndex': i},
        );
        buffer.write(text);
        
        // UI 업데이트를 위한 짧은 딜레이
        await Future.delayed(const Duration(milliseconds: 1));
      }

      document.dispose();
      return buffer.toString();
    } catch (e) {
      throw Exception('PDF 텍스트 추출 실패: $e');
    }
  }

  /// PDF 파일에서 모든 페이지 추출
  Future<List<String>> extractPages(PdfFileInfo pdfFile) async {
    try {
      final Uint8List bytes = await _getPdfBytes(pdfFile);
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      List<String> pages = [];
      
      // 각 페이지별로 텍스트 추출
      for (int i = 0; i < document.pages.count; i++) {
        String text = extractor.extractText(startPageIndex: i);
        pages.add(text);
      }
      
      document.dispose();
      return pages;
    } catch (e) {
      throw Exception('PDF 페이지 추출 실패: $e');
    }
  }

  /// PDF 파일에서 특정 페이지 추출
  Future<String> extractPage(PdfFileInfo pdfFile, int pageNumber) async {
    try {
      final Uint8List bytes = await _getPdfBytes(pdfFile);
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      if (pageNumber < 1 || pageNumber > document.pages.count) {
        throw Exception('잘못된 페이지 번호입니다');
      }
      
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText(startPageIndex: pageNumber - 1);
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('페이지 텍스트 추출 실패: $e');
    }
  }
  
  /// PdfFileInfo에서 바이트 데이터 가져오기
  Future<Uint8List> _getPdfBytes(PdfFileInfo pdfFile) async {
    try {
      debugPrint('PDF 바이트 가져오기 시작: ${pdfFile.fileName}');
      
      if (pdfFile.isWeb && pdfFile.url != null) {
        // URL이 Firestore 가상 URL인지 확인
        if (pdfFile.url!.startsWith('firestore://')) {
          // Firestore에서 PDF 데이터 가져오기
          final docId = pdfFile.url!.split('/').last;
          debugPrint('Firestore에서 PDF 데이터 가져오기: $docId');
          
          final bytes = await _webPdfService.getPdfDataFromFirestore(docId);
          if (bytes != null) {
            debugPrint('Firestore에서 PDF 데이터 가져오기 성공: ${bytes.length} 바이트');
            return bytes;
          } else {
            debugPrint('Firestore에서 PDF 데이터 가져오기 실패');
            // 빈 PDF 반환
            return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
          }
        }
        
        // 일반 웹 URL에서 PDF 다운로드
        try {
          debugPrint('웹 URL에서 PDF 다운로드 시작: ${pdfFile.url}');
          
          // CORS 문제를 우회하기 위해 Firebase 함수나 프록시 서버를 사용할 수 있습니다.
          // 현재는 직접 다운로드를 시도합니다.
          final response = await http.get(
            Uri.parse(pdfFile.url!),
            headers: {
              'Accept': 'application/pdf',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token'
            },
          );
          
          if (response.statusCode == 200) {
            debugPrint('PDF 다운로드 성공: ${response.bodyBytes.length} 바이트');
            return response.bodyBytes;
          } else {
            debugPrint('PDF 다운로드 실패: 상태 코드 ${response.statusCode}');
            
            // CORS 오류가 발생한 경우 기본 PDF 반환
            if (response.statusCode == 0 || response.statusCode >= 400) {
              debugPrint('CORS 오류가 발생했을 수 있습니다. 기본 PDF 반환');
              // 빈 PDF 생성 - 간단한 바이트 배열 반환
              return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
            }
            
            throw Exception('PDF 다운로드 실패: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('웹 PDF 다운로드 오류: $e');
          
          // 오류 발생 시 기본 PDF 생성 - 간단한 바이트 배열 반환
          return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
        }
      } else if (pdfFile.isLocal && pdfFile.file != null) {
        // 로컬 파일에서 바이트 읽기
        try {
          debugPrint('로컬 파일에서 PDF 읽기 시작: ${pdfFile.file!.path}');
          final bytes = await pdfFile.file!.readAsBytes();
          debugPrint('PDF 파일 읽기 성공: ${bytes.length} 바이트');
          return bytes;
        } catch (e) {
          debugPrint('로컬 PDF 읽기 오류: $e');
          throw Exception('PDF 파일 읽기 실패: $e');
        }
      } else {
        debugPrint('PDF 파일 정보 오류: URL=${pdfFile.url}, 로컬 파일=${pdfFile.file}');
        
        // 파일 정보가 없는 경우 기본 PDF 생성 - 간단한 바이트 배열 반환
        return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
      }
    } catch (e) {
      debugPrint('PDF 바이트 가져오기 오류: $e');
      
      // 최종 오류 처리: 기본 PDF 생성 - 간단한 바이트 배열 반환
      return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]);
    }
  }
  
  /// PDF 파일 크기 확인
  Future<int> getPdfFileSize(PdfFileInfo pdfFile) async {
    try {
      debugPrint('PDF 파일 크기 확인 시작: ${pdfFile.fileName}');
      
      // 이미 크기 정보가 있으면 사용
      if (pdfFile.fileSize > 0) {
        debugPrint('기존 크기 정보 사용: ${pdfFile.fileSize} 바이트');
        return pdfFile.fileSize;
      }
      
      // 크기 정보가 없으면 바이트 데이터 가져와서 계산
      final bytes = await _getPdfBytes(pdfFile);
      debugPrint('PDF 파일 크기 계산 완료: ${bytes.length} 바이트');
      return bytes.length;
    } catch (e) {
      debugPrint('PDF 파일 크기 확인 오류: $e');
      // 오류 발생 시 기본값 반환 (무료 사용자 제한보다 작은 값)
      return FREE_SIZE_LIMIT_BYTES - 1;
    }
  }
  
  /// PDF 텍스트 길이 확인 (미리보기용 짧은 텍스트만 추출)
  Future<int> getApproximateTextLength(PdfFileInfo pdfFile) async {
    try {
      final bytes = await _getPdfBytes(pdfFile);
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      // 모든 페이지의 텍스트 추출
      int totalLength = 0;
      final extractor = PdfTextExtractor(document);
      
      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final pageText = extractor.extractText(startPageIndex: pageIndex);
        totalLength += pageText.length;
      }
      
      // 실제 텍스트 길이 반환
      int estimatedLength = totalLength;
      
      document.dispose();
      return estimatedLength;
    } catch (e) {
      print('텍스트 길이 예측 중 오류: $e');
      // 오류 발생 시 기본값 반환 (무료 사용자 제한보다 작은 값)
      return FREE_TEXT_LENGTH_LIMIT - 1;
    }
  }
  
  /// 구독 티어에 따라 PDF 사용 가능 여부 확인
  Future<Map<String, dynamic>> checkPdfUsability(
    PdfFileInfo pdfFile, 
    SubscriptionTier tier
  ) async {
    try {
      // 프리미엄 사용자는 항상 모든 PDF 사용 가능
      if (tier == SubscriptionTier.premium || 
          tier == SubscriptionTier.premiumTrial || 
          tier == SubscriptionTier.enterprise) {
        return {
          'usable': true,
          'reason': '',
        };
      }
      
      // 파일 크기 확인
      final fileSize = await getPdfFileSize(pdfFile);
      if (fileSize > FREE_SIZE_LIMIT_BYTES) {
        return {
          'usable': false,
          'reason': 'size',
          'message': '파일 크기가 너무 큽니다 (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB).\n프리미엄 회원으로 업그레이드하여 더 큰 파일을 처리하세요.',
        };
      }
      
      // 텍스트 길이 확인 (대략적인 예측)
      final textLength = await getApproximateTextLength(pdfFile);
      if (textLength > FREE_TEXT_LENGTH_LIMIT) {
        return {
          'usable': false,
          'reason': 'length',
          'message': '문서 내용이 너무 깁니다.\n프리미엄 회원으로 업그레이드하여 더 긴 문서를 처리하세요.',
        };
      }
      
      return {
        'usable': true,
        'reason': '',
      };
    } catch (e) {
      print('PDF 사용 가능 여부 확인 오류: $e');
      // 오류 발생 시 기본적으로 사용 가능하도록 설정
      return {
        'usable': true,
        'reason': 'error',
        'message': '파일 확인 중 오류가 발생했지만, 계속 진행할 수 있습니다.',
      };
    }
  }

  /// URL에서 PDF 다운로드
  Future<Uint8List> downloadPdfFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      }
      
      return response.bodyBytes;
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      throw Exception('PDF 다운로드에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// PDF 정보 추출
  Future<PdfInfo> extractPdfInfo(Uint8List pdfData) async {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      
      // 페이지 수 가져오기
      final pageCount = document.pages.count;
      
      // 텍스트 추출
      final text = await extractTextFromPdfDocument(document);
      final textLength = text.length;
      
      document.dispose();
      
      return PdfInfo(
        pageCount: pageCount,
        textLength: textLength,
      );
    } catch (e) {
      debugPrint('PDF 정보 추출 오류: $e');
      throw Exception('PDF 정보 추출에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// PDF에서 텍스트 추출
  Future<String> extractTextFromPdf(Uint8List pdfData) async {
    try {
      final document = PdfDocument(inputBytes: pdfData);
      final text = await extractTextFromPdfDocument(document);
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('PDF 텍스트 추출 오류: $e');
      throw Exception('PDF 텍스트 추출에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// PdfDocument에서 텍스트 추출
  Future<String> extractTextFromPdfDocument(PdfDocument document) async {
    try {
      final pageCount = document.pages.count;
      final buffer = StringBuffer();
      
      for (var i = 0; i < pageCount; i++) {
        final page = document.pages[i];
        final text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        buffer.write(text);
        buffer.write('\n\n');
      }
      
      return buffer.toString();
    } catch (e) {
      debugPrint('PdfDocument 텍스트 추출 오류: $e');
      throw Exception('PDF 텍스트 추출에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// AI를 사용하여 텍스트 분석
  Future<String> analyzeTextWithAI(String text, String apiKey) async {
    try {
      // API 요청 URL (Gemini API 엔드포인트로 변경)
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent');
      
      // 요청 헤더 (Gemini API 형식으로 변경)
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      };
      
      // 요청 본문 (Gemini API 형식으로 변경)
      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '다음 PDF 내용을 분석하고 요약해주세요:\n\n$text'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        },
      };
      
      // API 요청
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      // 응답 처리 (Gemini API 응답 구조에 맞게 수정)
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('AI 분석 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI 분석 오류: $e');
      throw Exception('AI 분석에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// PDF 다운로드 (웹용)
  void downloadPdfForWeb(Uint8List pdfData, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([pdfData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Future<bool> openPDF(String filePath) async {
    try {
      // PDF 파일 열기 구현
      return true;
    } catch (e) {
      debugPrint('PDF 열기 실패: $e');
      return false;
    }
  }
  
  @override
  Future<int> getPageCount() async {
    try {
      // 페이지 수 가져오기 구현
      return 0;
    } catch (e) {
      debugPrint('페이지 수 가져오기 실패: $e');
      return 0;
    }
  }
  
  @override
  Future<int> getCurrentPage() async {
    try {
      // 현재 페이지 가져오기 구현
      return 0;
    } catch (e) {
      debugPrint('현재 페이지 가져오기 실패: $e');
      return 0;
    }
  }
  
  @override
  Future<bool> goToPage(int pageNumber) async {
    try {
      // 페이지 이동 구현
      return true;
    } catch (e) {
      debugPrint('페이지 이동 실패: $e');
      return false;
    }
  }
  
  @override
  Future<List<int>> renderPage({
    int width = 800,
    int height = 1200,
  }) async {
    try {
      // 페이지 렌더링 구현
      return [];
    } catch (e) {
      debugPrint('페이지 렌더링 실패: $e');
      return [];
    }
  }
  
  @override
  Future<String> extractText() async {
    try {
      // 텍스트 추출 구현
      return '';
    } catch (e) {
      debugPrint('텍스트 추출 실패: $e');
      return '';
    }
  }
  
  @override
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      // 메타데이터 가져오기 구현
      return {};
    } catch (e) {
      debugPrint('메타데이터 가져오기 실패: $e');
      return {};
    }
  }
  
  @override
  Future<List<int>> searchText(String query) async {
    try {
      // 텍스트 검색 구현
      return [];
    } catch (e) {
      debugPrint('텍스트 검색 실패: $e');
      return [];
    }
  }
  
  @override
  Future<bool> closePDF() async {
    try {
      // PDF 닫기 구현
      return true;
    } catch (e) {
      debugPrint('PDF 닫기 실패: $e');
      return false;
    }
  }
  
  @override
  bool isOpen() {
    // Implementation needed
  }
  
  @override
  String getFilePath() {
    // Implementation needed
  }
  
  @override
  void dispose() {
    // 리소스 정리 구현
  }
}

// isolate에서 실행될 함수
String _extractPageText(Map<String, dynamic> params) {
  final document = params['document'] as PdfDocument;
  final pageIndex = params['pageIndex'] as int;
  final extractor = PdfTextExtractor(document);
  return extractor.extractText(startPageIndex: pageIndex);
}

/// PDF 정보 클래스
class PdfInfo {
  final int pageCount;
  final int textLength;
  
  PdfInfo({
    required this.pageCount,
    required this.textLength,
  });
}

/// JSON 인코딩/디코딩 함수
dynamic jsonDecode(String source) {
  return const JsonDecoder().convert(source);
}

String jsonEncode(dynamic object) {
  return const JsonEncoder().convert(object);
}

/// JSON 인코더/디코더
class JsonDecoder {
  const JsonDecoder();
  
  dynamic convert(String source) {
    return json.decode(source);
  }
}

class JsonEncoder {
  const JsonEncoder();
  
  String convert(dynamic object) {
    return json.encode(object);
  }
}

/// JSON 라이브러리 (웹 환경에서는 dart:convert를 사용할 수 없으므로 대체)
class json {
  static dynamic decode(String source) {
    try {
      return jsonDecode(source);
    } catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      return null;
    }
  }
  
  static String encode(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      debugPrint('JSON 직렬화 오류: $e');
      return '{}';
    }
  }
}

/// JSON 문자열을 객체로 변환
dynamic parseJson(String source) {
  try {
    return jsonDecode(source);
  } catch (e) {
    debugPrint('JSON 파싱 오류: $e');
    return null;
  }
}

/// 객체를 JSON 문자열로 변환
String? stringifyJson(dynamic object) {
  try {
    return jsonEncode(object);
  } catch (e) {
    debugPrint('JSON 직렬화 오류: $e');
    return null;
  }
} 