import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// More info section — Problems & Solutions grid.
/// Black header bar + white content area matching the landing_page2 design.
class MoreInfoSection extends StatelessWidget {
  const MoreInfoSection({super.key});

  static const _hotPink = Color(0xFFE91E8B);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final solutionLabel = 'landing.migozz_solution_label'.tr();

    // Build the list of problem cards from keyed translations (0–9).
    final problems = <_ProblemCard>[];
    for (int i = 0; i < 10; i++) {
      final title = 'landing.problem_${i}_title'.tr();
      if (title == 'landing.problem_${i}_title') continue;
      problems.add(
        _ProblemCard(
          title: title,
          subtitle: 'landing.problem_${i}_problem'.tr(),
          solutionTitle: solutionLabel,
          solution: 'landing.problem_${i}_solution'.tr(),
        ),
      );
    }

    return Column(
      children: [
        // ── Black header bar with gradient text ────────────
        Container(
          width: double.infinity,
          color: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 20 : 28,
            horizontal: isMobile ? 20 : 48,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              'landing.more_info_title'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 31 : 67,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Bebas Neue',
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        // ── White content area with problem cards ──
        LayoutBuilder(
          builder: (context, outerConstraints) {
            final screenH = MediaQuery.of(context).size.height;
            return Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: screenH),
              color: Colors.white,
              padding: EdgeInsets.only(
                top: isMobile ? 20 : 28,
                bottom: isMobile ? 20 : 28,
                left: isMobile ? 20 : 80,
                right: isMobile ? 20 : 80,
              ),
              child: problems.isNotEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 700) {
                          return Wrap(
                            spacing: 64,
                            runSpacing: 8,
                            children: problems.map((card) {
                              final cardWidth = (constraints.maxWidth - 64) / 2;
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: cardWidth,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12,
                                    right: 30,
                                    left: 30,
                                  ),
                                  child: _buildProblemCard(card, isMobile),
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return Column(
                          children: problems.map((card) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                                right: 24,
                                left: 24,
                              ),
                              child: _buildProblemCard(card, isMobile),
                            );
                          }).toList(),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProblemCard(_ProblemCard card, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon + Title in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/landing/Ask_icons.svg',
              width: 36,
              height: 36,
              colorFilter: const ColorFilter.mode(_hotPink, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: isMobile ? 25 : 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Problem description
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Text(
            card.subtitle,
            style: TextStyle(
              fontSize: isMobile ? 10 : 15,
              color: Colors.black87,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Solution
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isMobile ? 10 : 15,
                color: Colors.black87,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFD43AB6), Color(0xFF9321BD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      card.solutionTitle,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: card.solution),
              ],
            ),
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

class _ProblemCard {
  final String title;
  final String subtitle;
  final String solutionTitle;
  final String solution;

  const _ProblemCard({
    required this.title,
    required this.subtitle,
    required this.solutionTitle,
    required this.solution,
  });
}
