// Mocks generated by Mockito 5.4.5 from annotations
// in pdf_learner_v2/test/unit/viewmodels/pdf_viewer_viewmodel_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:io' as _i5;

import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i8;
import 'package:pdf_learner_v2/core/services/pdf_service.dart' as _i7;
import 'package:pdf_learner_v2/data/datasources/pdf_local_datasource.dart'
    as _i9;
import 'package:pdf_learner_v2/domain/models/pdf_bookmark.dart' as _i6;
import 'package:pdf_learner_v2/domain/models/pdf_document.dart' as _i2;
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakePDFDocument_0 extends _i1.SmartFake implements _i2.PDFDocument {
  _FakePDFDocument_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [PDFRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockPDFRepository extends _i1.Mock implements _i3.PDFRepository {
  MockPDFRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.PDFDocument?> getDocument(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#getDocument, [id]),
            returnValue: _i4.Future<_i2.PDFDocument?>.value(),
          )
          as _i4.Future<_i2.PDFDocument?>);

  @override
  _i4.Future<List<_i2.PDFDocument>> getDocuments() =>
      (super.noSuchMethod(
            Invocation.method(#getDocuments, []),
            returnValue: _i4.Future<List<_i2.PDFDocument>>.value(
              <_i2.PDFDocument>[],
            ),
          )
          as _i4.Future<List<_i2.PDFDocument>>);

  @override
  _i4.Future<_i2.PDFDocument> importPDF(_i5.File? file) =>
      (super.noSuchMethod(
            Invocation.method(#importPDF, [file]),
            returnValue: _i4.Future<_i2.PDFDocument>.value(
              _FakePDFDocument_0(this, Invocation.method(#importPDF, [file])),
            ),
          )
          as _i4.Future<_i2.PDFDocument>);

  @override
  _i4.Future<_i2.PDFDocument> updateDocument(_i2.PDFDocument? document) =>
      (super.noSuchMethod(
            Invocation.method(#updateDocument, [document]),
            returnValue: _i4.Future<_i2.PDFDocument>.value(
              _FakePDFDocument_0(
                this,
                Invocation.method(#updateDocument, [document]),
              ),
            ),
          )
          as _i4.Future<_i2.PDFDocument>);

  @override
  _i4.Future<bool> deleteDocument(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#deleteDocument, [id]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<List<_i6.PDFBookmark>> getBookmarks(String? documentId) =>
      (super.noSuchMethod(
            Invocation.method(#getBookmarks, [documentId]),
            returnValue: _i4.Future<List<_i6.PDFBookmark>>.value(
              <_i6.PDFBookmark>[],
            ),
          )
          as _i4.Future<List<_i6.PDFBookmark>>);

  @override
  _i4.Future<void> addBookmark(_i6.PDFBookmark? bookmark) =>
      (super.noSuchMethod(
            Invocation.method(#addBookmark, [bookmark]),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> deleteBookmark(String? bookmarkId) =>
      (super.noSuchMethod(
            Invocation.method(#deleteBookmark, [bookmarkId]),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );

  @override
  _i4.Future<_i2.PDFDocument> addDocument(_i2.PDFDocument? document) =>
      (super.noSuchMethod(
            Invocation.method(#addDocument, [document]),
            returnValue: _i4.Future<_i2.PDFDocument>.value(
              _FakePDFDocument_0(
                this,
                Invocation.method(#addDocument, [document]),
              ),
            ),
          )
          as _i4.Future<_i2.PDFDocument>);
}

/// A class which mocks [PDFService].
///
/// See the documentation for Mockito's code generation for more information.
class MockPDFService extends _i1.Mock implements _i7.PDFService {
  MockPDFService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<bool> openPDF(_i5.File? file) =>
      (super.noSuchMethod(
            Invocation.method(#openPDF, [file]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<int> getPageCount() =>
      (super.noSuchMethod(
            Invocation.method(#getPageCount, []),
            returnValue: _i4.Future<int>.value(0),
          )
          as _i4.Future<int>);

  @override
  _i4.Future<int> getCurrentPage() =>
      (super.noSuchMethod(
            Invocation.method(#getCurrentPage, []),
            returnValue: _i4.Future<int>.value(0),
          )
          as _i4.Future<int>);

  @override
  _i4.Future<bool> goToPage(int? pageNumber) =>
      (super.noSuchMethod(
            Invocation.method(#goToPage, [pageNumber]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<List<int>> renderPage() =>
      (super.noSuchMethod(
            Invocation.method(#renderPage, []),
            returnValue: _i4.Future<List<int>>.value(<int>[]),
          )
          as _i4.Future<List<int>>);

  @override
  _i4.Future<String> extractText() =>
      (super.noSuchMethod(
            Invocation.method(#extractText, []),
            returnValue: _i4.Future<String>.value(
              _i8.dummyValue<String>(this, Invocation.method(#extractText, [])),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<Map<String, dynamic>> getMetadata() =>
      (super.noSuchMethod(
            Invocation.method(#getMetadata, []),
            returnValue: _i4.Future<Map<String, dynamic>>.value(
              <String, dynamic>{},
            ),
          )
          as _i4.Future<Map<String, dynamic>>);

  @override
  _i4.Future<List<Map<String, dynamic>>> searchText(String? query) =>
      (super.noSuchMethod(
            Invocation.method(#searchText, [query]),
            returnValue: _i4.Future<List<Map<String, dynamic>>>.value(
              <Map<String, dynamic>>[],
            ),
          )
          as _i4.Future<List<Map<String, dynamic>>>);

  @override
  _i4.Future<bool> closePDF() =>
      (super.noSuchMethod(
            Invocation.method(#closePDF, []),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [PDFLocalDataSource].
///
/// See the documentation for Mockito's code generation for more information.
class MockPDFLocalDataSource extends _i1.Mock
    implements _i9.PDFLocalDataSource {
  MockPDFLocalDataSource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<bool> saveDocument(dynamic document) =>
      (super.noSuchMethod(
            Invocation.method(#saveDocument, [document]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<dynamic> getDocument(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#getDocument, [id]),
            returnValue: _i4.Future<dynamic>.value(),
          )
          as _i4.Future<dynamic>);

  @override
  _i4.Future<List<dynamic>> getAllDocuments() =>
      (super.noSuchMethod(
            Invocation.method(#getAllDocuments, []),
            returnValue: _i4.Future<List<dynamic>>.value(<dynamic>[]),
          )
          as _i4.Future<List<dynamic>>);

  @override
  _i4.Future<bool> deleteDocument(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#deleteDocument, [id]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> updateDocument(dynamic document) =>
      (super.noSuchMethod(
            Invocation.method(#updateDocument, [document]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> saveBookmark(String? documentId, dynamic bookmark) =>
      (super.noSuchMethod(
            Invocation.method(#saveBookmark, [documentId, bookmark]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<List<dynamic>> getBookmarks(String? documentId) =>
      (super.noSuchMethod(
            Invocation.method(#getBookmarks, [documentId]),
            returnValue: _i4.Future<List<dynamic>>.value(<dynamic>[]),
          )
          as _i4.Future<List<dynamic>>);

  @override
  _i4.Future<bool> deleteBookmark(String? documentId, String? bookmarkId) =>
      (super.noSuchMethod(
            Invocation.method(#deleteBookmark, [documentId, bookmarkId]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> saveFile(String? path, List<int>? bytes) =>
      (super.noSuchMethod(
            Invocation.method(#saveFile, [path, bytes]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> deleteFile(String? path) =>
      (super.noSuchMethod(
            Invocation.method(#deleteFile, [path]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> fileExists(String? path) =>
      (super.noSuchMethod(
            Invocation.method(#fileExists, [path]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<int> getFileSize(String? path) =>
      (super.noSuchMethod(
            Invocation.method(#getFileSize, [path]),
            returnValue: _i4.Future<int>.value(0),
          )
          as _i4.Future<int>);

  @override
  _i4.Future<bool> clearCache() =>
      (super.noSuchMethod(
            Invocation.method(#clearCache, []),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);
}
