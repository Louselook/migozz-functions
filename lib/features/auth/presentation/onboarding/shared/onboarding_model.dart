class OnboardingData {
  final String titleKey;
  final String? subTitleKey;
  final String descriptionKey;
  final String imagePath;

  const OnboardingData({
    required this.titleKey,
    this.subTitleKey,
    required this.descriptionKey,
    required this.imagePath,
  });
}
