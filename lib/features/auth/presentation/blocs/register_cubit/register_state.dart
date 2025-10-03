import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/models/user_dto.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

enum RegisterStatus { initial, loading, success, failure }

enum EmailVerification { pending, success }

class RegisterState extends Equatable {
  final RegisterStatus status;
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
    this.status = RegisterStatus.initial,
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
    RegisterStatus? status,
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
    );
  }

  @override
  List<Object?> get props => [
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
