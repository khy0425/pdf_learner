import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ai_pdf_study_assistant/main.dart' as app;
import 'package:ai_pdf_study_assistant/widgets/drag_drop_area.dart';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify platform-specific UI', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 플랫폼별 UI 확인
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        expect(find.text('AI PDF 학습 도우미'), findsOneWidget);
        expect(find.byType(DragDropArea), findsOneWidget);
      } else {
        expect(find.byType(FloatingActionButton), findsOneWidget);
      }
    });
  });
} 