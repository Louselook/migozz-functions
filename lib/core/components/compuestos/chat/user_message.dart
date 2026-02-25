import 'package:flutter/material.dart';

class UserMessage extends StatelessWidget {
  final String text;
  final String? time;
  const UserMessage({super.key, required this.text, this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75 > 500
              ? 500
              : MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFDCDCDD), // Light grey
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topRight: Radius.circular(4), // Pointed top right
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.black, // Dark text
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                time!,
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
