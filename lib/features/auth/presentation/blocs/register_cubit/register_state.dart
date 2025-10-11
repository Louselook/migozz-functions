import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

enum RegisterIsLogin { initial, loading, success }

enum RegisterStatusProgress {
  emty,
  language,
  fullName,
  username,
  gender,
  socialEcosystem,
  location,
  sendOTP,
  emailVerification,
  avatarUrl,
  phone,
  voiceNoteUrl,
  category,
  interests,
  doneChat,
}

enum EmailVerification { pending, success }

class RegisterState extends Equatable {
  final bool loadigAiResponse;
  final RegisterStatusProgress regProgress;
  final RegisterIsLogin status;
  final bool isComplete;

  final String? email;
  final String? language;
  final String? fullName;
  final String? username;
  final String? gender;
  final LocationDTO? location;

  // Ahora socialEcosystem maneja datos dinámicos de cada red
  final List<Map<String, Map<String, dynamic>>>? socialEcosystem;

  // Archivos y multimedia
  final String? avatarUrl;
  final String? phone;
  final String? voiceNoteUrl;
  final List<String>? category;
  final Map<String, List<String>>? interests;

  final EmailVerification emailVerification;
  final String? currentOTP;

  const RegisterState({
    this.loadigAiResponse = false,
    this.regProgress = RegisterStatusProgress.emty,
    this.status = RegisterIsLogin.initial,
    this.isComplete = false,
    this.email,
    this.language,
    this.fullName,
    this.username,
    this.gender,
    this.location,
    this.socialEcosystem, // lista vacía por defecto
    this.avatarUrl,
    this.phone,
    this.voiceNoteUrl,
    this.category,
    this.interests,
    this.emailVerification = EmailVerification.pending,
    this.currentOTP,
  });

  RegisterState copyWith({
    bool? loadigAiResponse,
    RegisterStatusProgress? regProgress,
    RegisterIsLogin? status,
    bool? isComplete,
    String? email,
    String? language,
    String? fullName,
    String? username,
    String? gender,
    LocationDTO? location,
    List<Map<String, Map<String, dynamic>>>? socialEcosystem,
    String? avatarUrl,
    String? phone,
    String? voiceNoteUrl,
    List<String>? category,
    Map<String, List<String>>? interests,
    EmailVerification? emailVerification,
    String? currentOTP,
  }) {
    return RegisterState(
      loadigAiResponse: loadigAiResponse ?? this.loadigAiResponse,
      regProgress: regProgress ?? this.regProgress,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      email: email ?? this.email,
      language: language ?? this.language,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      category: category ?? this.category,
      interests: interests ?? this.interests,
      emailVerification: emailVerification ?? this.emailVerification,
      currentOTP: currentOTP ?? this.currentOTP,
    );
  }

  // Construye UserDTO
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
      phone: phone!,
      category: category!,
      interests: interests!,
      avatarUrl: avatarUrl, // opcional, ya en el state si se subió
      voiceNoteUrl: voiceNoteUrl, // opcional
    );
  }

  @override
  List<Object?> get props => [
    loadigAiResponse,
    regProgress,
    status,
    isComplete,
    email,
    language,
    fullName,
    username,
    gender,
    location,
    socialEcosystem,
    avatarUrl,
    phone,
    voiceNoteUrl,
    category,
    interests,
    currentOTP,
    emailVerification,
  ];
}
