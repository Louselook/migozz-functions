import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// More info section — Problems & Solutions grid.
/// Mirrors the React MoreInfo component.
class MoreInfoSection extends StatelessWidget {
  const MoreInfoSection({super.key});

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
    final isMobile = w < 900;
    final langCode = context.locale.languageCode;

    return FutureBuilder<List<_ProblemItem>>(
      future: _loadProblems(langCode),
      builder: (context, snapshot) {
        final problems = snapshot.data ?? [];

        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: screenHeight, // 100vh
          ),
          color: Colors.white,
          child: Column(
            children: [
              // Title bar (black background)
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 30 : 60,
                  horizontal: 20,
                ),
                child: Center(
                  child: Text(
                    'landing.more_info_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: isMobile ? 28 : 64,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD43AB6),
                      height: 1,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // Grid of problems
              if (problems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 40 : 80,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isMobile
                          ? Column(
                              children: problems
                                  .map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 50,
                                      ),
                                      child: _buildInfoCard(p, isMobile),
                                    ),
                                  )
                                  .toList(),
                            )
                          : _buildGrid(problems, isMobile),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<_ProblemItem> problems, bool isMobile) {
    return Wrap(
      spacing: 40,
      runSpacing: 60,
      children: problems
          .map((p) => SizedBox(width: 540, child: _buildInfoCard(p, isMobile)))
          .toList(),
    );
  }

  Widget _buildInfoCard(_ProblemItem item, bool isMobile) {
    final solutionLabel = 'landing.migozz_solution_label'.tr();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/Dudas.svg', width: 60, height: 60),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD43AB6),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.problem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: solutionLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFD43AB6),
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: item.solution,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('assets/icons/Dudas.svg', width: 70, height: 70),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD43AB6),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.problem,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: solutionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFD43AB6),
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: item.solution,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
