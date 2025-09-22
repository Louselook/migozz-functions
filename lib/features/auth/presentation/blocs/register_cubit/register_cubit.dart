import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  // ========== PASO 1: EMAIL ==========
  void setEmail(String email) {
    emit(state.copyWith(email: email, currentStep: RegisterStep.chatQuestions));
  }

  // ========== PASO 2: CHAT RESPUESTAS ==========
  void setLanguage(String language) {
    emit(state.copyWith(language: language));
  }

  void setFullName(String fullName) {
    emit(state.copyWith(fullName: fullName));
  }

  void setUsername(String username) {
    emit(state.copyWith(username: username));
  }

  void setGender(String gender) {
    emit(state.copyWith(gender: gender));
  }

  // ========== PASO 4: UBICACIÓN ==========
  void setLocation(LocationDTO location) {
    final updatedState = state.copyWith(location: location);

    if (updatedState.fullName != null &&
        updatedState.username != null &&
        updatedState.language != null &&
        updatedState.gender != null &&
        updatedState.location != null) {
      emit(updatedState.copyWith(currentStep: RegisterStep.finalReview));
    } else {
      emit(updatedState);
    }
  }

  // ========== PASO 3: REDES SOCIALES ==========
  void setSocialEcosystem(List<String> platforms) {
    emit(state.copyWith(socialEcosystem: platforms));
  }

  // ========== UTILIDADES ==========
  void reset() {
    emit(const RegisterState());
  }

  // Método para obtener el progreso del registro (0.0 - 1.0)
  double get registrationProgress {
    final totalSteps = RegisterStep.values.length;
    final currentStepIndex = RegisterStep.values.indexOf(state.currentStep);
    return (currentStepIndex + 1) / totalSteps;
  }

  // Método para verificar si se puede avanzar al siguiente paso
  bool canProceedToNextStep() {
    switch (state.currentStep) {
      case RegisterStep.email:
        return state.email != null && state.email!.isNotEmpty;
      case RegisterStep.chatQuestions:
        return state.fullName != null &&
            state.username != null &&
            state.gender != null &&
            state.language != null;
      case RegisterStep.socialPlatforms:
        return true; // Las redes sociales pueden ser opcionales
      case RegisterStep.locationConfirm:
        return true; // La ubicación puede usar valores por defecto
      case RegisterStep.finalReview:
        return state.isReadyToRegister;
    }
  }
}


// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:migozz_app/features/auth/services/auth_service.dart';
// import 'register_state.dart';

// class RegisterCubit extends Cubit<RegisterState> {
//   final AuthService _authService;

//   RegisterCubit(this._authService) : super(const RegisterState());


  // // ========== REGISTRO FINAL ==========
  // Future<void> completeRegistration() async {
  //   if (!state.isReadyToRegister) {
  //     emit(
  //       state.copyWith(
  //         status: RegisterStatus.failure,
  //         errorMessage: "Faltan datos requeridos para completar el registro",
  //       ),
  //     );
  //     return;
  //   }

  //   emit(state.copyWith(status: RegisterStatus.loading));

  //   try {
  //     final userDTO = state.buildUserDTO();

  //     await _authService.signUpRegister(
  //       email: state.email!,
  //       otp: "123456", // O el método que uses para la verificación
  //       userData: userDTO,
  //     );

  //     emit(state.copyWith(status: RegisterStatus.success, user: userDTO));
  //   } catch (e) {
  //     emit(
  //       state.copyWith(
  //         status: RegisterStatus.failure,
  //         errorMessage: e.toString(),
  //       ),
  //     );
  //   }
  // }
