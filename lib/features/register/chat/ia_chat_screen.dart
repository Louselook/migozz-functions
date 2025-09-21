import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/features/register/chat/components/response_ia_chat.dart';
import 'package:migozz_app/features/register/chat/components/social_card.dart';
import 'package:migozz_app/features/register/chat/components/suggestion_chips.dart';
import 'package:migozz_app/features/register/user_details/more_user_details.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final IaChatService _chatService = IaChatService();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    _showNextBotMessage();
  }

  void _showNextBotMessage() {
    final botResponse = _chatService.getNextBotResponse();

    if (botResponse != null) {
      setState(() {
        _messages.add({
          "isBot": true,
          "text": botResponse["text"],
          "time": _getTimeNow(),
        });
        _currentSuggestions = List<String>.from(botResponse["options"] ?? []);
      });
      _scrollToBottom();

      if (botResponse["action"] != null) {
        // 🚨 Si hay acción -> abrimos pantalla extra
        Future.delayed(const Duration(milliseconds: 1200), () {
          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MoreUserDetails(pageIndicator: botResponse["action"]),
            ),
          ).then((result) {
            if (result == "done") {
              Future.delayed(const Duration(milliseconds: 600), () {
                final postSocialResponse = _chatService.getNextBotResponse();
                if (postSocialResponse != null) {
                  if (postSocialResponse["dinamicResponse"] ==
                      "SocialEcosystemStep") {
                    // 👉 Mostrar mensaje introductorio
                    setState(() {
                      _messages.add({
                        "isBot": true,
                        "text": postSocialResponse["text"],
                        "time": _getTimeNow(),
                      });
                    });
                    _scrollToBottom();

                    // 👉 Después de los cards, lanzamos el siguiente mensaje
                    _addSocialCards().then((_) {
                      Future.delayed(const Duration(milliseconds: 800), () {
                        _showNextBotMessage();
                      });
                    });
                  } else {
                    // flujo normal
                    setState(() {
                      _messages.add({
                        "isBot": true,
                        "text": postSocialResponse["text"],
                        "time": _getTimeNow(),
                      });
                    });
                    _scrollToBottom();
                    Future.delayed(const Duration(milliseconds: 600), () {
                      _showNextBotMessage();
                    });
                  }
                }
              });
            }
          });
        });
      }
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"isBot": false, "text": text, "time": _getTimeNow()});
      _currentSuggestions = [];
    });
    _scrollToBottom();
    _controller.clear();

    if (_messages.length == 2) {
      _chatService.setLanguage(text);
    }

    Future.delayed(const Duration(milliseconds: 600), _showNextBotMessage);
  }

  Future<void> _addSocialCards() async {
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
      setState(() {
        _messages.add({
          "isBot": true,
          "social": true,
          "platform": card["platform"],
          "stats": card["stats"],
          "emoji": card["emoji"],
          "time": _getTimeNow(),
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText("IA Chat"),
            const SizedBox(height: 20),

            // Mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg["isBot"]) {
                    if (msg["social"] == true) {
                      return buildSocialCard(
                        msg["platform"],
                        msg["stats"],
                        msg["emoji"],
                        msg["time"],
                      );
                    }
                    return OtherMessage(
                      text: msg["text"],
                      time: msg["time"] ?? "",
                    );
                  } else {
                    return UserMessage(text: msg["text"]);
                  }
                },
              ),
            ),

            // Sugerencias dinámicas
            if (_currentSuggestions.isNotEmpty)
              SuggestionChips(
                suggestions: _currentSuggestions,
                onSelected: (choice) => _sendMessage(choice),
              ),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _controller,
                      hintText: "Type something...",
                      radius: 8,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    height: 48,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.verticalPinkPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => _sendMessage(_controller.text),
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
}
