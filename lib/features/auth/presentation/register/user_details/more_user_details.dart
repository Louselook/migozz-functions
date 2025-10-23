import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
// import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/category_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/interests_step.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/modules/layout_step.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/modules/pic_audio_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step.dart';

class MoreUserDetails extends StatefulWidget {
  final int pageIndicator; // Añadimos este parámetro

  const MoreUserDetails({
    super.key,
    this.pageIndicator = 0,
  }); // Valor por defecto es la primera página

  @override
  State<MoreUserDetails> createState() => _MoreUserDetailsState();
}

class _MoreUserDetailsState extends State<MoreUserDetails> {
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: widget.pageIndicator,
    ); // Inicializamos el PageController
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      SocialEcosystemStep(controller: pageController),
      CategoryStep(controller: pageController),
      InterestsStep(controller: pageController),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 0.0,
            ), // Antes era 40 por el progreso, pero sin el queda mucho espacio libre
            child: PageView.builder(
              controller:
                  pageController, // Aseguramos que el controlador se pase correctamente
              itemCount: steps.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {});
              },
              itemBuilder: (_, index) => steps[index],
            ),
          ),
        ],
      ),
    );
  }
}
