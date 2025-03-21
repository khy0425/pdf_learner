@echo off
REM PDF Learner - Windows용 보안 배포 스크립트
REM 이 스크립트는 Flutter 웹 앱 빌드 후 환경 변수를 대체하여 보안을 강화합니다

echo PDF Learner 배포 스크립트 시작...

REM 환경 변수 확인
if not exist .env (
  echo 환경 변수 파일 .env를 찾을 수 없습니다.
  exit /b 1
)

REM 환경 변수 로드
for /f "tokens=*" %%a in (.env) do (
  set %%a
)

REM 필수 환경 변수 확인
call :check_var FIREBASE_API_KEY
call :check_var FIREBASE_AUTH_DOMAIN
call :check_var FIREBASE_PROJECT_ID
call :check_var FIREBASE_STORAGE_BUCKET
call :check_var FIREBASE_MESSAGING_SENDER_ID
call :check_var FIREBASE_APP_ID
call :check_var FIREBASE_MEASUREMENT_ID
call :check_var GOOGLE_CLIENT_ID

echo 환경 변수 로드 완료

REM Flutter 웹 빌드
echo Flutter 웹 빌드 시작...
call flutter build web --release --web-renderer canvaskit

REM 생성된 index.html 파일의 경로
set INDEX_FILE=build\web\index.html

REM 생성된 파일이 있는지 확인
if not exist %INDEX_FILE% (
  echo 빌드 결과 파일을 찾을 수 없습니다: %INDEX_FILE%
  exit /b 1
)

REM 환경 변수 대체를 위한 임시 파일
echo 환경 변수 대체 중...
powershell -Command "(gc %INDEX_FILE%) -replace '__FIREBASE_API_KEY__', '%FIREBASE_API_KEY%' | Out-File -encoding utf8 %INDEX_FILE%.tmp"
powershell -Command "(gc %INDEX_FILE%.tmp) -replace '__FIREBASE_AUTH_DOMAIN__', '%FIREBASE_AUTH_DOMAIN%' | Out-File -encoding utf8 %INDEX_FILE%"
powershell -Command "(gc %INDEX_FILE%) -replace '__FIREBASE_PROJECT_ID__', '%FIREBASE_PROJECT_ID%' | Out-File -encoding utf8 %INDEX_FILE%.tmp"
powershell -Command "(gc %INDEX_FILE%.tmp) -replace '__FIREBASE_STORAGE_BUCKET__', '%FIREBASE_STORAGE_BUCKET%' | Out-File -encoding utf8 %INDEX_FILE%"
powershell -Command "(gc %INDEX_FILE%) -replace '__FIREBASE_MESSAGING_SENDER_ID__', '%FIREBASE_MESSAGING_SENDER_ID%' | Out-File -encoding utf8 %INDEX_FILE%.tmp"
powershell -Command "(gc %INDEX_FILE%.tmp) -replace '__FIREBASE_APP_ID__', '%FIREBASE_APP_ID%' | Out-File -encoding utf8 %INDEX_FILE%"
powershell -Command "(gc %INDEX_FILE%) -replace '__FIREBASE_MEASUREMENT_ID__', '%FIREBASE_MEASUREMENT_ID%' | Out-File -encoding utf8 %INDEX_FILE%.tmp"
powershell -Command "(gc %INDEX_FILE%.tmp) -replace '__GOOGLE_CLIENT_ID__', '%GOOGLE_CLIENT_ID%' | Out-File -encoding utf8 %INDEX_FILE%"
del %INDEX_FILE%.tmp

echo 환경 변수 대체 완료

REM Firebase 배포
echo Firebase 배포 시작...
call firebase deploy --only hosting

echo 배포 완료!
exit /b 0

:check_var
if not defined %1 (
  echo 필수 환경 변수 %1이(가) 설정되지 않았습니다.
  exit /b 1
)
exit /b 0 