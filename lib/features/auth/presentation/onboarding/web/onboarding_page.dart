import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/shared/constant.dart';
import 'package:migozz_app/features/auth/presentation/onboarding/web/onboarding_container.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  late final PageController controller;
  int currentPage = 0;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // Esperar un frame para que el contexto esté disponible
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      await AppConstants.precacheOnboardingImages(context);
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error preloading images: $e');
      // Mostrar la UI de todos modos después de un tiempo
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = AppConstants.onboardingPages;

    return Scaffold(
      backgroundColor: Colors.black,
      body: !_imagesLoaded
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PageView.builder(
              controller: controller,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return OnboardingContainer(
                  data: pages[index],
                  controller: controller,
                  currentPage: currentPage,
                  totalPages: pages.length,
                  pageIndex: index,
                  lastPage: index == pages.length - 1,
                );
              },
            ),
    );
  }
}
