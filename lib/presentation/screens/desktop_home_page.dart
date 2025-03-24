import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/pdf_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/pdf_list_item.dart';
import '../widgets/drag_drop_area.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_overlay.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDFProvider>().loadSavedPDFs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Consumer<TutorialProvider>(
      builder: (context, tutorialProvider, child) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/images/app_icon.png'),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI PDF 학습 도우미',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PDF LEARNER',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.help_outline,
                      color: colorScheme.primary,
                    ),
                    onPressed: _showHelpDialog,
                    tooltip: '도움말',
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: Icon(
                      context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () {
                      final themeProvider = context.read<ThemeProvider>();
                      themeProvider.setThemeMode(
                        themeProvider.themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      );
                    },
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // 사이드바
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 앱 타이틀 영역
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          'AI PDF 학습 도우미',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // PDF 목록
                          Expanded(
                            child: Consumer<PDFProvider>(
                              builder: (context, pdfProvider, child) {
                                if (pdfProvider.isLoading) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  );
                                }
                                if (pdfProvider.pdfFiles.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          size: 48,
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'PDF 파일이 없습니다',
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: pdfProvider.pdfFiles.length,
                                  itemBuilder: (context, index) {
                                    return PDFListItem(
                                      pdfFile: pdfProvider.pdfFiles[index],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 메인 컨텐츠
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.background.withOpacity(0.7),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: colorScheme.outlineVariant.withOpacity(0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          size: 48,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'PDF 파일 업로드',
                                        style: textTheme.headlineMedium?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'PDF 파일을 드래그하여 놓거나\n파일 선택 버튼을 클릭하세요',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      const DragDropArea(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tutorialProvider.isFirstTime)
              TutorialOverlay(
                onFinish: () {
                  tutorialProvider.completeTutorial();
                },
              ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('AI PDF 학습 도우미 사용법'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpSection(
                  title: '기본 기능',
                  items: [
                    '파일 추가: PDF 파일을 드래그하여 놓거나 파일 선택 버튼을 클릭하세요',
                    '파일 열기: 목록에서 PDF 파일을 클릭하여 열 수 있습니다',
                    '파일 삭제: 목록에서 파일의 삭제 버튼을 클릭하세요',
                  ],
                ),
                _HelpSection(
                  title: 'PDF 뷰어 기능',
                  items: [
                    '페이지 이동: 마우스 휠 또는 스크롤바를 사용하세요',
                    '확대/축소: Ctrl + 마우스 휠 또는 도구 모음의 확대/축소 버튼을 사용하세요',
                    '검색: Ctrl+F 또는 검색 버튼을 클릭하여 텍스트를 검색하세요',
                    '썸네일: 썸네일 버튼을 클릭하여 페이지 미리보기를 표시합니다',
                  ],
                ),
                _HelpSection(
                  title: '북마크 기능',
                  items: [
                    '북마크 추가: Ctrl+B 또는 북마크 버튼을 클릭하여 현재 페이지를 북마크에 추가하세요',
                    '북마크 보기: 북마크 목록에서 저장된 북마크를 확인할 수 있습니다',
                    '북마크 삭제: 북마크 목록에서 항목을 길게 눌러 삭제할 수 있습니다',
                  ],
                ),
                _HelpSection(
                  title: '단축키',
                  items: [
                    'Ctrl + O: 목차 열기',
                    'Ctrl + B: 북마크 목록 열기',
                    'Ctrl + F: 검색',
                    'Ctrl + +: 확대',
                    'Ctrl + -: 축소',
                  ],
                ),
                _HelpSection(
                  title: 'AI 기능',
                  items: [
                    '텍스트 추출: PDF의 텍스트를 추출하여 복사할 수 있습니다',
                    '내용 요약: AI가 PDF 내용을 요약해줍니다',
                    '퀴즈 생성: PDF 내용을 바탕으로 학습 퀴즈를 생성합니다',
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_right,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item)),
            ],
          ),
        )),
        const Divider(),
      ],
    );
  }
} 