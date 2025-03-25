import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';
import '../../domain/repositories/pdf_repository.dart';
import 'api_key_service.dart';
import 'rate_limiter.dart';

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

  Future<String> generateThumbnail(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('파일이 존재하지 않습니다.');
    }

    final bytes = await file.readAsBytes();
    final fileName = path.basename(filePath);
    final thumbnailPath = await _saveThumbnail(bytes, fileName);
    return thumbnailPath;
  }

  Future<String> _saveThumbnail(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailPath = path.join(directory.path, 'thumbnails', fileName);
    final thumbnailFile = File(thumbnailPath);

    await thumbnailFile.create(recursive: true);
    await thumbnailFile.writeAsBytes(bytes);
    return thumbnailPath;
  }

  Future<Uint8List?> loadThumbnail(String thumbnailPath) async {
    final file = File(thumbnailPath);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  Future<void> deleteThumbnail(String thumbnailPath) async {
    final file = File(thumbnailPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
} 