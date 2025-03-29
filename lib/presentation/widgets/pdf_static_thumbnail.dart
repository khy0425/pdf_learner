import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart';

/// PDF 정적 썸네일 위젯
/// PDF의 첫 페이지만 이미지로 렌더링하여 표시합니다.
class PdfStaticThumbnail extends StatefulWidget {
  /// PDF 바이트 데이터
  final Uint8List pdfData;
  
  /// 썸네일 너비
  final double width;
  
  /// 썸네일 높이
  final double height;
  
  /// 테두리 색상
  final Color borderColor;
  
  /// 테두리 두께
  final double borderWidth;
  
  /// 테두리 반경
  final double borderRadius;
  
  /// 배경색
  final Color backgroundColor;
  
  /// 페이지 번호
  final int pageNumber;

  const PdfStaticThumbnail({
    Key? key,
    required this.pdfData,
    this.width = 120,
    this.height = 160,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
    this.borderRadius = 4.0,
    this.backgroundColor = Colors.white,
    this.pageNumber = 1,
  }) : super(key: key);

  @override
  State<PdfStaticThumbnail> createState() => _PdfStaticThumbnailState();
}

class _PdfStaticThumbnailState extends State<PdfStaticThumbnail> {
  /// 썸네일 이미지 데이터
  Uint8List? _thumbnailData;
  
  /// 로딩 상태
  bool _isLoading = true;
  
  /// 오류 발생 여부
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(PdfStaticThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfData != widget.pdfData || 
        oldWidget.pageNumber != widget.pageNumber) {
      _generateThumbnail();
    }
  }

  /// PDF의 첫 페이지를 이미지로 변환
  Future<void> _generateThumbnail() async {
    if (widget.pdfData.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 백그라운드에서 이미지 생성
      _thumbnailData = await compute(_renderPdfPageToImage, 
        _RenderParams(widget.pdfData, widget.pageNumber));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('썸네일 생성 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth/2),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _thumbnailData == null || _thumbnailData!.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return Image.memory(
      _thumbnailData!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}

/// 렌더링 파라미터
class _RenderParams {
  final Uint8List pdfData;
  final int pageNumber;

  _RenderParams(this.pdfData, this.pageNumber);
}

/// PDF 페이지를 이미지로 렌더링 (분리된 isolate에서 실행)
Future<Uint8List> _renderPdfPageToImage(_RenderParams params) async {
  final Uint8List emptyResult = Uint8List(0);
  
  try {
    // PDF 문서 로드
    final PdfDocument document = PdfDocument(inputBytes: params.pdfData);
    
    try {
      // 페이지 번호 확인 (1부터 시작)
      final int pageNumber = params.pageNumber < 1 || 
                           params.pageNumber > document.pages.count 
                           ? 1 : params.pageNumber;
      
      // 페이지 가져오기
      final PdfPage page = document.pages[pageNumber - 1];
      
      // 이미지 생성
      // PDF 문서 페이지의 실제 크기를 사용
      final targetWidth = page.size.width.toInt();
      final targetHeight = page.size.height.toInt();
      
      try {
        // 페이지 이미지 생성 (render 메서드 사용)
        final PdfPageImage? pageImage = await page.render(
          width: targetWidth,
          height: targetHeight
        );
        
        // 문서 닫기
        document.dispose();
        
        if (pageImage == null) {
          debugPrint('PDF 이미지 생성 실패: null 반환됨');
          return emptyResult;
        }
        
        // 이미지 바이트 배열 가져오기
        final bytes = pageImage.bytes;
        return bytes.isEmpty ? emptyResult : bytes;
      } catch (e) {
        document.dispose(); // 오류 발생 시 문서 닫기
        debugPrint('PDF 이미지 생성 오류: $e');
        return emptyResult;
      }
    } catch (e) {
      document.dispose(); // 오류 발생 시 문서 닫기
      debugPrint('PDF 페이지 접근 오류: $e');
      return emptyResult;
    }
  } catch (e) {
    debugPrint('PDF 문서 로드 오류: $e');
    return emptyResult;
  }
} 