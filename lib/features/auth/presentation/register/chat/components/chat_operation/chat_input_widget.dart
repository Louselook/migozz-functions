// lib/features/auth/presentation/register/chat/widgets/chat_input_widget.dart
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: controller,
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
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
