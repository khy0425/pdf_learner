# PDF Learner (AI PDF 학습 도우미)

PDF 문서를 AI를 활용하여 효과적으로 학습할 수 있도록 도와주는 Flutter 애플리케이션입니다.

## TODO List

### 기능 구현
- [x] PDF 파일 업로드 및 관리
- [x] PDF 텍스트 추출
- [x] 드래그 앤 드롭 PDF 업로드 (윈도우)
- [x] 환경 변수 설정
- [ ] AI 요약 기능
- [ ] 퀴즈 생성 기능
- [ ] 북마크 기능
- [ ] 학습 진도 관리

### 개선사항
- [ ] 다중 파일 드래그 앤 드롭
- [ ] 파일 크기 제한 및 검증
- [ ] 업로드 진행률 표시
- [ ] 파일 미리보기
- [ ] 윈도우 네이티브 메뉴바
- [ ] 다크 모드 지원

### 기술적 개선
- [ ] 에러 처리 개선
- [ ] 성능 최적화
- [ ] 테스트 코드 작성
- [ ] CI/CD 구축

## 주요 기능

### 📚 기본 기능
- PDF 파일 업로드 및 뷰어
- PDF 텍스트 추출
- 문서 관리 및 저장
- 북마크 및 하이라이트 기능

### 🤖 AI 기능
- 문서 내용 자동 요약
- 핵심 개념 추출
- 맞춤형 퀴즈 생성
- Q&A 시스템

### 📝 학습 보조 기능
- 중요 내용 하이라이트
- 학습 진도 관리
- 복습 알림
- 플래시카드 생성

## 시작하기

### 필수 요구사항
- Flutter SDK (3.0.0 이상)
- Dart SDK (2.17.0 이상)
- Android Studio 또는 VS Code
- OpenAI API 키 (AI 기능 사용 시)

### 설치 방법

1. 저장소 클론
```bash
git clone https://github.com/khy0425/pdf_learner.git
cd pdf_learner
```

2. 의존성 설치
```bash
flutter pub get
```

3. 환경 변수 설정
- `.env` 파일을 프로젝트 루트에 생성하고 다음 내용을 추가:

```bash
AI_API_KEY=your_openai_api_key
AI_API_ENDPOINT=your_api_endpoint
```

4. 앱 실행
```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart
├── screens/
│   ├── home_page.dart
│   ├── pdf_viewer_screen.dart
│   └── ...
├── providers/
│   ├── pdf_provider.dart
│   ├── ai_service_provider.dart
│   └── ...
├── services/
│   ├── pdf_service.dart
│   └── ...
└── widgets/
    ├── pdf_list_item.dart
    └── ...
```

## 사용된 주요 패키지

- `syncfusion_flutter_pdfviewer`: ^22.2.12 - PDF 파일 표시
- `pdf_text`: ^0.5.0 - PDF 텍스트 추출
- `provider`: ^6.0.5 - 상태 관리
- `http`: ^1.1.0 - API 통신
- `path_provider`: ^2.1.1 - 파일 시스템 접근
- `sqflite`: ^2.3.0 - 로컬 데이터베이스
- `file_picker`: ^6.1.1 - 파일 선택 기능

## 주요 기능 사용법

### PDF 업로드
1. 홈 화면에서 'PDF 업로드' 버튼 클릭
2. 기기에서 PDF 파일 선택
3. 업로드된 PDF가 목록에 표시됨

### AI 요약 기능
1. PDF 목록에서 문서 선택
2. 뷰어 화면의 요약 버튼 클릭
3. AI가 생성한 요약 내용 확인

### 퀴즈 생성
1. PDF 문서 열기
2. 퀴즈 생성 버튼 클릭
3. AI가 생성한 퀴즈 풀기

## 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 문제 해결

### 일반적인 문제
- **PDF 로딩 실패**: 파일 권한 설정 확인
- **AI 기능 오류**: API 키 설정 확인
- **앱 크래시**: Flutter 및 패키지 버전 호환성 확인

### 개발 환경 설정
- Android Studio나 VS Code에 Flutter 및 Dart 플러그인 설치
- `flutter doctor` 명령어로 환경 설정 확인

## 연락처

프로젝트 관리자 - [@khy0425](https://github.com/khy0425)

프로젝트 링크: [https://github.com/khy0425/pdf_learner](https://github.com/khy0425/pdf_learner)
