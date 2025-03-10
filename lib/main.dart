import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' if (dart.library.html) 'package:pdf_learner/utils/web_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:js' as js;

// 필요한 Provider 및 서비스 추가
import 'providers/pdf_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/tutorial_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_service_provider.dart';
import 'screens/home_page.dart';
import 'screens/pdf_viewer_screen.dart';  // PDF 뷰어 스크린 import 추가

// 로그 중복 방지를 위한 Set
final Set<String> _loggedMessages = <String>{};

// 안전한 로그 출력 함수 - 최소화된 로그만 출력
void secureLog(String message, [Object? data]) {
  // 중요한 로그만 출력 (에러 등)
  if (message.contains('오류') || message.contains('실패') || kDebugMode) {
    debugPrint('$message${data != null ? ': $data' : ''}');
  }
}

// 전역 오류 처리 함수
void _handleError(Object error, StackTrace stack) {
  // 타입 변환 오류 무시
  if (error.toString().contains('type') && error.toString().contains('is not a subtype of type')) {
    return;
  }
  
  // 기타 오류는 기본 오류 처리기로 전달
  FlutterError.presentError(FlutterErrorDetails(
    exception: error,
    stack: stack,
    library: 'PDF Learner',
    context: ErrorDescription('애플리케이션 실행 중'),
  ));
}

void main() async {
  // 전역 오류 처리 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    // 타입 변환 오류 무시
    if (details.exception.toString().contains('type') && 
        details.exception.toString().contains('is not a subtype of type')) {
      return;
    }
    
    // 기타 오류는 기본 오류 처리기로 전달
    FlutterError.presentError(details);
  };
  
  // Zone 오류 처리
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      // 먼저 환경 변수 로드
      await dotenv.load(fileName: ".env");
      
      // 윈도우 크기 설정 (웹이 아닌 경우에만)
      if (!kIsWeb) {
        try {
          if (Platform.isWindows) {
            setWindowTitle('AI PDF 학습 도우미');
            setWindowMinSize(const Size(800, 600));
            setWindowMaxSize(Size.infinite);
          }
        } catch (e) {
          secureLog('윈도우 크기 설정 오류', e);
        }
      }

      // Firebase 초기화
      if (kIsWeb) {
        // 웹에서는 index.html에서 이미 초기화됨
        debugPrint("웹 환경에서 Flutter 초기화");
      } else {
        // 네이티브 환경에서는 Firebase SDK를 통해 초기화
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 앱 실행
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PDFProvider()),
            ChangeNotifierProvider(create: (_) => BookmarkProvider()),
            ChangeNotifierProvider(create: (_) => TutorialProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AIServiceProvider()),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e) {
      secureLog('초기화 오류', e);
      // 오류 발생 시 기본 에러 화면 표시
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('앱 초기화 중 오류가 발생했습니다: $e'),
            ),
          ),
        ),
      );
    }
  }, _handleError);
}

// 앱 구조 단순화
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeProvider 사용 (가능한 경우)
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    
    return MaterialApp(
      title: 'PDF Learner',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// 홈 화면
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _userId = '';
  
  @override
  void initState() {
    super.initState();
    _loadPDFs();
    _getUserInfo();
  }
  
  void _getUserInfo() {
    if (kIsWeb) {
      try {
        // JavaScript에서 현재 로그인된 사용자 확인
        final user = js.context.callMethod('getCurrentFirebaseUser', []);
        if (user != null && user != '') {
          setState(() {
            _userId = user.toString();
          });
          return;
        }
        
        // 저장된 사용자 정보 확인
        final storedUserInfo = _getStoredUserInfo();
        if (storedUserInfo != null && storedUserInfo['userId'] != null) {
          final storedUserId = storedUserInfo['userId'].toString();
          
          if (mounted) {
            setState(() {
              _userId = storedUserId;
            });
          }
        }
      } catch (e) {
        debugPrint('로그인 상태 확인 오류: $e');
      }
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
      }
    }
  }
  
  // 로컬 스토리지에서 사용자 정보 가져오기
  dynamic _getStoredUserInfo() {
    try {
      return js.context.callMethod('getStoredUserInfo', []);
    } catch (e) {
      debugPrint('저장된 사용자 정보 가져오기 오류: $e');
      return null;
    }
  }
  
  // 로그아웃 기능
  void _logout() {
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (kIsWeb) {
        js.context.callMethod('logoutUser', []);
      } else {
        FirebaseAuth.instance.signOut();
      }
      
      // 상태 업데이트
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _userId = '로그아웃됨';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 구글 로그인 기능
  void _googleLogin() {
    try {
      setState(() {
        _isLoading = true;
      });
      
      if (kIsWeb) {
        js.context.callMethod('signInWithGoogle', [])
          .then((result) {
            if (mounted) {
              _getUserInfo();
              setState(() {
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            debugPrint('구글 로그인 오류: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
      } else {
        // 네이티브 환경 로그인 로직 (미구현)
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('구글 로그인 시도 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPDFs() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      await context.read<PDFProvider>().loadSavedPDFs(context);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'PDF 파일 로드 중 오류 발생: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Learner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('PDF 파일 로드 중 오류 발생', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPDFs,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF 파일을 불러오는 중...'),
          ],
        ),
      );
    }

    // 로그인 상태에 따라 화면 분기
    if (_userId.isEmpty) {
      return _buildLoginScreen();
    }

    return _buildContent();
  }
  
  Widget _buildLoginScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PDF Learner',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _googleLogin,
            icon: const Icon(Icons.login),
            label: const Text('구글로 로그인'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final pdfProvider = Provider.of<PDFProvider>(context);

    return Column(
      children: [
        // 상단 헤더 영역 개선
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 24,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $_userId',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '총 ${pdfProvider.pdfFiles.length}개의 PDF',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 업로드 버튼 개선
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => pdfProvider.pickPDF(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('PDF 업로드하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
        
        // PDF 목록 표시 영역
        Expanded(
          child: pdfProvider.pdfFiles.isEmpty
              ? _buildEmptyState(pdfProvider)
              : _buildPdfList(pdfProvider),
        ),
      ],
    );
  }

  Widget _buildEmptyState(PDFProvider pdfProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF 파일이 없습니다',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: const Text(
              'PDF 파일을 업로드하여 AI가 분석하고 학습을 도와드립니다',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => pdfProvider.pickPDF(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('첫 PDF 업로드하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfList(PDFProvider pdfProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RefreshIndicator(
        onRefresh: _loadPDFs,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,  // 한 줄에 2개씩
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: pdfProvider.pdfFiles.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final pdfFile = pdfProvider.pdfFiles[index];
            return _buildPdfCard(pdfFile, pdfProvider);
          },
        ),
      ),
    );
  }

  Widget _buildPdfCard(PdfFileInfo pdfFile, PDFProvider pdfProvider) {
    return Hero(
      tag: 'pdf-${pdfFile.id}',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // PDF 선택 시 PDF 뷰어 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF 썸네일 영역
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
              
              // PDF 정보 영역
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdfFile.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '파일 크기: ${(pdfFile.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 작업 버튼 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
                          ),
                        );
                      },
                      tooltip: '보기',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => pdfProvider.deletePDF(pdfFile, context),
                      tooltip: '삭제',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 