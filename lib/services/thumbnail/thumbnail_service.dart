import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/utils/web_utils.dart';

/// PDF 문서의 썸네일을 생성하고 관리하는 서비스
class ThumbnailService {
  /// PDF 문서의 첫 페이지를 썸네일로 생성합니다.
  Future<Uint8List?> generateThumbnail(Uint8List pdfBytes, {int pageNumber = 0}) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      if (document.pages.count <= pageNumber) return null;

      final PdfPage page = document.pages[pageNumber];
      final PdfBitmap bitmap = await page.render(
        width: 200,
        height: 200 * page.size.height / page.size.width,
      );

      return bitmap.bytes;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// PDF 문서의 썸네일을 저장합니다.
  Future<String?> saveThumbnail(Uint8List thumbnailBytes, String documentId) async {
    try {
      if (WebUtils.isWeb()) {
        final base64Data = WebUtils.bytesToBase64(thumbnailBytes);
        WebUtils.saveToLocalStorage('thumbnail_$documentId', base64Data);
        return 'thumbnail_$documentId';
      }
      // TODO: Implement local storage for mobile platforms
      return null;
    } catch (e) {
      print('Error saving thumbnail: $e');
      return null;
    }
  }

  /// PDF 문서의 썸네일을 불러옵니다.
  Future<Uint8List?> loadThumbnail(String documentId) async {
    try {
      if (WebUtils.isWeb()) {
        final base64Data = WebUtils.loadFromLocalStorage('thumbnail_$documentId');
        if (base64Data != null) {
          return WebUtils.base64ToBytes(base64Data);
        }
      }
      // TODO: Implement local storage for mobile platforms
      return null;
    } catch (e) {
      print('Error loading thumbnail: $e');
      return null;
    }
  }

  /// PDF 문서의 썸네일을 삭제합니다.
  Future<void> deleteThumbnail(String documentId) async {
    try {
      if (WebUtils.isWeb()) {
        WebUtils.removeFromLocalStorage('thumbnail_$documentId');
      }
      // TODO: Implement local storage for mobile platforms
    } catch (e) {
      print('Error deleting thumbnail: $e');
    }
  }
} 