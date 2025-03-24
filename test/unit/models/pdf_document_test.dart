import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';

void main() {
  group('PDFDocument 모델 테스트', () {
    late PDFDocument document;

    setUp(() {
      document = PDFDocument(
        id: 'test_id',
        title: '테스트 문서',
        filePath: '/test/path/document.pdf',
        fileSize: 1024,
        totalPages: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('문서 생성 테스트', () {
      expect(document.id, 'test_id');
      expect(document.title, '테스트 문서');
      expect(document.filePath, '/test/path/document.pdf');
      expect(document.fileSize, 1024);
      expect(document.totalPages, 10);
    });

    test('문서 복사 테스트', () {
      final copiedDocument = document.copyWith(
        title: '수정된 제목',
        description: '새로운 설명',
      );

      expect(copiedDocument.id, document.id);
      expect(copiedDocument.title, '수정된 제목');
      expect(copiedDocument.description, '새로운 설명');
      expect(copiedDocument.filePath, document.filePath);
    });

    test('문서 유효성 검사 테스트', () {
      expect(document.isValid(), true);

      final invalidDocument = document.copyWith(
        id: '',
        title: '',
        filePath: '',
        fileSize: 0,
        totalPages: 0,
      );

      expect(invalidDocument.isValid(), false);
    });
  });
} 