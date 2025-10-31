import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AvatarTutorialService {
  TutorialCoachMark? _tutorialCoachMark;
  
  /// Crear y mostrar el tutorial
  void showTutorial({
    required BuildContext context,
    required GlobalKey attachButtonKey,
    required VoidCallback onFinish,
    required String language, // 'Español' o 'English'
  }) {
    final isSpanish = language == 'Español';
    
    final targets = [
      TargetFocus(
        identify: "attach_button",
        keyTarget: attachButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? '📸 ¡Agreguemos tu foto!'
                          : '📸 Let\'s add your photo!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSpanish
                          ? 'Toca el botón del clip (📎) para agregar tu foto de perfil. Puedes tomarla con la cámara o seleccionarla de tu galería.'
                          : 'Tap the clip button (📎) to add your profile photo. You can take it with the camera or select it from your gallery.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          controller.next();
                        },
                        child: Text(
                          isSpanish ? 'Entendido' : 'Got it',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
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
      opacityShadow: 0.8,
      paddingFocus: 10,
      onFinish: () {
        debugPrint('✅ Tutorial de avatar completado');
        onFinish();
      },
      onClickTarget: (target) {
        debugPrint('👆 Usuario tocó el target: ${target.identify}');
        _tutorialCoachMark?.finish();
        onFinish();
      },
      onSkip: () {
        debugPrint('⏭️ Usuario saltó el tutorial');
        return true;
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _tutorialCoachMark?.show(context: context);
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