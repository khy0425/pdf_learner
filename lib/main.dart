import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pdf_provider.dart';
import 'providers/ai_service_provider.dart';
import 'screens/home_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PDFProvider()),
        ChangeNotifierProvider(create: (_) => AIServiceProvider()),
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
      title: 'AI PDF 학습 도우미',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
} 