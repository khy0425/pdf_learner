import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_summary.dart';
import '../models/pdf_document.dart';
import '../viewmodels/ai_summary_viewmodel.dart';
import '../widgets/circular_loader.dart';
import '../widgets/ai_summary/input_form.dart';
import '../widgets/ai_summary/summary_result.dart';

/// AI 요약 화면
class AiSummaryPage extends StatefulWidget {
  final String documentId;
  final PDFDocument? document;
  
  const AiSummaryPage({
    Key? key,
    required this.documentId,
    this.document,
  }) : super(key: key);

  @override
  _AiSummaryPageState createState() => _AiSummaryPageState();
}

class _AiSummaryPageState extends State<AiSummaryPage> {
  @override
  void initState() {
    super.initState();
    // ViewModel 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<AiSummaryViewModel>(context, listen: false);
      viewModel.initialize(widget.documentId, widget.document);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 요약'),
        actions: [
          Consumer<AiSummaryViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.hasSummary) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: viewModel.shareSummary,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AiSummaryViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularLoader());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: viewModel.hasSummary
                ? AiSummaryResult(
                    summary: viewModel.currentSummary!,
                    onNewSummary: viewModel.resetSummary,
                  )
                : AiSummaryInputForm(
                    startPage: viewModel.startPage,
                    endPage: viewModel.endPage,
                    onStartPageChanged: viewModel.setStartPage,
                    onEndPageChanged: viewModel.setEndPage,
                    onGenerateSummary: viewModel.generateSummary,
                    isLoading: viewModel.isLoading,
                  ),
          );
        },
      ),
    );
  }
} 