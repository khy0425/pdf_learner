/// 웹 환경에서 pdf_render 패키지 스텁 구현

/// PdfDocument 스텁 클래스
class PdfDocument {
  /// 파일에서 문서 열기
  static Future<PdfDocument> openFile(String path) async {
    throw UnsupportedError('웹 환경에서는 PdfDocument.openFile을 사용할 수 없습니다.');
  }
  
  /// 바이트에서 문서 열기
  static Future<PdfDocument> openData(List<int> data) async {
    throw UnsupportedError('웹 환경에서는 PdfDocument.openData를 사용할 수 없습니다.');
  }
  
  /// 페이지 가져오기
  Future<PdfPage> getPage(int pageNumber) async {
    throw UnsupportedError('웹 환경에서는 PdfDocument.getPage를 사용할 수 없습니다.');
  }
  
  /// 문서 정리
  void dispose() {
    // 스텁 구현
  }
}

/// PdfPage 스텁 클래스
class PdfPage {
  /// 페이지 렌더링
  Future<PdfPageImage> render({required int width, required int height}) async {
    throw UnsupportedError('웹 환경에서는 PdfPage.render를 사용할 수 없습니다.');
  }
}

/// PdfPageImage 스텁 클래스
class PdfPageImage {
  /// 이미지 정리
  void dispose() {
    // 스텁 구현
  }
  
  /// 이미지 객체 생성
  Future<PdfImageDetached> createImageDetached() async {
    throw UnsupportedError('웹 환경에서는 PdfPageImage.createImageDetached를 사용할 수 없습니다.');
  }
}

/// PdfImageDetached 스텁 클래스
class PdfImageDetached {
  /// PNG 이미지로 변환
  Future<List<int>> toPNG() async {
    throw UnsupportedError('웹 환경에서는 PdfImageDetached.toPNG를 사용할 수 없습니다.');
  }
} 