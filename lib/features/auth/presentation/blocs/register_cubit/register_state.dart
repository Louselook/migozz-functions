import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

enum RegisterStatus { initial, loading, success, failure }

enum EmailVerification { pending, inProgress, success }

class RegisterState extends Equatable {
  // final RegisterStatus status;
  final bool isComplete;
  // final String? errorMessage;

  final String? email;
  final String? language;
  final String? fullName;
  final String? username;
  final String? gender;
  final LocationDTO? location;
  final List<String>? socialEcosystem;

  // add new
  final String? avatarUrl;
  final String? phone;
  final String? voiceNoteUrl;
  final String? category;
  final Map<String, List<String>>? interests;

  final EmailVerification emailVerification;
  final bool confirmEmail;

  // final String? birthday;

  const RegisterState({
    // this.status = RegisterStatus.initial,
    this.isComplete = false,

    // this.errorMessage,
    this.email,
    this.language,
    this.fullName,
    this.username,
    this.gender,
    this.location,
    this.socialEcosystem,

    // add new
    this.avatarUrl,
    this.phone,
    this.voiceNoteUrl,
    this.category,
    this.interests,

    this.emailVerification = EmailVerification.pending,
    this.confirmEmail = false,
    // this.birthday,
  });

  RegisterState copyWith({
    bool? isComplete,

    // String? errorMessage,
    String? email,
    String? language,
    String? fullName,
    String? username,
    String? gender,
    LocationDTO? location,
    List<String>? socialEcosystem,

    // add new
    String? avatarUrl,
    String? phone,
    String? voiceNoteUrl,
    String? category,
    Map<String, List<String>>? interests,

    EmailVerification? emailVerification,
    bool? confirmEmail,
    // String? birthday,
  }) {
    return RegisterState(
      // status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      // errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
      language: language ?? this.language,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,

      // add neew
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      category: category ?? this.category,
      interests: interests ?? this.interests,

      emailVerification: emailVerification ?? this.emailVerification,
      confirmEmail: confirmEmail ?? this.confirmEmail,
      // birthday: birthday ?? this.birthday,
    );
  }

  // Método para construir el UserDTO final
  UserDTO buildUserDTO() {
    return UserDTO(
      email: email!,
      lang: language ?? "en-US",
      displayName: fullName!,
      username: username!,
      gender: gender!,
      location:
          location ??
          LocationDTO(
            country: "Colombia",
            state: "Antioquia",
            city: "Medellín",
            lat: 6.2442,
            lng: -75.5812,
          ),
      socialEcosystem: socialEcosystem,

      // add new
      avatarUrl: avatarUrl!,
      phone: phone!,
      voiceNoteUrl: voiceNoteUrl!,
      category: category!,
      interests: interests!,

      // birthday: birthday!,
    );
  }

  @override
  List<Object?> get props => [
    // status,
    isComplete,
    // errorMessage,
    email,
    language,
    fullName,
    username,
    gender,
    location,
    socialEcosystem,

    // add new
    avatarUrl,
    phone,
    voiceNoteUrl,
    category,
    interests,

    confirmEmail,
    emailVerification,
    // birthday,
  ];
}
