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

  @override
  void initState() {
    super.initState();
    controller = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppConstants.precacheOnboardingImages(context);
    });
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
      body: PageView.builder(
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
