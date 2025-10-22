import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _glowBlurAnim;
  late final Animation<double> _glowSpreadAnim;
  late final Animation<Color?> _glowColorAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnim = Tween<double>(
      begin: 1.00,
      end: 1.10,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _logoScaleAnim = Tween<double>(
      begin: 1.00,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _glowBlurAnim = Tween<double>(
      begin: 12.0,
      end: 30.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _glowSpreadAnim = Tween<double>(
      begin: 2.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _glowColorAnim = ColorTween(
      begin: const Color.fromARGB(70, 69, 29, 47),
      end: const Color(0xFFFF8CBF),
    ).animate(_animCtrl);

    _animCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseLogoSize = 130.0;
    final glowBoxSize = baseLogoSize * 1.1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              final glowColor = (_glowColorAnim.value ?? Colors.white)
                  .withValues(alpha: 0.48);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Halo animado
                  Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: glowBoxSize,
                      height: glowBoxSize,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor,
                            blurRadius: _glowBlurAnim.value,
                            spreadRadius: _glowSpreadAnim.value,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Transform.scale(
                    scale: _logoScaleAnim.value,
                    child: const Logo(width: 130, height: 130),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
