import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// PDF 관련 유틸리티 함수들
class PdfUtils {
  /// URL에서 PDF 데이터를 바이트 배열로 가져오기
  static Future<Uint8List?> getPdfBytesFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('PDF 다운로드 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('PDF 다운로드 중 오류: $e');
      return null;
    }
  }

  /// 파일에서 PDF 데이터를 바이트 배열로 가져오기
  static Future<Uint8List?> getPdfBytesFromFile(File file) async {
    try {
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        debugPrint('파일이 존재하지 않음: ${file.path}');
        return null;
      }
    } catch (e) {
      debugPrint('파일 읽기 중 오류: $e');
      return null;
    }
  }

  /// 임시 PDF 파일 생성
  static Future<File?> createTempPdfFile(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(tempDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return file;
    } catch (e) {
      debugPrint('임시 파일 생성 중 오류: $e');
      return null;
    }
  }

  /// 파일 경로에서 파일 이름 추출
  static String getFileNameFromPath(String filePath) {
    return p.basename(filePath);
  }

  /// 파일 확장자 확인 (PDF 인지)
  static bool isPdfFile(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return extension == '.pdf';
  }

  /// 파일 크기 계산 (MB 단위)
  static Future<double> getFileSizeInMB(File file) async {
    try {
      final bytes = await file.length();
      return bytes / (1024 * 1024); // 바이트를 MB로 변환
    } catch (e) {
      debugPrint('파일 크기 계산 중 오류: $e');
      return 0.0;
    }
  }

  /// 파일 크기 계산 (MB 단위, 바이트 배열에서)
  static double getByteSizeInMB(Uint8List bytes) {
    return bytes.length / (1024 * 1024); // 바이트를 MB로 변환
  }

  /// 파일 크기 포맷 (읽기 쉬운 형태로)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return '$gb GB';
    }
  }
} 