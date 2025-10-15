// Splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  ImageProvider get _logo => const AssetImage('assets/images/Migozz.webp');
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -15.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -15.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(_bounceController);

    _bounceController.repeat(reverse: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precarga las imágenes para que aparezcan sin "salto"
    precacheImage(const AssetImage('assets/images/loading.gif'), context);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;

    return Scaffold(
      body: Stack(
        children: [
          // Tinte inferior (ocupa ancho; ajusta a tu widget real)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TintesGradients(
                child: SizedBox(height: bottomGradientHeight),
              ),
            ),
          ),

          // Loader centrado y un poco arriba
          Center(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Image.asset(
                'assets/images/loading.gif',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Logo cerca del bottom con animación de rebote
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * 0.09,
            child: Center(
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  );
                },
                child: Image(
                  image: _logo,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
