import 'package:flutter/material.dart';

Widget buildSocialCard(String name, String stats, String emoji, String time) {
  return Container(
    margin: const EdgeInsets.only(right: 80, bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$emoji $name",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          stats,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    ),
  );
}
