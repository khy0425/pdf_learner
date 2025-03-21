#!/bin/bash

# PDF Learner - 보안 배포 스크립트
# 이 스크립트는 Flutter 웹 앱 빌드 후 환경 변수를 대체하여 보안을 강화합니다

set -e  # 에러 발생 시 스크립트 중단

# 환경 변수 확인
if [ ! -f .env ]; then
  echo "환경 변수 파일 .env를 찾을 수 없습니다."
  exit 1
fi

# 환경 변수 파일 로드
source .env

# 필수 환경 변수 확인
required_vars=(
  "FIREBASE_API_KEY"
  "FIREBASE_AUTH_DOMAIN"
  "FIREBASE_PROJECT_ID"
  "FIREBASE_STORAGE_BUCKET"
  "FIREBASE_MESSAGING_SENDER_ID"
  "FIREBASE_APP_ID"
  "FIREBASE_MEASUREMENT_ID"
  "GOOGLE_CLIENT_ID"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "필수 환경 변수 ${var}가 설정되지 않았습니다."
    exit 1
  fi
done

echo "환경 변수 로드 완료"

# Flutter 웹 빌드
echo "Flutter 웹 빌드 시작..."
flutter build web --release --web-renderer canvaskit

# 생성된 index.html 파일의 경로
INDEX_FILE="build/web/index.html"

# 환경 변수 대체
echo "환경 변수 대체 중..."
sed -i "s/__FIREBASE_API_KEY__/${FIREBASE_API_KEY}/g" $INDEX_FILE
sed -i "s/__FIREBASE_AUTH_DOMAIN__/${FIREBASE_AUTH_DOMAIN}/g" $INDEX_FILE
sed -i "s/__FIREBASE_PROJECT_ID__/${FIREBASE_PROJECT_ID}/g" $INDEX_FILE
sed -i "s/__FIREBASE_STORAGE_BUCKET__/${FIREBASE_STORAGE_BUCKET}/g" $INDEX_FILE
sed -i "s/__FIREBASE_MESSAGING_SENDER_ID__/${FIREBASE_MESSAGING_SENDER_ID}/g" $INDEX_FILE
sed -i "s/__FIREBASE_APP_ID__/${FIREBASE_APP_ID}/g" $INDEX_FILE
sed -i "s/__FIREBASE_MEASUREMENT_ID__/${FIREBASE_MEASUREMENT_ID}/g" $INDEX_FILE
sed -i "s/__GOOGLE_CLIENT_ID__/${GOOGLE_CLIENT_ID}/g" $INDEX_FILE

echo "환경 변수 대체 완료"

# Firebase 배포
echo "Firebase 배포 시작..."
firebase deploy --only hosting

echo "배포 완료!" 