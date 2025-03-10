import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// PDF 파일 정보를 담는 모델 클래스 - 단순화된 버전
class PdfFileInfo {
  final String id;
  final String fileName;
  final String? url;
  final File? file;
  final DateTime createdAt;
  final int size;
  final Uint8List? bytes;  // 웹에서 사용하는 바이트 데이터
  
  PdfFileInfo({
    required this.id,
    required this.fileName,
    this.url,
    this.file,
    required this.createdAt,
    required this.size,
    this.bytes,
  });
  
  bool get isWeb => url != null;
  bool get isLocal => file != null;
  bool get hasBytes => bytes != null;
  
  // 파일 경로 반환 (로컬 파일인 경우 파일 경로, 웹 파일인 경우 URL)
  String get path => isLocal ? file!.path : (url ?? '');
  
  // Bytes 데이터 읽기 메서드
  Future<Uint8List> readAsBytes() async {
    if (hasBytes) {
      return bytes!;
    } else if (isLocal) {
      return await file!.readAsBytes();
    } else if (isWeb && url != null) {
      // URL에서 파일 다운로드
      try {
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('PDF 파일을 가져올 수 없습니다 (상태 코드: ${response.statusCode})');
        }
      } catch (e) {
        debugPrint('PDF 다운로드 오류: $e');
        throw Exception('PDF 파일을 다운로드하는 중 오류가 발생했습니다: $e');
      }
    } else {
      throw Exception('PDF 파일을 읽을 수 없습니다');
    }
  }
  
  // 미리보기용 URL 생성 (웹용)
  String? get previewUrl {
    if (isWeb && url != null && !url!.startsWith('memory://')) {
      return url;
    }
    return null;
  }
}

/// PDF 파일 관리용 Provider - 단순화된 버전
class PDFProvider with ChangeNotifier {
  List<PdfFileInfo> _pdfFiles = [];
  PdfFileInfo? _currentPdf;
  bool _isLoading = false;

  List<PdfFileInfo> get pdfFiles => _pdfFiles;
  PdfFileInfo? get currentPdf => _currentPdf;
  bool get isLoading => _isLoading;

  // PDF 파일 선택
  Future<void> pickPDF(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null) {
        if (kIsWeb) {
          // 웹에서 선택한 파일 처리
          if (result.files.single.bytes != null) {
            final fileName = result.files.single.name;
            final bytes = result.files.single.bytes!;
            
            final newPdf = PdfFileInfo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: fileName,
              url: 'memory://${DateTime.now().millisecondsSinceEpoch}',
              createdAt: DateTime.now(),
              size: bytes.length,
              bytes: bytes,
            );
            
            _pdfFiles.add(newPdf);
            _currentPdf = newPdf;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF 파일 "$fileName"이(가) 선택되었습니다')),
            );
          }
        } else {
          // 로컬 파일 처리
          final file = File(result.files.single.path!);
          final fileName = result.files.single.name;
          
          final newPdf = PdfFileInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: fileName,
            file: file,
            createdAt: DateTime.now(),
            size: await file.length(),
          );
          
          _pdfFiles.add(newPdf);
          _currentPdf = newPdf;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF 파일 "$fileName"이(가) 선택되었습니다')),
          );
        }
      }
    } catch (e) {
      debugPrint('PDF 파일 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 파일 선택 중 오류가 발생했습니다: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentPDF(PdfFileInfo file) {
    _currentPdf = file;
    notifyListeners();
  }

  // 저장된 PDF 파일들 로드 (샘플 PDF 제거)
  Future<void> loadSavedPDFs([BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 실제 앱에서는 여기서 저장된 PDF 파일들을 로드
      // 예: SharedPreferences나 Firebase에서 로드
      
      // 샘플 PDF 제거 (필요 없다고 하셨으므로)
      // 대신 빈 리스트로 시작
      if (_pdfFiles.isEmpty) {
        _pdfFiles = [];
      }
      
      await Future.delayed(const Duration(milliseconds: 300)); // 짧은 로딩 시뮬레이션
      
    } catch (e) {
      debugPrint('PDF 파일 로드 오류: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 로드 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePDF(PdfFileInfo pdfInfo, [BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _pdfFiles.removeWhere((pdf) => pdf.id == pdfInfo.id);
      
      // 삭제한 PDF가 현재 선택된 PDF라면 현재 PDF 초기화
      if (_currentPdf?.id == pdfInfo.id) {
        _currentPdf = _pdfFiles.isNotEmpty ? _pdfFiles.first : null;
      }
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 "${pdfInfo.fileName}"이(가) 삭제되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 오류: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 