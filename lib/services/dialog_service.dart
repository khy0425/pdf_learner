import 'package:flutter/material.dart';
import 'dart:math';
import '../viewmodels/document_list_viewmodel.dart';
import '../viewmodels/document_actions_viewmodel.dart';
import '../models/sort_option.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

/// 다이얼로그와 모달을 처리하는 서비스 클래스
class DialogService {
  /// PDF 추가 메뉴 옵션을 보여주는 모달 바텀 시트
  Future<void> showAddPdfOptions(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PDF 추가하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('파일에서 추가'),
              onTap: () {
                Navigator.pop(context);
                _pickPdfFile(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL에서 추가'),
              onTap: () {
                Navigator.pop(context);
                showAddPdfFromUrlDialog(context);
              },
            ),
            if (Theme.of(context).platform == TargetPlatform.macOS ||
                Theme.of(context).platform == TargetPlatform.windows ||
                Theme.of(context).platform == TargetPlatform.linux ||
                kIsWeb)
              ListTile(
                leading: const Icon(Icons.science),
                title: const Text('샘플 PDF 추가'),
                subtitle: const Text('테스트용 PDF 파일을 추가합니다'),
                onTap: () {
                  Navigator.pop(context);
                  addSamplePdf(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 기기에서 PDF 파일 선택
  Future<void> _pickPdfFile(BuildContext context) async {
    final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    
    try {
      final result = await viewModel.pickAndAddDocument();
      
      if (result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF 파일 추가 완료'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 선택 오류: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// URL에서 PDF 추가 다이얼로그
  Future<void> showAddPdfFromUrlDialog(BuildContext context) async {
    final TextEditingController urlController = TextEditingController();
    bool isValidUrl = false;
    bool isLoading = false;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('URL에서 PDF 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/document.pdf',
                    labelText: 'PDF URL',
                    errorText: urlController.text.isNotEmpty && !isValidUrl
                        ? 'PDF URL을 입력해주세요 (.pdf로 끝나야 함)'
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (value) {
                    final lowered = value.toLowerCase();
                    setState(() {
                      isValidUrl = lowered.startsWith('http') && lowered.endsWith('.pdf');
                    });
                  },
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: isLoading || !isValidUrl
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        
                        try {
                          final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
                          final urlText = urlController.text.trim();
                          final title = urlText.split('/').last.replaceAll('.pdf', '');
                          
                          final result = await viewModel.addPdfFromUrl(urlText, title);
                          
                          if (result && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PDF URL 추가 완료'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else if (dialogContext.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('URL에서 PDF 추가 실패: ${viewModel.errorMessage}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('PDF 추가 실패: $e'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: const Text('추가'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 샘플 PDF 추가
  Future<void> addSamplePdf(BuildContext context) async {
    final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    
    // 샘플 PDF URL
    const String sampleUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    final String title = '샘플 PDF ${DateTime.now().millisecondsSinceEpoch}';
    
    // 로딩 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('샘플 PDF 다운로드 중...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      final result = await viewModel.addPdfFromUrl(sampleUrl, title);
      
      if (result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('샘플 PDF 추가 완료'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('샘플 PDF 추가 실패: ${viewModel.errorMessage}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('샘플 PDF 추가 중 오류: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 정렬 옵션을 선택하는 바텀 시트
  Future<void> showSortOptions(BuildContext context) async {
    final viewModel = Provider.of<DocumentActionsViewModel>(context, listen: false);
    
    return showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('최근 날짜순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.dateNewest);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('오래된 날짜순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.dateOldest);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('제목 오름차순 (A-Z)'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.nameAZ);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('제목 내림차순 (Z-A)'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.nameZA);
            },
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('페이지수 적은순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.pageCountAsc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('페이지수 많은순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.pageCountDesc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('추가일 최신순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.addedNewest);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('추가일 오래된순'),
            onTap: () {
              Navigator.pop(context);
              viewModel.setSortOption(SortOption.addedOldest);
            },
          ),
        ],
      ),
    );
  }

  /// 문서 삭제 확인 다이얼로그
  Future<void> showDeleteConfirmDialog(BuildContext context, String documentId, String documentTitle) async {
    final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 삭제'),
        content: Text('정말 "$documentTitle" 문서를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await viewModel.deleteDocument(documentId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$documentTitle 문서가 삭제되었습니다'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 문서 이름 변경 다이얼로그
  Future<void> showRenameDialog(BuildContext context, String documentId, String currentTitle) async {
    final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    final titleController = TextEditingController(text: currentTitle);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 이름 변경'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: '새 이름 입력',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                // 문서 이름 변경
                final success = await viewModel.renameDocument(documentId, titleController.text);
                
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('문서 이름이 변경되었습니다'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                
                Navigator.pop(context);
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  /// 검색 바 표시
  Future<void> showSearchBar(BuildContext context, TextEditingController searchController) async {
    final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: '문서 검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      viewModel.setSearchQuery(query);
                    },
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      Navigator.pop(context);
                    },
                    autofocus: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    viewModel.clearSearch();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 