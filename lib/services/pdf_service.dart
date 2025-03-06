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
}

// isolate에서 실행될 함수
String _extractPageText(Map<String, dynamic> params) {
  final document = params['document'] as PdfDocument;
  final pageIndex = params['pageIndex'] as int;
  final extractor = PdfTextExtractor(document);
  return extractor.extractText(startPageIndex: pageIndex);
} 