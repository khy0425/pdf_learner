import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_pdf_study_assistant/widgets/drag_drop_area.dart';
import 'package:ai_pdf_study_assistant/providers/pdf_provider.dart';

void main() {
  group('DragDropArea Widget Tests', () {
    testWidgets('shows upload button and drag drop text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => PDFProvider(),
            child: const Scaffold(
              body: DragDropArea(),
            ),
          ),
        ),
      );

      expect(find.text('PDF 파일을 이곳에 끌어다 놓으세요'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
} 