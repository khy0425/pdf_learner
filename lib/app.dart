class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: context.read<AuthService>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          
          return snapshot.hasData
              ? const DesktopHomePage()  // 로그인된 경우
              : const LoginScreen();     // 로그인되지 않은 경우
        },
      ),
    );
  }
} 