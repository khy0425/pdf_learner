import 'package:flutter/material.dart';
import '../../models/pdf_file_info.dart';
import '../home/pdf_list_item.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';
import '../../screens/pdf_viewer_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// PDF 목록 위젯
/// PDF 파일의 목록을 리스트로 표시합니다.
class PdfListWidget extends StatelessWidget {
  final List<PdfFileInfo> pdfList;
  final Function(PdfFileInfo) onDeletePdf;
  
  const PdfListWidget({
    super.key,
    required this.pdfList,
    required this.onDeletePdf,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final pdfFile = pdfList[index];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: PdfListItem(
              pdfInfo: pdfFile,
              onOpen: () => _openPdf(context, pdfFile),
              onDelete: onDeletePdf,
            ),
          );
        },
        childCount: pdfList.length,
      ),
    );
  }
  
  /// PDF 파일 열기
  void _openPdf(BuildContext context, PdfFileInfo pdfFile) async {
    try {
      if (kDebugMode) {
        print('[PdfListWidget] PDF 열기 - ${pdfFile.fileName}');
      }
      
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF 파일을 불러오는 중...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // PDF 데이터 미리 로드 시도 (오류 방지)
      if (!pdfFile.hasBytes) {
        try {
          if (kDebugMode) {
            print('[PdfListWidget] PDF 바이트 데이터 미리 로드 시도');
          }
          
          // bytes 데이터 로드
          final bytes = await pdfFile.readAsBytes();
          
          // bytes 데이터로 새 PdfFileInfo 객체 생성
          final updatedPdfFile = PdfFileInfo(
            id: pdfFile.id,
            fileName: pdfFile.fileName,
            url: pdfFile.url,
            file: pdfFile.file,
            createdAt: pdfFile.createdAt,
            fileSize: pdfFile.fileSize,
            bytes: bytes,
            userId: pdfFile.userId,
            firestoreId: pdfFile.firestoreId,
          );
          
          if (kDebugMode) {
            print('[PdfListWidget] PDF 바이트 데이터 로드 성공: ${bytes.length} 바이트');
          }
          
          // 현재 선택된 PDF 업데이트
          context.read<PDFProvider>().setCurrentPDF(updatedPdfFile);
          
          // PDF 뷰어 화면으로 이동
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(pdfFile: updatedPdfFile),
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('[PdfListWidget] PDF 바이트 데이터 로드 실패: $e');
          }
          // 오류 발생 시 원래 파일 정보로 계속 진행
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
              ),
            );
          }
        }
      } else {
        // 이미 bytes 데이터가 있는 경우 바로 PDF 뷰어 화면으로 이동
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(pdfFile: pdfFile),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PdfListWidget] PDF 열기 실패: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 파일을 열 수 없습니다: $e')),
        );
      }
    }
  }
} 