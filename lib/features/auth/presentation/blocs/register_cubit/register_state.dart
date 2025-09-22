import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

enum RegisterStatus { initial, loading, success, failure }

enum RegisterStep {
  email, // Paso 1: Capturar email
  chatQuestions, // Paso 2: Preguntas del chat IA
  socialPlatforms, // Paso 3: Conectar redes sociales
  locationConfirm, // Paso 4: Confirmar ubicación
  finalReview, // Paso 5: Revisión final
}

class RegisterState extends Equatable {
  // ---------------------------
  // Parte 1 (principales)
  // ---------------------------
  final RegisterStatus status;
  final RegisterStep currentStep;
  // final UserDTO? user;
  // final String? errorMessage;

  // Datos temporales durante el registro
  final String? email;
  final String? language;
  final String? fullName;
  final String? username;
  final String? gender;
  final LocationDTO? location;
  final List<String>? socialEcosystem;

  // ---------------------------
  // Parte 2 (esperando uso futuro)
  // ---------------------------
  // final String? phone;
  // final String? birthday;
  // final String? category;
  // final List<String> connectedSocialPlatforms;
  // final Map<String, List<String>> interests;
  // final Map<String, String> chatAnswers; // Para guardar respuestas del chat

  const RegisterState({
    // Parte 1
    this.status = RegisterStatus.initial,
    this.currentStep = RegisterStep.email,
    // this.user,
    // this.errorMessage,
    this.email,
    this.language,
    this.fullName,
    this.username,
    this.gender,
    this.location,
    this.socialEcosystem,

    // Parte 2 (comentados)
    // this.phone,
    // this.birthday,
    // this.category,
    // this.connectedSocialPlatforms = const [],
    // this.interests = const {},
    // this.chatAnswers = const {},
  });

  RegisterState copyWith({
    // Parte 1
    RegisterStatus? status,
    RegisterStep? currentStep,
    UserDTO? user,
    String? errorMessage,
    String? email,
    String? language,
    String? fullName,
    String? username,
    String? gender,
    LocationDTO? location,
    List<String>? socialEcosystem,

    // Parte 2 (comentados)
    // String? phone,
    // String? birthday,
    // String? category,
    // List<String>? connectedSocialPlatforms,
    // Map<String, List<String>>? interests,
    // Map<String, String>? chatAnswers,
  }) {
    return RegisterState(
      // Parte 1
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      // user: user ?? this.user,
      // errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
      language: language ?? this.language,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,

      // Parte 2 (comentados)
      // phone: phone ?? this.phone,
      // birthday: birthday ?? this.birthday,
      // category: category ?? this.category,
      // connectedSocialPlatforms: connectedSocialPlatforms ?? this.connectedSocialPlatforms,
      // interests: interests ?? this.interests,
      // chatAnswers: chatAnswers ?? this.chatAnswers,
    );
  }

  // Método para verificar si todos los datos requeridos están completos
  bool get isReadyToRegister {
    return email != null &&
        email!.isNotEmpty &&
        fullName != null &&
        fullName!.isNotEmpty &&
        username != null &&
        username!.isNotEmpty &&
        gender != null &&
        language != null;
  }

  // Método para construir el UserDTO final
  UserDTO buildUserDTO() {
    return UserDTO(
      email: email!,
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
      lang: language ?? "es-CO",
      socialEcosystem: socialEcosystem,

      // Parte 2 (comentados)
      // phone: phone,
      // birthday: birthday!,
      // category: category ?? "User",
      // interests: interests.isNotEmpty ? interests : {"interests": <String>[]},
    );
  }

  @override
  List<Object?> get props => [
    // Parte 1
    status,
    currentStep,
    // user,
    // errorMessage,
    email,
    language,
    fullName,
    username,
    gender,
    location,
    socialEcosystem,

    // Parte 2 (comentados)
    // phone,
    // birthday,
    // category,
    // connectedSocialPlatforms,
    // interests,
    // chatAnswers,
  ];
}
