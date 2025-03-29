import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class PdfChatViewModel extends ChangeNotifier {
  final String documentId;
  final bool showAds;
  final bool showRewardButton;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _remainingRequests = 0;

  PdfChatViewModel({
    required this.documentId,
    required this.showAds,
    required this.showRewardButton,
  });

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingRequests => _remainingRequests;

  Future<void> initialize() async {
    try {
      _remainingRequests = 5; // 임시로 5회로 설정
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (!_checkRemainingRequests()) {
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
      // 실제 API 호출 대신 임시 응답
      await Future.delayed(const Duration(seconds: 2));
      final response = "이것은 임시 응답입니다. 실제 AI 서비스와 연결되지 않았습니다.";

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        content: response,
        isUser: false,
      );

      _messages.add(aiMessage);
      _remainingRequests--;
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

  bool _checkRemainingRequests() {
    if (_remainingRequests <= 0) {
      _errorMessage = '요청 제한에 도달했습니다. 잠시 후 다시 시도해주세요.';
      notifyListeners();
      return false;
    }
    return true;
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
    // 광고 시청 로직 구현 (임시)
    _remainingRequests += 5; // 임시로 5회 추가
    notifyListeners();
  }
} 