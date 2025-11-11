class ShareDTO {
  final String handle;
  final String publicUrl;
  final String? qrUrl;

  ShareDTO({required this.handle, required this.publicUrl, this.qrUrl});

  Map<String, dynamic> toMap() => {
    'handle': handle,
    'publicUrl': publicUrl,
    'qrUrl': qrUrl,
  };

  factory ShareDTO.fromMap(Map<String, dynamic> map) => ShareDTO(
    handle: map['handle'],
    publicUrl: map['publicUrl'],
    qrUrl: map['qrUrl'],
  );
}
