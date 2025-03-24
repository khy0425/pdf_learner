class AppConstants {
  static const String appName = 'PDF 학습기';
  static const String appVersion = '1.0.0';
  
  // 파일 관련 상수
  static const String documentsFileName = 'documents.json';
  static const String bookmarksFileName = 'bookmarks.json';
  static const String thumbnailDirectory = 'thumbnails';
  
  // PDF 관련 상수
  static const int maxThumbnailSize = 200;
  static const double defaultZoomLevel = 1.0;
  static const double minZoomLevel = 0.5;
  static const double maxZoomLevel = 3.0;
  
  // UI 관련 상수
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  
  // 애니메이션 관련 상수
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // 에러 메시지
  static const String errorLoadingDocument = '문서를 불러오는데 실패했습니다';
  static const String errorSavingDocument = '문서를 저장하는데 실패했습니다';
  static const String errorDeletingDocument = '문서를 삭제하는데 실패했습니다';
  static const String errorAddingBookmark = '북마크를 추가하는데 실패했습니다';
  static const String errorDeletingBookmark = '북마크를 삭제하는데 실패했습니다';
  
  // 성공 메시지
  static const String successAddingBookmark = '북마크가 추가되었습니다';
  static const String successDeletingBookmark = '북마크가 삭제되었습니다';
  static const String successSavingDocument = '문서가 저장되었습니다';
  static const String successDeletingDocument = '문서가 삭제되었습니다';
} 