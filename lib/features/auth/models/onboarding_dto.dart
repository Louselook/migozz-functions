class OnboardingDTO {
  final OnboardingStatus status;
  final bool completed;

  OnboardingDTO({required this.status, required this.completed});

  factory OnboardingDTO.fromMap(Map<String, dynamic> map) {
    return OnboardingDTO(
      status: OnboardingStatus.fromString(map['status'] ?? 'started'),
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status.value, 'completed': completed};
  }
}

enum OnboardingStatus {
  started('started'),
  aiReview('ai_review'),
  nickname('nickname'),
  category('category'),
  interests('interests'),
  socials('socials'),
  media('media'),
  completed('completed');

  const OnboardingStatus(this.value);
  final String value;

  static OnboardingStatus fromString(String status) {
    return OnboardingStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => OnboardingStatus.started,
    );
  }
}

// class OnboardingDTO {
//   final String status;
//   final bool completed;

//   OnboardingDTO({required this.status, required this.completed});

//   Map<String, dynamic> toMap() => {'status': status, 'completed': completed};

//   factory OnboardingDTO.fromMap(Map<String, dynamic> map) =>
//       OnboardingDTO(status: map['status'], completed: map['completed']);
// }
