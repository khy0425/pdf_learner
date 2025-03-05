import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/anonymous_user_service.dart';
import '../services/web_pdf_service.dart';
import '../providers/auth_service.dart';
import '../widgets/signup_prompt_dialog.dart';

/// PDF 파일 정보를 담는 모델 클래스
class PdfFileInfo {
  final String id;
  final String fileName;
  final String? url;
  final File? file;
  final DateTime createdAt;
  final int size;
  
  PdfFileInfo({
    required this.id,
    required this.fileName,
    this.url,
    this.file,
    required this.createdAt,
    required this.size,
  });
  
  bool get isWeb => url != null;
  bool get isLocal => file != null;
}

class PDFProvider with ChangeNotifier {
  List<PdfFileInfo> _pdfFiles = [];
  PdfFileInfo? _currentPdf;
  bool _isLoading = false;
  final AnonymousUserService _anonymousUserService = AnonymousUserService();
  final WebPdfService _webPdfService = WebPdfService();

  List<PdfFileInfo> get pdfFiles => _pdfFiles;
  PdfFileInfo? get currentPdf => _currentPdf;
  bool get isLoading => _isLoading;

  /// PDF 파일 추가 및 무료 사용 한도 확인
  Future<void> addPDF(dynamic file, [BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kIsWeb) {
        // 웹 환경에서는 WebPdfService 사용
        if (context != null) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final userId = authService.currentUser?.id ?? await _anonymousUserService.getAnonymousUserId();
          
          if (file is PlatformFile) {
            final bytes = file.bytes!;
            final fileName = file.name;
            
            final downloadUrl = await _webPdfService.uploadPdfWeb(bytes, fileName, userId);
            
            final newPdf = PdfFileInfo(
              id: DateTime.now().millisecondsSinceEpoch.toString(), // 임시 ID
              fileName: fileName,
              url: downloadUrl,
              createdAt: DateTime.now(),
              size: bytes.length,
            );
            
            _pdfFiles.add(newPdf);
            _currentPdf = newPdf;
          }
        }
      } else {
        // 네이티브 환경에서는 기존 로직 사용
        if (file is File) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(file.path);
          final savedFile = await file.copy(path.join(appDir.path, fileName));
          
          final newPdf = PdfFileInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: fileName,
            file: savedFile,
            createdAt: DateTime.now(),
            size: await savedFile.length(),
          );
          
          _pdfFiles.add(newPdf);
          _currentPdf = newPdf;
        }
      }
      
      // 무료 사용 횟수 증가
      await _anonymousUserService.incrementUsageCount();
      
      // 무료 사용 한도 확인 및 회원가입 다이얼로그 표시
      if (context != null) {
        await SignUpPromptDialog.show(context);
      }
      
    } catch (e) {
      debugPrint('PDF 파일 추가 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentPDF(PdfFileInfo file) {
    _currentPdf = file;
    notifyListeners();
  }

  // 저장된 PDF 파일들 로드
  Future<void> loadSavedPDFs([BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kIsWeb) {
        // 웹 환경에서는 Firestore에서 PDF 목록 로드
        if (context != null) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final userId = authService.currentUser?.id ?? await _anonymousUserService.getAnonymousUserId();
          
          final pdfList = await _webPdfService.getUserPdfs(userId);
          _pdfFiles = pdfList.map((pdf) => PdfFileInfo(
            id: pdf['id'],
            fileName: pdf['fileName'],
            url: pdf['url'],
            createdAt: (pdf['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            size: pdf['size'] ?? 0,
          )).toList();
        }
      } else {
        // 네이티브 환경에서는 로컬 파일 시스템에서 PDF 목록 로드
        final appDir = await getApplicationDocumentsDirectory();
        final files = appDir.listSync();
        _pdfFiles = files
            .where((file) => file.path.toLowerCase().endsWith('.pdf'))
            .map((fileEntity) {
              final file = File(fileEntity.path);
              return PdfFileInfo(
                id: path.basename(file.path),
                fileName: path.basename(file.path),
                file: file,
                createdAt: DateTime.now(),
                size: file.lengthSync(),
              );
            })
            .toList();
      }
          
    } catch (e) {
      debugPrint('PDF 파일 로드 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePDF(PdfFileInfo pdfInfo, [BuildContext? context]) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kIsWeb) {
        // 웹 환경에서는 WebPdfService 사용
        if (context != null) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final userId = authService.currentUser?.id ?? await _anonymousUserService.getAnonymousUserId();
          
          await _webPdfService.deletePdf(pdfInfo.id, userId);
        }
      } else {
        // 네이티브 환경에서는 로컬 파일 삭제
        if (pdfInfo.file != null) {
          await pdfInfo.file!.delete();
        }
      }
      
      _pdfFiles.remove(pdfInfo);
      
      if (_currentPdf == pdfInfo) {
        _currentPdf = null;
      }
    } catch (e) {
      debugPrint('PDF 파일 삭제 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PDF 파일 선택 및 추가
  Future<void> pickPDF(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // 웹 환경에서는 파일 데이터 필요
    );

    if (result != null) {
      if (kIsWeb) {
        await addPDF(result.files.first, context);
      } else {
        final file = File(result.files.single.path!);
        await addPDF(file, context);
      }
    }
  }
} 