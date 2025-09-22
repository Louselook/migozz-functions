class InterestSectionModel {
  final String title;
  final List<String> options;
  bool expanded;

  InterestSectionModel({
    required this.title,
    required this.options,
    this.expanded = false,
  });
}
