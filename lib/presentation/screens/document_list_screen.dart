import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/pdf_document.dart';
import '../viewmodels/pdf_viewmodel.dart';
import 'pdf_viewer_screen.dart';

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pdfViewModel = Provider.of<PDFViewModel>(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 앱 바
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text('내 문서'),
            actions: [
              // 정렬 버튼
              PopupMenuButton<String>(
                tooltip: '정렬',
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  pdfViewModel.sortDocuments(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, size: 20),
                        SizedBox(width: 8),
                        Text('이름순'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20),
                        SizedBox(width: 8),
                        Text('날짜순'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, size: 20),
                        SizedBox(width: 8),
                        Text('즐겨찾기'),
                      ],
                    ),
                  ),
                ],
              ),
              // 검색 버튼
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: '검색',
                onPressed: () {
                  // TODO: 검색 기능 구현
                  showSearch(
                    context: context,
                    delegate: DocumentSearchDelegate(pdfViewModel.documents),
                  );
                },
              ),
            ],
          ),
          
          // 문서 목록 영역
          pdfViewModel.isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : pdfViewModel.documents.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(context),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final document = pdfViewModel.documents[index];
                            return _buildDocumentCard(context, document, pdfViewModel);
                          },
                          childCount: pdfViewModel.documents.length,
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await pdfViewModel.pickAndAddPDF();
            if (pdfViewModel.error != null && pdfViewModel.error!.isNotEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(pdfViewModel.error!)),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF 추가 중 오류가 발생했습니다: $e')),
              );
            }
          }
        },
        tooltip: 'PDF 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 문서 카드 위젯
  Widget _buildDocumentCard(
      BuildContext context, PDFDocument document, PDFViewModel viewModel) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          try {
            viewModel.setSelectedDocument(document);
            final pdfBytes = await viewModel.getPDFBytes(document.filePath);
            
            if (context.mounted && pdfBytes != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                    document: document,
                    pdfBytes: pdfBytes,
                  ),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF 파일을 열 수 없습니다.')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF 열기 오류: $e')),
              );
            }
          }
        },
        onLongPress: () {
          _showDocumentOptions(context, document, viewModel);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 영역
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 썸네일 이미지 (또는 기본 이미지)
                  Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: document.thumbnailUrl != null
                          ? Image.network(
                              document.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.picture_as_pdf,
                                size: 48,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.picture_as_pdf,
                              size: 48,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  
                  // 즐겨찾기 아이콘
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        viewModel.toggleFavorite(document);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          document.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: document.isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // 진행률 표시
                  if (document.readingProgress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: document.readingProgress,
                        backgroundColor: Colors.transparent,
                        color: Colors.blue.shade300,
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
            
            // 문서 정보
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // 생성일
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(document.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 페이지 정보
                  Text(
                    '${document.pageCount}페이지',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 문서 옵션 다이얼로그
  void _showDocumentOptions(
      BuildContext context, PDFDocument document, PDFViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(document.title),
                subtitle: Text(
                  '${DateFormat('yyyy.MM.dd').format(document.createdAt)} · ${document.pageCount}페이지',
                ),
                leading: const Icon(Icons.picture_as_pdf),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  document.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: document.isFavorite ? Colors.red : null,
                ),
                title: Text(document.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가'),
                onTap: () {
                  viewModel.toggleFavorite(document);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('이름 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, document, viewModel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('공유'),
                onTap: () {
                  // TODO: 공유 기능 구현
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, document, viewModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 이름 변경 다이얼로그
  void _showRenameDialog(
      BuildContext context, PDFDocument document, PDFViewModel viewModel) {
    final TextEditingController controller = TextEditingController(text: document.title);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 변경'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '문서 이름',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  // 내용 수정된 document 생성
                  final updatedDoc = document.copyWith(
                    title: newTitle,
                    updatedAt: DateTime.now(),
                  );
                  // 문서 업데이트 호출
                  viewModel.updateDocument(updatedDoc);
                  Navigator.pop(context);
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(
      BuildContext context, PDFDocument document, PDFViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('문서 삭제'),
          content: Text('${document.title}을(를) 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                viewModel.deleteDocument(document.id);
                Navigator.pop(context);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '문서가 없습니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF 파일을 추가해보세요',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<PDFViewModel>(context, listen: false).pickAndAddPDF();
            },
            icon: const Icon(Icons.add),
            label: const Text('PDF 추가'),
          ),
        ],
      ),
    );
  }
}

// 문서 검색 위임 클래스
class DocumentSearchDelegate extends SearchDelegate<PDFDocument?> {
  final List<PDFDocument> documents;

  DocumentSearchDelegate(this.documents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = query.isEmpty
        ? documents
        : documents
            .where((doc) =>
                doc.title.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.blue),
          ),
          title: Text(doc.title),
          subtitle: Text(
            '${DateFormat('yyyy.MM.dd').format(doc.createdAt)} · ${doc.pageCount}페이지',
          ),
          trailing: doc.isFavorite
              ? const Icon(Icons.favorite, color: Colors.red, size: 18)
              : null,
          onTap: () async {
            final pdfViewModel = Provider.of<PDFViewModel>(context, listen: false);
            try {
              pdfViewModel.setSelectedDocument(doc);
              final pdfBytes = await pdfViewModel.getPDFBytes(doc.filePath);
              
              if (context.mounted && pdfBytes != null) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      document: doc,
                      pdfBytes: pdfBytes,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF 열기 오류: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
} 