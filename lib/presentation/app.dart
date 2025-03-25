import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/pdf_viewmodel.dart';
import 'views/login_page.dart';
import 'screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => GetIt.I<AuthViewModel>(),
        ),
        ChangeNotifierProvider<PDFViewModel>(
          create: (_) => GetIt.I<PDFViewModel>(),
        ),
      ],
      child: MaterialApp(
        title: 'PDF Learner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
} 