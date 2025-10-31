import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class VoiceNoteTutorialService {
  TutorialCoachMark? _tutorialCoachMark;
  
  /// Crear y mostrar el tutorial para el botón del micrófono
  void showTutorial({
    required BuildContext context,
    required GlobalKey micButtonKey,
    required VoidCallback onFinish,
    required String language, // 'Español' o 'English'
  }) {
    final isSpanish = language == 'Español';
    
    final targets = [
      TargetFocus(
        identify: "mic_button",
        keyTarget: micButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        radius: 30,
        enableOverlayTab: true, // Permite interactuar con el botón
        contents: [
          TargetContent(
            align: ContentAlign.top, // 👈 Mostrar arriba del botón
            builder: (context, controller) {
              return Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange.shade900,
                      Colors.red.shade800,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isSpanish
                                ? '¡Graba tu presentación!'
                                : 'Record your intro!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSpanish
                          ? '✋ Mantén presionado el botón del micrófono 🎤 para grabar.\n\n'
                            '⏱️ Duración: entre 5 y 10 segundos.\n\n'
                            '💡 Preséntate: quién eres, qué te gusta, qué buscas en Migozz.'
                          : '✋ Press and hold the microphone button 🎤 to record.\n\n'
                            '⏱️ Duration: between 5 and 10 seconds.\n\n'
                            '💡 Introduce yourself: who you are, what you like, what you\'re looking for on Migozz.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.next();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isSpanish ? 'Entendido ✓' : 'Got it ✓',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      paddingFocus: 10,
      onFinish: () {
        debugPrint('✅ [VoiceNoteTutorial] Tutorial completado');
        onFinish();
      },
      onClickTarget: (target) {
        debugPrint('👆 [VoiceNoteTutorial] Usuario tocó el target: ${target.identify}');
        _tutorialCoachMark?.finish();
        onFinish();
      },
      onSkip: () {
        debugPrint('⏭️ [VoiceNoteTutorial] Usuario saltó el tutorial');
        return true;
      },
    );

    // Pequeño delay para asegurar que el widget esté completamente renderizado
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        _tutorialCoachMark?.show(context: context);
      }
    });
  }

  /// Cerrar el tutorial si está activo
  void closeTutorial() {
    _tutorialCoachMark?.finish();
    _tutorialCoachMark = null;
  }

  /// Verificar si el tutorial está activo
  bool get isShowing => _tutorialCoachMark != null;
}