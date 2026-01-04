/// Servicio de validación de inputs por step
/// IA-01 & IA-02: Input Gate por step y validación de audio

import 'package:flutter/material.dart';
import 'package:migozz_app/core/services/ai/gemini_service.dart';
import 'package:migozz_app/features/chat/services/step_input_types.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

class StepInputValidator {
  final RegisterCubit registerCubit;
  final GeminiService _geminiService = GeminiService.instance;

  StepInputValidator({required this.registerCubit});

  /// Obtener el step actual del registro
  String get currentStep => _geminiService.currentStep;

  /// Obtener el tipo de entrada esperado para el step actual
  InputStepType get expectedInputType => getInputTypeForStep(currentStep);

  /// Verificar si el usuario está en un step de audio
  bool isOnAudioStep() => expectedInputType == InputStepType.audio;

  /// Verificar si el usuario está en un step de imagen
  bool isOnImageStep() => expectedInputType == InputStepType.image;

  /// Verificar si el usuario está en un step de ubicación
  bool isOnLocationStep() => expectedInputType == InputStepType.location;

  /// Verificar si el usuario está en un step de texto
  bool isOnTextStep() => expectedInputType == InputStepType.text;

  /// Verificar si el usuario está en un step de opciones/choice
  bool isOnChoiceStep() => expectedInputType == InputStepType.choice;

  /// Verificar si el usuario está en un step de teléfono
  bool isOnPhoneStep() => expectedInputType == InputStepType.phone;

  /// Validar si un tipo de entrada es válido para el step actual
  bool validateInputType(InputStepType inputType) {
    return isValidInputTypeForStep(currentStep, inputType);
  }

  /// Obtener mensaje de error cuando el input es incorrecto
  String getInputMismatchMessage(InputStepType providedType) {
    final isSpanish = registerCubit.state.language == 'Español';
    final expectedDesc = getInputTypeDescription(expectedInputType, isSpanish);

    if (isSpanish) {
      return '⚠️ Espero $expectedDesc en este paso. Por favor, intenta de nuevo.';
    } else {
      return '⚠️ I expect $expectedDesc at this step. Please try again.';
    }
  }

  /// Validar si se puede enviar un audio en el step actual
  /// Retorna (isValid, errorMessage)
  (bool, String?) validateAudioInput() {
    if (!isOnAudioStep()) {
      final isSpanish = registerCubit.state.language == 'Español';
      if (isSpanish) {
        return (
          false,
          '⚠️ Las notas de voz solo se aceptan en el paso de grabación.',
        );
      } else {
        return (
          false,
          '⚠️ Voice notes are only accepted at the recording step.',
        );
      }
    }
    return (true, null);
  }

  /// Validar si se puede enviar una imagen en el step actual
  /// Retorna (isValid, errorMessage)
  (bool, String?) validateImageInput() {
    if (!isOnImageStep()) {
      final isSpanish = registerCubit.state.language == 'Español';
      if (isSpanish) {
        return (false, '⚠️ Las fotos solo se aceptan en el paso de avatar.');
      } else {
        return (false, '⚠️ Photos are only accepted at the avatar step.');
      }
    }
    return (true, null);
  }

  /// Obtener descripción del step esperado para mostrar al usuario
  String getStepExpectationText() {
    final isSpanish = registerCubit.state.language == 'Español';

    switch (expectedInputType) {
      case InputStepType.text:
        return isSpanish ? '💬 Escribe tu respuesta' : '💬 Type your answer';
      case InputStepType.audio:
        return isSpanish
            ? '🎤 Mantén presionado para grabar'
            : '🎤 Hold to record';
      case InputStepType.image:
        return isSpanish ? '📸 Sube una foto' : '📸 Upload a photo';
      case InputStepType.location:
        return isSpanish
            ? '📍 Confirma tu ubicación'
            : '📍 Confirm your location';
      case InputStepType.choice:
        return isSpanish ? '👆 Selecciona una opción' : '👆 Select an option';
      case InputStepType.phone:
        return isSpanish ? '📱 Ingresa tu teléfono' : '📱 Enter your phone';
      case InputStepType.code:
        return isSpanish ? '🔐 Ingresa el código' : '🔐 Enter the code';
      case InputStepType.any:
        return isSpanish ? '✍️ Tu respuesta' : '✍️ Your answer';
    }
  }

  /// Verificar si el micrófono debe estar visible/habilitado
  bool shouldShowMicrophone() {
    // Solo mostrar micrófono en:
    // 1. Step de audio
    // 2. O en otros steps donde se permite grabación (como confirmación)
    return isOnAudioStep();
  }

  /// Verificar si el botón de adjuntar debe estar visible/habilitado
  bool shouldShowAttachButton() {
    // Solo mostrar botón de adjuntar (para fotos) en step de imagen
    return isOnImageStep();
  }

  /// Obtener mensaje de ayuda para pasos de imagen
  String? getImageStepHelperText() {
    if (!isOnImageStep()) return null;

    final isSpanish = registerCubit.state.language == 'Español';
    if (isSpanish) {
      return '📸 Sube una foto clara de tu rostro para tu perfil';
    } else {
      return '📸 Upload a clear photo of your face for your profile';
    }
  }

  /// Obtener mensaje de ayuda para pasos de audio
  String? getAudioStepHelperText() {
    if (!isOnAudioStep()) return null;

    final isSpanish = registerCubit.state.language == 'Español';
    if (isSpanish) {
      return '🎤 Graba una nota de voz breve presentándote';
    } else {
      return '🎤 Record a brief voice note introducing yourself';
    }
  }

  /// Log para debug
  void debugLogCurrentStep() {
    debugPrint(
      '📍 [StepValidator] Step: $currentStep | Type: $expectedInputType',
    );
  }
}
