import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
import 'package:migozz_app/features/register/chat/components/response_ia_chat.dart';
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

      // 🚨 Si ya no hay opciones, significa que terminó el flujo
      if ((botResponse["options"] as List).isEmpty &&
          (botResponse["text"].toString().contains("🎉"))) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (_) => const MoreUserDetails()),
          );
        });
      }
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"isBot": false, "text": text});
      _currentSuggestions = []; // limpiar sugerencias al responder
    });
    _scrollToBottom();
    _controller.clear();

    // Si es selección de idioma
    if (_messages.length == 2) {
      _chatService.setLanguage(text);
    }

    Future.delayed(const Duration(milliseconds: 600), _showNextBotMessage);
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

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSelected;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: suggestions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.verticalPinkPurple.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: Colors.white,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
