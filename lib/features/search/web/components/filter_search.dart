import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/search/web/components/filter_tab.dart';

class FilterSearch extends StatefulWidget {
  final double topPadding;
  final Widget? child;

  const FilterSearch({super.key, this.topPadding = 125.0, this.child});

  @override
  State<FilterSearch> createState() => _FilterSearchState();
}

class _FilterSearchState extends State<FilterSearch> {
  final List<String> _options = [
    "search.options.forYou".tr(),
    "search.options.accounts".tr(),
    "search.options.reels".tr(),
    "search.options.audio".tr(),
    "search.options.hashtags".tr(),
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final selectedColor = const Color(0xFF722583);

    // Responsive sizing
    final scale = size.width / 375.0;
    final textFontSize = (14.0 * scale).clamp(12.0, 16.0);
    final indicatorWidth = (40.0 * scale).clamp(24.0, 60.0);
    final horizontalPadding = 10.0 * scale;

    return Container(
      height: 48,
      width: size.width,
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_options.length, (i) {
            return FilterTab(
              label: _options[i],
              isSelected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
              fontSize: textFontSize,
              indicatorWidth: indicatorWidth,
              horizontalPadding: horizontalPadding,
              selectedColor: selectedColor,
            );
          }),
        ),
      ),
    );
  }
}
