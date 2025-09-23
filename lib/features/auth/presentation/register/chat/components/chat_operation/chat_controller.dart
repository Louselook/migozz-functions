import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/response_ia_chat.dart';

class ChatController extends ChangeNotifier {
  final IaChatService _chatService = IaChatService();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  List<String> _currentSuggestions = [];

  List<Map<String, dynamic>> get messages => _messages;
  List<String> get currentSuggestions => _currentSuggestions;

  void initializeChat({Function(Map<String, dynamic>)? onActionRequired}) {
    showNextBotMessage(onActionRequired: onActionRequired);
  }

  void showNextBotMessage({Function(Map<String, dynamic>)? onActionRequired}) {
    final botResponse = _chatService.getNextBotResponse();

    if (botResponse != null) {
      _messages.add({
        "isBot": true,
        "text": botResponse["text"],
        "time": _getTimeNow(),
      });
      _currentSuggestions = List<String>.from(botResponse["options"] ?? []);
      notifyListeners();
      scrollToBottom();

      // 🚨 Si hay acción -> trigger navegación
      if (botResponse["action"] != null) {
        onActionRequired?.call(botResponse);
      }
      if (botResponse["dinamicResponse"] == "FollowedMessages") {
        onActionRequired?.call(botResponse);
      }
    }
  }

  void sendMessage(
    String text, {
    Function(Map<String, dynamic>)? onActionRequired,
  }) {
    if (text.trim().isEmpty) return;

    _messages.add({"isBot": false, "text": text, "time": _getTimeNow()});
    _currentSuggestions = []; // limpiar sugeerencias
    notifyListeners();
    scrollToBottom();

    if (_messages.length == 2) {
      _chatService.setLanguage(text);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      showNextBotMessage(onActionRequired: onActionRequired);
    });
  }

  void handlePostActionResponse({
    required Function() onSocialEcosystem,
    required Function() onNormalFlow,
  }) {
    Future.delayed(const Duration(milliseconds: 600), () {
      final postSocialResponse = _chatService.getNextBotResponse();
      if (postSocialResponse != null) {
        if (postSocialResponse["dinamicResponse"] == "SocialEcosystemStep") {
          _messages.add({
            "isBot": true,
            "text": postSocialResponse["text"],
            "time": _getTimeNow(),
          });
          notifyListeners();
          scrollToBottom();
          onSocialEcosystem();
        } else {
          _messages.add({
            "isBot": true,
            "text": postSocialResponse["text"],
            "time": _getTimeNow(),
          });
          notifyListeners();
          scrollToBottom();
          onNormalFlow();
        }
      }
    });
  }

  Future<void> addSocialCards() async {
    final socialCards = [
      {
        "platform": "Instagram",
        "stats": "12.5K followers • 248 posts",
        "emoji": "📸",
      },
      {
        "platform": "TikTok",
        "stats": "8.2K followers • 156 videos",
        "emoji": "📱",
      },
    ];

    for (var card in socialCards) {
      await Future.delayed(const Duration(milliseconds: 800));
      _messages.add({
        "isBot": true,
        "social": true,
        "platform": card["platform"],
        "stats": card["stats"],
        "emoji": card["emoji"],
        "time": _getTimeNow(),
      });
      notifyListeners();
      scrollToBottom();
    }
  }

  Future<void> addPictureCards() async {
    final pictureCards = [
      {"imageUrl": "https://picsum.photos/200", "label": "Camera"},
      {"imageUrl": "https://picsum.photos/201", "label": "Gallery"},
      {"imageUrl": "https://picsum.photos/202", "label": "Custom"},
    ];

    await Future.delayed(const Duration(milliseconds: 800));
    _messages.add({
      "isBot": true,
      "picture": true, // para que ChatMessageBuilder use PictureOptions
      "pictures": pictureCards, // lista completa
      "time": _getTimeNow(),
    });
    notifyListeners();
    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getTimeNow() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
