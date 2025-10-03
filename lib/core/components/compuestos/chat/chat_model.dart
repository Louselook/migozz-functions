enum MessageType {
  text,
  socialCard,
  pictureCard,
  audio,
  audioPlayback, // Para reproducir audio con UI específica
  typing,
  socialCardsCompact,
}

class ChatMessage {
  final bool other;
  final MessageType type;
  final String? text;
  final String? audio;
  final List<Map<String, String>>? pictures; // [{"imageUrl":..., "label":...}]
  final List<String>? options; // Sugerencias
  final String time;

  ChatMessage({
    required this.other,
    required this.type,
    this.text,
    this.audio,
    this.pictures,
    this.options,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      "other": other,
      "type": type,
      "text": text,
      "audio": audio,
      "pictures": pictures,
      "options": options,
      "time": time,
    };
  }
}
