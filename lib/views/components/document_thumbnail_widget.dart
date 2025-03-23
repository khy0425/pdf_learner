import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/pdf_document.dart';
import '../../utils/color_generator.dart';

/// PDF 문서 썸네일 위젯
class DocumentThumbnailWidget extends StatelessWidget {
  final PDFDocument document;
  
  const DocumentThumbnailWidget({
    Key? key,
    required this.document,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return _buildDocumentThumbnail();
  }
  
  Widget _buildDocumentThumbnail() {
    // 썸네일 경로가 있는 경우 이미지 표시 시도
    if (document.thumbnailPath != null && document.thumbnailPath!.isNotEmpty) {
      // 웹 환경에서는 네트워크 이미지 사용
      if (kIsWeb) {
        // URL이 HTTP/HTTPS로 시작하는지 확인
        if (document.thumbnailPath!.startsWith('http')) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 썸네일 이미지
              Image.network(
                document.thumbnailPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('웹 썸네일 로드 오류: $error');
                  return _buildDefaultWebThumbnail();
                },
              ),
              
              // PDF 정보 배지
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '${document.pageCount}p',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // URL이 아닌 경우 기본 썸네일 표시
          return _buildDefaultWebThumbnail();
        }
      } else {
        // 모바일 환경에서는 기존 로직 사용
        // PDF.js 뷰어 URL 확인 (첫 페이지 표시)
        final isPdfJsUrl = document.thumbnailPath!.contains('mozilla.github.io/pdf.js');
        
        // 아이콘 URL 확인
        final isIconUrl = document.thumbnailPath!.contains('flaticon.com') || 
                        document.thumbnailPath!.contains('icons');
        
        if (isPdfJsUrl) {
          // PDF.js 썸네일 - 정적 이미지로 대체
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              
              // PDF 표시 텍스트 오버레이
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Center(
                    child: Text(
                      'PDF 문서',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if (isIconUrl) {
          // 아이콘 이미지 표시
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              color: Colors.white,
              child: Center(
                child: Image.network(
                  document.thumbnailPath!,
                  fit: BoxFit.contain,
                  height: 80,
                  width: 80,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('아이콘 로드 오류: $error');
                    return _buildThumbnailPlaceholder();
                  },
                ),
              ),
            ),
          );
        } else {
          // 일반 썸네일 URL - 이미지로 표시 시도
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              document.thumbnailPath!,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('썸네일 로드 오류: $error');
                return _buildThumbnailPlaceholder();
              },
            ),
          );
        }
      }
    } else {
      // 썸네일 없음 - 기본 플레이스홀더 사용
      if (kIsWeb) {
        return _buildDefaultWebThumbnail();
      } else {
        return _buildThumbnailPlaceholder();
      }
    }
  }
  
  /// 웹용 기본 썸네일
  Widget _buildDefaultWebThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorGenerator.fromString(document.title),
            ColorGenerator.fromString(document.title).withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 패턴
          Opacity(
            opacity: 0.1,
            child: GridPaper(
              color: Colors.white,
              divisions: 4,
              interval: 100,
              subdivisions: 2,
            ),
          ),
          
          // 메인 컨텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    document.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // PDF 정보 배지
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '${document.pageCount}p',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 썸네일 플레이스홀더 생성
  Widget _buildThumbnailPlaceholder() {
    // 문서 제목에서 색상 생성
    final color = ColorGenerator.fromString(document.title);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 패턴
          Opacity(
            opacity: 0.1,
            child: GridPaper(
              color: Colors.white,
              divisions: 4,
              interval: 100,
              subdivisions: 2,
            ),
          ),
          
          // 메인 컨텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    document.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // PDF 정보 배지
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '${document.pageCount}p',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 