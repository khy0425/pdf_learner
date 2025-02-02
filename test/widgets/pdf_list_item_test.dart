import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_pdf_study_assistant/widgets/pdf_list_item.dart';
import 'package:ai_pdf_study_assistant/providers/pdf_provider.dart';
import 'dart:io';

void main() {
  group('PDFListItem Widget Tests', () {
    testWidgets('renders PDF file name', (WidgetTester tester) async {
      final testFile = File('test.pdf');
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => PDFProvider(),
            child: PDFListItem(pdfFile: testFile),
          ),
        ),
      );

      expect(find.text('test.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (WidgetTester tester) async {
      final testFile = File('test.pdf');
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => PDFProvider(),
            child: PDFListItem(pdfFile: testFile),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('PDF 삭제'), findsOneWidget);
      expect(find.text('이 PDF를 삭제하시겠습니까?'), findsOneWidget);
    });
  });
} 