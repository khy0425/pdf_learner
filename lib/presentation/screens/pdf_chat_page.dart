import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pdf_chat_viewmodel.dart';
import '../widgets/pdf_chat/chat_input.dart';
import '../widgets/pdf_chat/chat_messages.dart';

class PdfChatPage extends StatefulWidget {
  final String documentId;
  final bool showAds;
  final bool showRewardButton;

  const PdfChatPage({
    super.key,
    required this.documentId,
    this.showAds = true,
    this.showRewardButton = true,
  });

  @override
  State<PdfChatPage> createState() => _PdfChatPageState();
}

class _PdfChatPageState extends State<PdfChatPage> {
  late final PdfChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfChatViewModel(
      documentId: widget.documentId,
      showAds: widget.showAds,
      showRewardButton: widget.showRewardButton,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _viewModel.resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<PdfChatViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ChatMessages(
                  messages: viewModel.messages,
                  onRetry: viewModel.retryLastMessage,
                );
              },
            ),
          ),
          Consumer<PdfChatViewModel>(
            builder: (context, viewModel, child) {
              return ChatInput(
                onSend: viewModel.sendMessage,
                isLoading: viewModel.isLoading,
                remainingRequests: viewModel.remainingRequests,
                showRewardButton: widget.showRewardButton,
                onWatchAd: viewModel.watchAdForMoreRequests,
              );
            },
          ),
        ],
      ),
    );
  }
} 