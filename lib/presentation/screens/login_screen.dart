class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('이메일로 로그인'),
              onPressed: () {
                // 이메일 로그인 화면으로 이동
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Google로 로그인'),
              onPressed: () {
                context.read<AuthService>().signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }
} 