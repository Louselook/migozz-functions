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
                              'assets/migozz_icon/MigozzVector.png',
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
                          const Flexible(
                            child: Text(
                              'The username @username1 is available!',
                              style: TextStyle(
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
                      'JOIN MIGOZZ!',
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
                    'Create your AI Social Ecosystem!\nRecieve Gifts & Monetize.',
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
                            decoration: const InputDecoration(
                              hintText: 'migozz.com/yourname',
                              hintStyle: TextStyle(
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
                                child: const Text(
                                  'Availability',
                                  style: TextStyle(
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
                        child: const Text('Pre-Save'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Safe. Free. Hassle-free.',
                    style: TextStyle(
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
                'WELCOME TO THE REVOLUTION',
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
                      'OF YOUR DIGITAL PRESENCE!',
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
                'All these people have already secured their username to\nexperience the full potential of our AI ecosystem.',
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
                  "Don't miss out, reserve yours now!",
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
                    const Text(
                      'Registered users',
                      style: TextStyle(
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
              Text(
                'YOUR FIRST AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'ECOSYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 44,
                  fontWeight: FontWeight.w900,
                  color: _hotPink,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white70,
                      fontFamily: 'Inter',
                      height: 1.7,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Migozz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ' is the ultimate '),
                      TextSpan(
                        text: 'AI-powered social ecosystem',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ' that '),
                      TextSpan(
                        text: 'connects',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ', '),
                      TextSpan(
                        text: 'centralizes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ', and '),
                      TextSpan(
                        text: 'monetizes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ' your entire '),
                      TextSpan(
                        text: 'digital presence',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
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
        title: 'VIEW YOUR GLOBAL IMPACT\nIN ONE PLACE',
        description:
            'Visualize the total number of your followers across all your platforms. Migozz shows you the true power of your community.',
        reversed: false,
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_2.png',
        title: 'GROW YOUR\nINFLUENCE EVERYWHERE',
        description:
            'Your followers can follow you on other networks directly from Migozz. You decide how and where to connect.',
        reversed: true,
      ),
      _FeatureItem(
        imagePath: 'assets/images/landing/mobile_3.png',
        title: 'YOUR IMPACT IS\nREWARDED.',
        description:
            'Receive gifts for your influence and participation. The more you grow, the more rewards you unlock.',
        reversed: false,
      ),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 16 : 48,
      ),
      child: Column(
        children: features
            .map((f) => _buildFeatureCard(f, isMobile))
            .toList(),
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
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Inter',
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.description,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: Colors.black87,
              fontFamily: 'Inter',
              height: 1.6,
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            imageWidget,
            const SizedBox(height: 20),
            textWidget,
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: feature.reversed
            ? [
                Flexible(child: textWidget),
                const SizedBox(width: 40),
                imageWidget,
              ]
            : [
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

    final problems = [
      _ProblemCard(
        title: 'How do I connect all my Socials?',
        subtitle:
            'Fans struggle to find creators on new platforms after an account is lost.',
        solutionTitle: 'Migozz Solution:',
        solution:
            'Smart linking ensures your followers always know where to find you, no matter what platform you\'re on.',
      ),
      _ProblemCard(
        title: "User's Don't own their data",
        subtitle:
            "Platforms control your audience, so if you're banned, you lose your followers.",
        solutionTitle: 'Migozz Solution:',
        solution:
            'We give you full ownership of your follower data, so you always have access to your community.',
      ),
      _ProblemCard(
        title: 'How Many Followers do you really have?',
        subtitle:
            "Fans don't always realize you're active on multiple platforms.",
        solutionTitle: 'Migozz Solution:',
        solution:
            'Migozz seamlessly connects your followers across all platforms, making it easy for them to stay engaged.',
      ),
      _ProblemCard(
        title: 'Wasting too much time posting',
        subtitle:
            'Manually uploading content across different social media accounts takes too long.',
        solutionTitle: 'Migozz Solution:',
        solution:
            'One-click cross-posting lets you share content everywhere instantly, saving you time.',
      ),
      _ProblemCard(
        title: 'Unfair Account Suspensions',
        subtitle:
            'Accounts can be suspended without warning, leaving creators with no way to recover.',
        solutionTitle: 'Migozz Solution:',
        solution:
            'We provide backup and recovery options, ensuring you never lose access to your audience or content.',
      ),
      _ProblemCard(
        title: 'Platforms are charging too much',
        subtitle:
            "Big platforms take a large percentage of a creator's income.",
        solutionTitle: 'Migozz Solution:',
        solution:
            'We charge lower fees so you keep more of the money you earn.',
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
            "THE PROBLEM WE'RE SOLVING",
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
                  children: problems.map((card) {
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
                children: problems.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildProblemCard(card),
                  );
                }).toList(),
              );
            },
          ),
          // Gradient bottom bar
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(top: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_hotPink, _purple],
              ),
            ),
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
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _hotPink,
              fontFamily: 'Inter',
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
              fontSize: 12,
              color: Colors.black87,
              fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
          const Text(
            'Join our WhatsApp channel',
            style: TextStyle(
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
  final bool reversed;

  const _FeatureItem({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.reversed,
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
