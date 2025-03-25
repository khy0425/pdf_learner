import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/presentation/services/rate_limiter.dart';
import 'package:pdf_learner_v2/presentation/services/api_key_service.dart';
import 'package:pdf_learner_v2/core/utils/web_utils.dart';

@singleton
class ThumbnailService {
  final PDFRepository _pdfRepository;
  final RateLimiter _rateLimiter;
  final ApiKeyService _apiKeyService;

  ThumbnailService(
    this._pdfRepository,
    this._rateLimiter,
    this._apiKeyService,
  );

  Future<String> get _thumbnailPath async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailDir = Directory(path.join(directory.path, 'thumbnails'));
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    return thumbnailDir.path;
  }

  /// PDF 썸네일 생성
  Future<Uint8List?> generateThumbnail(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $filePath');
      }

      // TODO: PDF 첫 페이지에서 이미지 추출 로직 구현
      // 현재는 임시로 빈 이미지 반환
      return Uint8List(0);
    } catch (e) {
      throw Exception('Failed to generate thumbnail: $e');
    }
  }

  /// 썸네일 저장
  Future<String> saveThumbnail(Uint8List bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final thumbnailPath = '${directory.path}/thumbnails/$fileName';
      
      // 디렉토리 생성
      await Directory('${directory.path}/thumbnails').create(recursive: true);
      
      // 파일 저장
      final file = File(thumbnailPath);
      await file.writeAsBytes(bytes);
      
      return thumbnailPath;
    } catch (e) {
      throw Exception('Failed to save thumbnail: $e');
    }
  }

  /// 썸네일 로드
  Future<Uint8List?> loadThumbnail(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to load thumbnail: $e');
    }
  }

  /// 썸네일 삭제
  Future<bool> deleteThumbnail(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('썸네일 삭제 실패: $e');
      return false;
    }
  }

  Future<Uint8List?> extractImage(String filePath, {int pageNumber = 0}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $filePath');
      }

      // TODO: PDF에서 이미지 추출 로직 구현
      // 현재는 임시로 빈 이미지 반환
      return Uint8List(0);
    } catch (e) {
      throw Exception('Failed to extract image: $e');
    }
  }
} 