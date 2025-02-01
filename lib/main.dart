import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/pdf_provider.dart';
import 'screens/home_page.dart';
import 'screens/desktop_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드
  await dotenv.load(fileName: ".env");
  
  // 윈도우 크기 설정 (데스크톱인 경우)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('AI PDF 학습 도우미');
    setWindowMinSize(const Size(800, 600));
    setWindowMaxSize(Size.infinite);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PDFProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Learner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? const DesktopHomePage()
          : const HomePage(),
    );
  }
} 