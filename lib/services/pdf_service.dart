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

class PDFService {
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
      if (pdfFile.size > 0) {
        debugPrint('기존 크기 정보 사용: ${pdfFile.size} 바이트');
        return pdfFile.size;
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
      
      // 샘플링할 페이지 수 (최대 3페이지)
      final pagesToSample = math.min(3, pageCount);
      int sampleLength = 0;
      
      // 첫 페이지, 중간 페이지, 마지막 페이지 샘플링
      for (int i = 0; i < pagesToSample; i++) {
        int pageIndex = 0;
        if (i == 0) pageIndex = 0;
        else if (i == 1) pageIndex = (pageCount / 2).floor();
        else pageIndex = pageCount - 1;
        
        final extractor = PdfTextExtractor(document);
        final pageText = extractor.extractText(startPageIndex: pageIndex);
        sampleLength += pageText.length;
      }
      
      // 전체 텍스트 길이 예측
      double estimatedLengthDouble = (sampleLength / pagesToSample) * pageCount;
      int estimatedLength = estimatedLengthDouble.toInt();
      
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
      // API 요청 URL
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      
      // 요청 헤더
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      
      // 요청 본문
      final body = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '당신은 PDF 문서를 분석하고 요약하는 AI 비서입니다. 주어진 텍스트를 분석하여 핵심 내용을 요약하고, 중요한 정보를 추출하세요.'
          },
          {
            'role': 'user',
            'content': '다음 PDF 내용을 분석하고 요약해주세요:\n\n$text'
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      };
      
      // API 요청
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      // 응답 처리
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
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
    if (kIsWeb) {
      return html.window.JSON.parse(source);
    } else {
      return const JsonDecoder().convert(source);
    }
  }
  
  static String encode(dynamic object) {
    if (kIsWeb) {
      return html.window.JSON.stringify(object);
    } else {
      return const JsonEncoder().convert(object);
    }
  }
} 