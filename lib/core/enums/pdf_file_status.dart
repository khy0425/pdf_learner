/// PDF 파일 관련 상태 열거형
enum PdfFileStatus {
  /// 초기 상태
  initial,
  
  /// 로딩 중
  loading,
  
  /// 다운로드 중
  downloading,
  
  /// 성공
  success,
  
  /// 오류 발생
  error,
}

/// PDF 뷰어 상태 열거형
enum PDFViewerStatus {
  /// 초기 상태
  initial,
  
  /// 로딩 중
  loading,
  
  /// 성공
  success,
  
  /// 오류 발생
  error,
} 