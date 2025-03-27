import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_learner_v2/domain/models/pdf_document.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewmodel.dart';
import 'package:pdf_learner_v2/services/auth_service.dart';
import 'package:pdf_learner_v2/services/theme_service.dart';

class PDFView extends StatelessWidget {
  const PDFView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 문서'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.read<PDFViewModel>().add(AddDocument()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: BlocBuilder<PDFViewModel, PDFViewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('오류: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PDFViewModel>().add(LoadDocuments()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (state.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('PDF 문서가 없습니다'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PDFViewModel>().add(AddDocument()),
                    child: const Text('PDF 추가'),
                  ),
                ],
              ),
            );
          }

          return _buildDocumentList(state.documents, context.read<PDFViewModel>());
        },
      ),
    );
  }

  Widget _buildDocumentList(List<PDFDocument> documents, PDFViewModel viewModel) {
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: document.thumbnailUrl != null
                ? Image.network(
                    document.thumbnailUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.picture_as_pdf),
            title: Text(document.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('페이지: ${document.totalPages}'),
                if (document.lastAccessedAt != null)
                  Text(
                    '마지막 접근: ${_formatDate(document.lastAccessedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (document.isEncrypted)
                  const Text(
                    '암호화됨',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    document.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: document.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => viewModel.add(ToggleFavorite(document.id)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, document, viewModel),
                ),
              ],
            ),
            onTap: () => viewModel.add(OpenDocument(document.id)),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    PDFDocument document,
    PDFViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문서 삭제'),
        content: Text('"${document.title}" 문서를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.add(DeleteDocument(document.id));
    }
  }
} 