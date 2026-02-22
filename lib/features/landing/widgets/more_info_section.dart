import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// More info section — Problems & Solutions grid.
/// Updated design inspired by landing_page2.
class MoreInfoSection extends StatelessWidget {
  const MoreInfoSection({super.key});

  static const _hotPink = Color(0xFFE91E8B);

  /// Reads the problems array directly from the translation JSON file
  /// because easy_localization does not support array-index key resolution.
  Future<List<_ProblemItem>> _loadProblems(String langCode) async {
    final path = 'assets/translations/$langCode.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final landing = data['landing'] as Map<String, dynamic>?;
      if (landing == null) return [];
      final problemsList = landing['problems'] as List<dynamic>?;
      if (problemsList == null) return [];
      return problemsList.map((item) {
        final map = item as Map<String, dynamic>;
        return _ProblemItem(
          title: (map['title'] ?? '') as String,
          problem: (map['problem'] ?? '') as String,
          solution: (map['solution'] ?? '') as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [MoreInfoSection] Error loading problems: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final langCode = context.locale.languageCode;

    return FutureBuilder<List<_ProblemItem>>(
      future: _loadProblems(langCode),
      builder: (context, snapshot) {
        final problems = snapshot.data ?? [];

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.only(
            top: isMobile ? 40 : 56,
            bottom: isMobile ? 40 : 56,
            left: isMobile ? 20 : 48,
            right: isMobile ? 20 : 48,
          ),
          child: Column(
            children: [
              // Title
              Text(
                'landing.more_info_title'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'Bebas Neue',
                ),
              ),
              const SizedBox(height: 40),
              // Cards — 2 columns on desktop, 1 on mobile
              if (problems.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      // Desktop: 2-column grid
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: problems.map((p) {
                          final cardWidth = (constraints.maxWidth - 24) / 2;
                          return SizedBox(
                            width: cardWidth,
                            child: _buildProblemCard(p),
                          );
                        }).toList(),
                      );
                    }
                    // Mobile: single column
                    return Column(
                      children: problems.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildProblemCard(p),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProblemCard(_ProblemItem item) {
    final solutionLabel = 'landing.migozz_solution_label'.tr();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Question mark icon
          SvgPicture.asset(
            'assets/images/landing/Ask_icons.svg',
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(_hotPink, BlendMode.srcIn),
          ),
          const SizedBox(height: 10),
          // Title (pink, underlined)
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _hotPink,
              fontFamily: 'Bebas Neue',
              height: 1.3,
              decoration: TextDecoration.underline,
              decorationColor: _hotPink,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle
          Text(
            item.problem,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Bebas Neue',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Solution
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontFamily: 'Bebas Neue',
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$solutionLabel ',
                  style: const TextStyle(
                    color: _hotPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: item.solution),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemItem {
  final String title;
  final String problem;
  final String solution;

  _ProblemItem({
    required this.title,
    required this.problem,
    required this.solution,
  });
}
