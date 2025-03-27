import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 문제 진단을 위한 최소한의 테스트 앱
/// 실제 앱 기능을 하나씩 추가하면서 문제 원인을 파악하기 위한 용도
class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Learner 테스트',
      debugShowCheckedModeBanner: true, // 디버그 모드 표시 
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({Key? key}) : super(key: key);

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  // 상태 변수
  String _statusMessage = '테스트 앱이 정상적으로 로드되었습니다';
  int _counter = 0;
  bool _isLoading = false;

  // 상태 업데이트 예시
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // 진단 버튼 액션
  void _runDiagnostics() {
    setState(() {
      _isLoading = true;
      _statusMessage = '진단 중...';
    });

    // 간단한 진단 시뮬레이션
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '진단 완료: 앱 기본 기능 정상';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Learner 테스트 앱'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                '테스트 모드',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                const SizedBox(),
              const SizedBox(height: 20),
              Text(
                '카운터: $_counter',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _incrementCounter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('카운터 증가'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _runDiagnostics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('진단 실행'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // 플랫폼 정보
              Text(
                '플랫폼: ${kIsWeb ? "웹" : "네이티브"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (kIsWeb)
                const Text(
                  '웹 배포 테스트 중',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  // Provider 추가 등 다음 단계로 진행
                  setState(() {
                    _statusMessage = '다음 단계 준비 완료: Provider 수정 필요';
                  });
                },
                child: const Text('다음 단계 확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 