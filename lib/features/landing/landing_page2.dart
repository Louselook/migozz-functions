import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Landing page shown only for web users who are not authenticated.
/// This is a purely visual / static page — no functional logic yet.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _usernameController = TextEditingController();
  bool _showTopBanner = true;

  // ─── COLORS ───────────────────────────────────────────────
  static const _bgColor = Color(0xFF0D0D0D);
  static const _cardDark = Color(0xFF1C1C1E);
  static const _purple = Color(0xFF9C27B0);
  static const _hotPink = Color(0xFFE91E8B);
  static const _accentOrange = Color(0xFFF89A44);
  static const _deepPurple = Color(0xFF7B1FA2);

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildRegisteredUsersSection(context),
            _buildCreateEcosystemSection(context),
            _buildFirstAIEcosystemSection(context),
            _buildFeaturesCardsSection(context),
            _buildProblemSection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO SECTION — "JOIN MIGOZZ!" — White card on purple bg
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_hotPink, Color(0xFF8E24AA), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 64,
        horizontal: isMobile ? 16 : 32,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative repeating Migozz icon pattern collage
          Positioned.fill(
            child: ClipRect(
              child: Opacity(
                opacity: 0.18,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final iconSize = isMobile ? 70.0 : 100.0;
                    final cols = (constraints.maxWidth / iconSize).ceil() + 2;
                    final rows = (constraints.maxHeight / iconSize).ceil() + 2;
                    return Stack(
                      children: List.generate(rows * cols, (index) {
                        final row = index ~/ cols;
                        final col = index % cols;
                        final offsetX = col * iconSize + (row.isOdd ? iconSize * 0.5 : 0) - iconSize * 0.5;
                        final offsetY = row * iconSize - iconSize * 0.5;
                        final rotation = ((row + col) % 4) * 0.25 - 0.25;
                        return Positioned(
                          left: offsetX,
                          top: offsetY,
                          child: Transform.rotate(
                            angle: rotation,
                            child: Image.asset(
                              'assets/images/landing/MigozzVector.png',
                              width: iconSize,
                              height: iconSize,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
          // Banner + White card
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Availability banner (above card)
                if (_showTopBanner)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'landing.banner_available'.tr(namedArgs: {'username': 'username1'}),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() => _showTopBanner = false),
                            child: const Text(
                              'X',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // White card
                Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 520,
              ),
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 32 : 40,
                horizontal: isMobile ? 20 : 40,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_hotPink, _purple],
                    ).createShader(bounds),
                    child: Text(
                      'landing.join_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'landing.join_subtitle_one'.tr()}\n${'landing.join_subtitle_two'.tr()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.black54,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ─── USERNAME INPUT BAR ──────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        // Migozz link icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_hotPink, _purple],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.link, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _usernameController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'migozz.com/${'landing.username_placeholder'.tr()}',
                              hintStyle: const TextStyle(
                                color: Colors.black45,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Availability button (green)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {},
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 20,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'landing.claim_btn'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ─── PRE-SAVE BUTTON (gradient) ───────────────
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_hotPink, _purple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                          ),
                        ),
                        child: Text('landing.pre_save_btn'.tr()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'landing.security_note_part_1'.tr(),
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REGISTERED USERS / "WELCOME TO THE REVOLUTION"
  // ═══════════════════════════════════════════════════════════
  Widget _buildRegisteredUsersSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 64,
        horizontal: isMobile ? 16 : 24,
      ),
      color: _bgColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Purple blob left
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _purple.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Purple blob right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _purple.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content — SizedBox forces full width so centering works in Stack
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // First line white
              Text(
                'landing.revolution_title_1'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Inter',
                  height: 1.3,
                ),
              ),
              // Second line: gradient + emoji
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_hotPink, _purple],
                    ).createShader(bounds),
                    child: Text(
                      'landing.revolution_title_2'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🚀',
                    style: TextStyle(fontSize: isMobile ? 22 : 30),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'landing.revolution_description'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              // Pink italic CTA
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_hotPink, _accentOrange],
                ).createShader(bounds),
                child: Text(
                  'landing.revolution_cta'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Counter card
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: isMobile ? 36 : 56,
                ),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      '7,450',
                      style: TextStyle(
                        fontSize: isMobile ? 40 : 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'landing.registered_users'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CREATE YOUR AI SOCIAL ECOSYSTEM — Full background image
  // ═══════════════════════════════════════════════════════════
  Widget _buildCreateEcosystemSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Image.asset(
      'assets/images/landing/Create_Your_AI_Social_Ecosystem.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // YOUR FIRST AI ECOSYSTEM — Dark bg, phone screenshots behind
  // ═══════════════════════════════════════════════════════════
  Widget _buildFirstAIEcosystemSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      width: double.infinity,
      color: _bgColor,
      child: Stack(
        children: [
          // Phone screenshots background — fills entire section edge-to-edge
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/images/landing/Migozz_background_phone.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Content with padding on top of bg
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 40 : 64,
              horizontal: isMobile ? 16 : 48,
            ),
            child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Builder(
                builder: (context) {
                  final parts = 'landing.welcome_title'.tr().split('|');
                  return Column(
                    children: [
                      Text(
                        parts[0],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 26 : 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        parts.length > 1 ? parts[1] : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 44,
                          fontWeight: FontWeight.w900,
                          color: _hotPink,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'landing.welcome_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white70,
                    fontFamily: 'Inter',
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FEATURE CARDS — Light gray bg, white cards, phone + text
  // ═══════════════════════════════════════════════════════════
  Widget _buildFeaturesCardsSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 750;

    final features = [
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_1.png',
        title: 'landing.slide_1_title'.tr(),
        description: 'landing.slide_1_text'.tr(),
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_2.png',
        title: 'landing.slide_2_title'.tr(),
        description: 'landing.slide_2_text'.tr(),
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_3.png',
        title: 'landing.slide_3_title'.tr(),
        description: 'landing.slide_3_text'.tr(),
      ),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child: Stack(
        children: [
          // Decorative Migozz icon — one on each side
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF9C27B0),
                  BlendMode.srcATop,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/images/landing/MigozzVector.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: Image.asset(
                        'assets/images/landing/MigozzVector.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Actual content
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 32 : 48,
              horizontal: isMobile ? 16 : 48,
            ),
            child: Column(
              children: features
                  .map((f) => _buildFeatureCard(f, isMobile))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isMobile) {
    final imageWidget = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? 220 : 380,
        maxHeight: isMobile ? 300 : 520,
      ),
      child: Image.asset(
        feature.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(
              Icons.phone_android,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );

    final textWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_hotPink, _purple],
            ).createShader(bounds),
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: isMobile ? 25 : 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Inter',
                height: 1.3,
              ),
            ),
          ),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              color: Colors.black87,
              fontFamily: 'Inter',
              height: 1.6,
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            imageWidget,
            const SizedBox(height: 20),
            textWidget,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          imageWidget,
          const SizedBox(width: 40),
          Flexible(child: textWidget),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // THE PROBLEM WE'RE SOLVING — White cards on dark bg
  // ═══════════════════════════════════════════════════════════
  Widget _buildProblemSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final solutionLabel = 'landing.migozz_solution_label'.tr();
    final problemsList = [
      _ProblemCard(
        title: 'landing.problem_0_title'.tr(),
        subtitle: 'landing.problem_0_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_0_solution'.tr(),
      ),
      _ProblemCard(
        title: 'landing.problem_1_title'.tr(),
        subtitle: 'landing.problem_1_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_1_solution'.tr(),
      ),
      _ProblemCard(
        title: 'landing.problem_2_title'.tr(),
        subtitle: 'landing.problem_2_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_2_solution'.tr(),
      ),
      _ProblemCard(
        title: 'landing.problem_3_title'.tr(),
        subtitle: 'landing.problem_3_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_3_solution'.tr(),
      ),
      _ProblemCard(
        title: 'landing.problem_4_title'.tr(),
        subtitle: 'landing.problem_4_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_4_solution'.tr(),
      ),
      _ProblemCard(
        title: 'landing.problem_5_title'.tr(),
        subtitle: 'landing.problem_5_problem'.tr(),
        solutionTitle: solutionLabel,
        solution: 'landing.problem_5_solution'.tr(),
      ),
    ];

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
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 40),
          // Cards — 2 columns on desktop, 1 on mobile
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                // Desktop: 2-column grid
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: problemsList.map((card) {
                    final cardWidth =
                        (constraints.maxWidth - 24) / 2;
                    return SizedBox(
                      width: cardWidth,
                      child: _buildProblemCard(card),
                    );
                  }).toList(),
                );
              }
              // Mobile: single column
              return Column(
                children: problemsList.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildProblemCard(card),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCard(_ProblemCard card) {
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
            colorFilter: const ColorFilter.mode(
              _hotPink,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 10),
          // Title (pink, underlined)
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _hotPink,
              fontFamily: 'Poppings',
              height: 1.3,
              decoration: TextDecoration.underline,
              decorationColor: _hotPink,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle
          Text(
            card.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Poppins',
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
                fontFamily: 'Poppins',
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '${card.solutionTitle} ',
                  style: const TextStyle(
                    color: _hotPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: card.solution),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER — Gradient pink→purple bg
  // ═══════════════════════════════════════════════════════════
  Widget _buildFooter(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 500;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_hotPink, _deepPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 32,
        horizontal: isMobile ? 16 : 24,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildFooterIcons(),
                const SizedBox(height: 16),
                _buildWhatsAppButton(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFooterIcons(),
                const SizedBox(width: 32),
                _buildWhatsAppButton(),
              ],
            ),
    );
  }

  Widget _buildFooterIcons() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _footerSocialIcon('assets/icons/social_networks/Tiktok.svg'),
        _footerSocialIcon('assets/icons/social_networks/Instagram.svg'),
        _footerSocialIcon('assets/icons/social_networks/Facebook.svg'),
        _footerSocialIcon('assets/icons/social_networks/Youtube.svg'),
      ],
    );
  }

  Widget _buildWhatsAppButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/social_networks/WhatsApp.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'landing.whatsapp_btn'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerSocialIcon(String assetPath) {
    return SizedBox(
      width: 36,
      height: 36,
      child: SvgPicture.asset(
        assetPath,
        width: 36,
        height: 36,
      ),
    );
  }
}

// ─── Helper Data Classes ─────────────────────────────────────
class _FeatureItem {
  final String imagePath;
  final String title;
  final String description;

  const _FeatureItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
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
