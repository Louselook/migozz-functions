import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    Theme.of(context);
    final size = MediaQuery.of(context).size;
    final selectedColor = const Color(0xFF722583);

    // Responsive sizing: base scale on a 375pt wide reference (iPhone 8)
    final scale = size.width / 375.0;
    // Container height: scale with screen but keep within reasonable bounds
    final containerHeight = (size.height * 0.4).clamp(56.0, size.height * 0.33);
    final textFontSize = (15.0 * scale).clamp(12.0, 18.0);
    final indicatorWidth = (50.0 * scale).clamp(24.0, 80.0);

    return Column(
      children: [
        SizedBox(
          height: containerHeight,
          // height: size.height * 0.4,
          width: size.width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: size.width),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_options.length, (i) {
                  final isSelected = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _options[i],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: textFontSize,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bottom border indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 3,
                            width: isSelected ? indicatorWidth : 0,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor
                                  : const Color.fromARGB(0, 255, 255, 255),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
