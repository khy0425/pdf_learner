import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_document/pdf_document.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class PDFRepositoryImpl {
  final FirebaseService _firebaseService;

  PDFRepositoryImpl(this._firebaseService);

  @override
  Future<PDFDocument?> pickAndUploadPDF() async {
    try {
      // 파일 선택 - 웹 환경인지 네이티브 환경인지 확인하여 처리
      File? file;
      Uint8List? bytes;
      bool isWeb = kIsWeb;
      
      if (isWeb) {
        // 웹 환경일 경우
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        
        if (result == null || result.files.isEmpty) return null;
        
        bytes = result.files.first.bytes;
        if (bytes == null) return null;
      } else {
        // 네이티브 환경일 경우
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        
        if (result == null || result.files.isEmpty || result.files.first.path == null) 
          return null;
        
        file = File(result.files.first.path!);
        if (!await file.exists()) return null;
      }
      
      // 선택된 파일 이름 가져오기
      final fileName = isWeb 
          ? FilePicker.platform.pickFiles().then((value) => value?.files.first.name ?? 'document.pdf')
          : file!.path.split('/').last;
      
      // PDF 문서 정보 추출
      int pageCount = 0;
      try {
        if (isWeb) {
          final pdfDoc = await PdfDocument.openData(bytes!);
          pageCount = pdfDoc.pageCount;
          pdfDoc.dispose();
        } else {
          final pdfDoc = await PdfDocument.openFile(file!.path);
          pageCount = pdfDoc.pageCount;
          pdfDoc.dispose();
        }
      } catch (e) {
        // PDF 파싱 오류 처리
        pageCount = 1; // 기본값 설정
      }
      
      // 파일 업로드
      String downloadUrl = '';
      String filePath = '';
      
      if (isWeb) {
        // 웹 환경에서 bytes 업로드
        downloadUrl = await _firebaseService.uploadBytes(
          bytes!,
          'pdfs/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        filePath = downloadUrl; // 웹에서는 URL을 파일 경로로 사용
      } else {
        // 네이티브 환경에서 파일 업로드
        downloadUrl = await _firebaseService.uploadFile(
          file!.path,
          'pdfs/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        
        // 앱 내부 저장소에 파일 복사 (오프라인 액세스용)
        final directory = await getApplicationDocumentsDirectory();
        final savedFile = await file.copy('${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        filePath = savedFile.path;
      }
      
      // 문서 정보 생성 및 Firestore에 저장
      final document = PDFDocument(
        id: const Uuid().v4(),
        title: fileName.replaceAll('.pdf', ''),
        filePath: filePath,
        downloadUrl: downloadUrl,
        pageCount: pageCount,
        currentPage: 0,
        readingProgress: 0.0,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Firestore에 문서 추가
      await _firebaseService.addPDFDocument(document);
      
      return document;
    } catch (e) {
      debugPrint('PDF 선택 및 업로드 중 오류 발생: $e');
      return null;
    }
  }
} 