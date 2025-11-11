class PrivacyDTO {
  final bool discoverable;

  PrivacyDTO({required this.discoverable});

  Map<String, dynamic> toMap() => {'discoverable': discoverable};

  factory PrivacyDTO.fromMap(Map<String, dynamic> map) =>
      PrivacyDTO(discoverable: map['discoverable'] ?? true);
}
