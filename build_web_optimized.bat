@echo off
echo PDF Learner 웹 앱 최적화 빌드 시작...

REM 기존 빌드 제거
echo 기존 빌드 정리 중...
if exist build\web rmdir /s /q build\web

REM 최적화된 웹 빌드 실행
echo 최적화된 웹 빌드 실행 중...
flutter clean
flutter pub get
flutter build web --release --web-renderer html --pwa-strategy offline-first --tree-shake-icons --dart-define=Dart2jsOptimization=O4

REM 빌드 결과 확인
if %errorlevel% neq 0 (
  echo 빌드 실패! 오류를 확인하세요.
  exit /b %errorlevel%
)

echo 빌드 최적화 작업 실행 중...

REM 메인 JS 파일 압축 확인
echo main.dart.js 크기 확인 중...
for %%F in (build\web\main.dart.js) do echo 메인 JS 크기: %%~zF bytes

REM 빌드 완료! 웹 호스팅에 배포
echo.
echo 빌드 완료! 결과물: build\web
echo 웹 서버에 배포하려면 아래 명령어를 실행하세요:
echo firebase deploy --only hosting
echo.

pause 