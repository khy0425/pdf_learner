import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf_render/pdf_render.dart';
import '../constants/app_constants.dart';
import 'file_utils.dart';

class PDFUtils {
  static Future<int> getPageCount(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = await PdfDocument.openData(bytes);
      return document.pageCount;
    } catch (e) {
      throw Exception('PDF 페이지 수를 가져오는데 실패했습니다: $e');
    }
  }

  static Future<String> generateThumbnail(String filePath, {int pageNumber = 0}) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = await PdfDocument.openData(bytes);
      final page = await document.getPage(pageNumber + 1);
      final image = await page.render(
        width: AppConstants.maxThumbnailSize,
        height: AppConstants.maxThumbnailSize,
      );

      final thumbnailDir = await FileUtils.getThumbnailDirectory();
      final thumbnailPath = FileUtils.generateThumbnailPath(
        FileUtils.getFileName(filePath),
      );
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(image.bytes);

      return thumbnailPath;
    } catch (e) {
      throw Exception('PDF 썸네일을 생성하는데 실패했습니다: $e');
    }
  }

  static Future<List<String>> extractText(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = await PdfDocument.openData(bytes);
      final pageCount = document.pageCount;
      final List<String> texts = [];

      for (var i = 1; i <= pageCount; i++) {
        final page = await document.getPage(i);
        final text = await page.text;
        texts.add(text);
      }

      return texts;
    } catch (e) {
      throw Exception('PDF 텍스트를 추출하는데 실패했습니다: $e');
    }
  }

  static Future<Map<String, dynamic>> getPDFInfo(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = await PdfDocument.openData(bytes);

      return {
        'pageCount': document.pageCount,
        'title': document.title ?? FileUtils.getFileName(filePath),
        'author': document.author ?? '',
        'subject': document.subject ?? '',
        'keywords': document.keywords ?? '',
        'creator': document.creator ?? '',
        'producer': document.producer ?? '',
        'creationDate': document.creationDate?.toIso8601String() ?? '',
        'modificationDate': document.modificationDate?.toIso8601String() ?? '',
      };
    } catch (e) {
      throw Exception('PDF 정보를 가져오는데 실패했습니다: $e');
    }
  }

  static Future<bool> isPDFCorrupted(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      await PdfDocument.openData(bytes);
      return false;
    } catch (e) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> getPageInfo(String filePath, int pageNumber) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = await PdfDocument.openData(bytes);
      final page = await document.getPage(pageNumber + 1);

      return {
        'width': page.width,
        'height': page.height,
        'rotation': page.rotation,
        'text': await page.text,
      };
    } catch (e) {
      throw Exception('페이지 정보를 가져오는데 실패했습니다: $e');
    }
  }
} 