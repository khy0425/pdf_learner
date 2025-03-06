import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/anonymous_user_service.dart';
import '../services/web_pdf_service.dart';
import '../services/usage_limiter.dart';
import '../providers/auth_service.dart';
import '../widgets/signup_prompt_dialog.dart';
import '../services/subscription_service.dart';
import 'package:http/http.dart' as http;

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
  
  // 파일 경로 반환 (로컬 파일인 경우 파일 경로, 웹 파일인 경우 URL)
  String get path => isLocal ? file!.path : (url ?? '');
  
  // PDF 파일의 바이트 데이터 읽기
  Future<Uint8List> readAsBytes() async {
    if (isLocal) {
      return await file!.readAsBytes();
    } else if (isWeb && url != null) {
      // Firestore 가상 URL 처리
      if (url!.startsWith('firestore://')) {
        // WebPdfService를 통해 Firestore에서 데이터 가져오기
        final docId = url!.split('/').last;
        final webPdfService = WebPdfService();
        final bytes = await webPdfService.getPdfDataFromFirestore(docId);
        if (bytes != null) {
          return bytes;
        } else {
          throw Exception('Firestore에서 PDF 데이터를 가져올 수 없습니다');
        }
      }
      
      // 일반 웹 URL 처리
      final response = await http.get(Uri.parse(url!));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('PDF 파일을 다운로드할 수 없습니다: ${response.statusCode}');
      }
    } else {
      throw Exception('PDF 파일을 읽을 수 없습니다');
    }
  }
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
            if (file.bytes == null || file.bytes!.isEmpty) {
              debugPrint('PDF 파일 데이터가 비어 있습니다: ${file.name}');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 파일 데이터를 읽을 수 없습니다.')),
                );
              }
              return;
            }
            
            final bytes = file.bytes!;
            final fileName = file.name;
            
            debugPrint('PDF 업로드 시작: 파일명=$fileName, 크기=${bytes.length}바이트');
            
            // 파일 크기 제한 확인 (100MB)
            const maxSizeBytes = 100 * 1024 * 1024;
            if (bytes.length > maxSizeBytes) {
              debugPrint('PDF 파일 크기 초과: ${bytes.length}바이트');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 파일 크기가 너무 큽니다. 100MB 이하의 파일만 업로드할 수 있습니다.')),
                );
              }
              return;
            }
            
            // 업로드 진행 중 메시지 표시
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF 파일을 업로드하는 중입니다...')),
              );
            }
            
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
            
            // 업로드 성공 메시지 표시
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF 파일 "$fileName"이(가) 업로드되었습니다.')),
              );
            }
          } else {
            debugPrint('지원되지 않는 파일 유형: ${file.runtimeType}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('지원되지 않는 파일 유형입니다.')),
              );
            }
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
      // 파일 크기 및 텍스트 길이 제한 확인
      final usageLimiter = Provider.of<UsageLimiter>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 임시 PdfFileInfo 객체 생성
      PdfFileInfo tempPdfInfo;
      if (kIsWeb) {
        tempPdfInfo = PdfFileInfo(
          id: 'temp',
          fileName: result.files.first.name,
          url: null,
          createdAt: DateTime.now(),
          size: result.files.first.size,
        );
      } else {
        final file = File(result.files.single.path!);
        tempPdfInfo = PdfFileInfo(
          id: 'temp',
          fileName: path.basename(file.path),
          file: file,
          createdAt: DateTime.now(),
          size: await file.length(),
        );
      }
      
      // 사용 가능 여부 확인
      final usabilityCheck = await usageLimiter.canUsePdf(tempPdfInfo);
      
      if (!usabilityCheck['usable']) {
        // 사용 불가능한 경우 알림 표시
        if (context.mounted) {
          _showUpgradeDialog(context, usabilityCheck['message']);
        }
        return;
      }
      
      // 사용 가능한 경우 PDF 추가
      if (kIsWeb) {
        await addPDF(result.files.first, context);
      } else {
        final file = File(result.files.single.path!);
        await addPDF(file, context);
      }
    }
  }
  
  /// 업그레이드 안내 다이얼로그 표시
  void _showUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리미엄 기능 필요'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 회원가입 또는 업그레이드 화면으로 이동
              SignUpPromptDialog.show(context, forceShow: true);
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }
} 