import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/progress_indicator.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/category_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests_step.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/modules/layout_step.dart';
// import 'package:migozz_app/features/auth/presentation/register/user_details/modules/pic_audio_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem_step.dart';

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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: widget.pageIndicator,
    ); // Inicializamos el PageController
    _currentPage = widget.pageIndicator;
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
      // PicAudioStep(controller: pageController),
      // LayoutStep(controller: pageController),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: PageView.builder(
              controller:
                  pageController, // Aseguramos que el controlador se pase correctamente
              itemCount: steps.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (_, index) => steps[index],
            ),
          ),
          // Indicadores de progreso
          Container(
            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (index) => CustomProgressIndicator(
                  index,
                  currentIndex: _currentPage,
                  activeWidth: 16,
                  activeHeight: 16,
                  inactiveWidth: 16,
                  inactiveHeight: 16,
                  borderRadius: BorderRadius.circular(20),
                  inactiveColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
