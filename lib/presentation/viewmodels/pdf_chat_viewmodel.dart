import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/pdf_document.dart';
import '../services/ai_service.dart';
import '../services/pdf_repository.dart';
import '../utils/rate_limiter.dart';

class PdfChatViewModel extends ChangeNotifier {
  final String documentId;
  final bool showAds;
  final bool showRewardButton;
  final PDFRepository _pdfRepository;
  final AiService _aiService;
  final RateLimiter _rateLimiter;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  PDFDocument? _document;
  int _remainingRequests = 0;

  PdfChatViewModel({
    required this.documentId,
    required this.showAds,
    required this.showRewardButton,
    PDFRepository? pdfRepository,
    AiService? aiService,
    RateLimiter? rateLimiter,
  })  : _pdfRepository = pdfRepository ?? PDFRepository(),
        _aiService = aiService ?? AiService(),
        _rateLimiter = rateLimiter ?? RateLimiter();

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingRequests => _remainingRequests;

  Future<void> initialize() async {
    try {
      _document = await _pdfRepository.getDocument(documentId);
      if (_document == null) {
        throw Exception('문서를 찾을 수 없습니다.');
      }
      _remainingRequests = _rateLimiter.getRemainingRequests('pdf_chat');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_document == null) {
      _errorMessage = '문서를 찾을 수 없습니다.';
      notifyListeners();
      return;
    }

    if (!_rateLimiter.checkRequest('pdf_chat')) {
      _errorMessage = '요청 제한에 도달했습니다. 잠시 후 다시 시도해주세요.';
      notifyListeners();
      return;
    }

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      isUser: true,
    );

    _messages.add(userMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _aiService.chatWithDocument(
        documentId: documentId,
        message: content,
      );

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        content: response,
        isUser: false,
      );

      _messages.add(aiMessage);
      _remainingRequests = _rateLimiter.getRemainingRequests('pdf_chat');
    } catch (e) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: '오류가 발생했습니다. 다시 시도해주세요.',
        isUser: false,
        isError: true,
      );
      _messages.add(errorMessage);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLastMessage() async {
    if (_messages.isEmpty) return;

    final lastMessage = _messages.last;
    if (!lastMessage.isError) return;

    _messages.removeLast();
    await sendMessage(lastMessage.content);
  }

  Future<void> resetChat() async {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> watchAdForMoreRequests() async {
    // TODO: 광고 시청 로직 구현
    _remainingRequests += 5; // 임시로 5회 추가
    notifyListeners();
  }

  @override
  void dispose() {
    _rateLimiter.dispose();
    super.dispose();
  }
} 