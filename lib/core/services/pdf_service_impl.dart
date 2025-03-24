import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'pdf_service.dart';

/// PDFService의 구현체
class PDFServiceImpl implements PDFService {
  File? _pdfFile;
  pw.Document? _document;
  int _currentPage = 0;
  final _lock = Lock();
  bool _isDisposed = false;

  @override
  Future<bool> openPDF(File file) async {
    if (_isDisposed) return false;

    return await _lock.synchronized(() async {
      try {
        _pdfFile = file;
        final bytes = await file.readAsBytes();
        _document = pw.Document.load(bytes);
        _currentPage = 0;
        return true;
      } catch (e) {
        print('PDF 파일 열기 실패: $e');
        return false;
      }
    });
  }

  @override
  Future<int> getPageCount() async {
    if (_isDisposed || _document == null) return 0;

    return await _lock.synchronized(() async {
      try {
        return _document!.pdfDocument.pages.length;
      } catch (e) {
        print('페이지 수 가져오기 실패: $e');
        return 0;
      }
    });
  }

  @override
  Future<int> getCurrentPage() async {
    if (_isDisposed) return 0;
    return _currentPage;
  }

  @override
  Future<bool> goToPage(int pageNumber) async {
    if (_isDisposed || _document == null) return false;

    return await _lock.synchronized(() async {
      try {
        final pageCount = await getPageCount();
        if (pageNumber < 0 || pageNumber >= pageCount) {
          return false;
        }
        _currentPage = pageNumber;
        return true;
      } catch (e) {
        print('페이지 이동 실패: $e');
        return false;
      }
    });
  }

  @override
  Future<List<int>> renderPage() async {
    if (_isDisposed || _document == null) return [];

    return await _lock.synchronized(() async {
      try {
        final page = _document!.pdfDocument.pages[_currentPage];
        final pageImage = await page.render(
          format: PdfPageImageFormat.png,
          width: page.width.toInt(),
          height: page.height.toInt(),
        );
        return pageImage?.bytes ?? [];
      } catch (e) {
        print('페이지 렌더링 실패: $e');
        return [];
      }
    });
  }

  @override
  Future<String> extractText() async {
    if (_isDisposed || _document == null) return '';

    return await _lock.synchronized(() async {
      try {
        final page = _document!.pdfDocument.pages[_currentPage];
        return await page.text;
      } catch (e) {
        print('텍스트 추출 실패: $e');
        return '';
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getMetadata() async {
    if (_isDisposed || _document == null) {
      return {};
    }

    return await _lock.synchronized(() async {
      try {
        final info = _document!.pdfDocument.info;
        return {
          'title': info.title ?? '',
          'author': info.author ?? '',
          'subject': info.subject ?? '',
          'keywords': info.keywords ?? [],
          'creator': info.creator ?? '',
          'producer': info.producer ?? '',
          'creationDate': info.creationDate,
          'modificationDate': info.modificationDate,
        };
      } catch (e) {
        print('메타데이터 가져오기 실패: $e');
        return {};
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> searchText(String query) async {
    if (_isDisposed || _document == null || query.isEmpty) {
      return [];
    }

    return await _lock.synchronized(() async {
      try {
        final results = <Map<String, dynamic>>[];
        final pageCount = await getPageCount();

        for (var i = 0; i < pageCount; i++) {
          final page = _document!.pdfDocument.pages[i];
          final text = await page.text;
          
          if (text.toLowerCase().contains(query.toLowerCase())) {
            results.add({
              'page': i,
              'text': text,
            });
          }
        }

        return results;
      } catch (e) {
        print('텍스트 검색 실패: $e');
        return [];
      }
    });
  }

  @override
  Future<bool> closePDF() async {
    if (_isDisposed) return false;

    return await _lock.synchronized(() async {
      try {
        _document?.dispose();
        _document = null;
        _pdfFile = null;
        _currentPage = 0;
        return true;
      } catch (e) {
        print('PDF 파일 닫기 실패: $e');
        return false;
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    closePDF();
  }
} 