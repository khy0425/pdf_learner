import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_learner/services/theme_service.dart';
import 'package:pdf_learner/services/service_locator.dart';
import 'package:pdf_learner/services/pdf_service.dart';
import 'package:pdf_learner/models/pdf_document.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _pickAndOpenPDF(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final pdfService = ServiceLocator.pdfService;
        
        final document = await pdfService.openPDF(file);
        if (document != null) {
          if (context.mounted) {
            // TODO: PDF 뷰어 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${document.title} 파일이 열렸습니다.'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('PDF 파일을 열 수 없습니다.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 상단 앱바
          SliverAppBar.large(
            title: Text(
              'PDF 학습기',
              style: GoogleFonts.notoSansKr(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  // TODO: 검색 기능 구현
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  // TODO: 설정 화면으로 이동
                },
              ),
            ],
          ),
          
          // 메인 컨텐츠
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
              ),
              delegate: SliverChildListDelegate([
                _buildFeatureCard(
                  context,
                  'PDF 열기',
                  Icons.file_open,
                  () => _pickAndOpenPDF(context),
                ),
                _buildFeatureCard(
                  context,
                  '최근 문서',
                  Icons.history,
                  () {
                    // TODO: 최근 문서 목록으로 이동
                  },
                ),
                _buildFeatureCard(
                  context,
                  'AI 요약',
                  Icons.auto_awesome,
                  () {
                    // TODO: AI 요약 기능 구현
                  },
                ),
                _buildFeatureCard(
                  context,
                  '학습 통계',
                  Icons.analytics,
                  () {
                    // TODO: 학습 통계 화면으로 이동
                  },
                ),
              ]),
            ),
          ),
          
          // 최근 문서 섹션
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 문서',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5, // 임시 데이터
                      itemBuilder: (context, index) {
                        return _buildRecentDocumentCard(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndOpenPDF(context),
        icon: const Icon(Icons.add),
        label: const Text('새 PDF'),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDocumentCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '문서 제목.pdf',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '마지막 수정: 2024-01-01',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 