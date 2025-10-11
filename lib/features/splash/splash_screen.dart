// splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ImageProvider get _logo => const AssetImage('assets/icons/Migozz300x.png');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precachea el logo para que aparezca sin “salto”
    precacheImage(_logo, context);
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
              child: const SizedBox(
                width: 72,
                height: 72,
                child: SmileyLoader(color: Color(0xFFE24CCB)),
              ),
            ),
          ),

          // Logo cerca del bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * 0.09,
            child: Center(
              child: Image(
                image: _logo,
                width: size.width * 0.4,
                height: size.width * 0.4,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SmileyLoader extends StatefulWidget {
  final Color color;
  final double strokeWidth;

  const SmileyLoader({
    super.key,
    this.color = const Color(0xFFE24CCB),
    this.strokeWidth = 12.0,
  });

  @override
  State<SmileyLoader> createState() => _SmileyLoaderState();
}

class _SmileyLoaderState extends State<SmileyLoader>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _sweepController;
  late final Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _sweepAnim = Tween<double>(begin: 2.4, end: (2 * math.pi) - 0.12).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut),
    );

    _sweepController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _sweepController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _SmileyPainter(
            rotationProgress: _rotationController.value,
            sweep: _sweepAnim.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _SmileyPainter extends CustomPainter {
  final double rotationProgress; // 0..1
  final double sweep; // radians
  final Color color;
  final double strokeWidth;

  _SmileyPainter({
    required this.rotationProgress,
    required this.sweep,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final startAngle = -math.pi / 2 + rotationProgress * 2 * math.pi;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);

    final dotPaint = Paint()..color = color;
    final dotRadius = strokeWidth * 0.9;

    final start = startAngle;
    final end = startAngle + sweep;

    final dotRadiusFromCenter = radius - (strokeWidth / 2) + (dotRadius * 0.25);

    final startDx = center.dx + dotRadiusFromCenter * math.cos(start);
    final startDy = center.dy + dotRadiusFromCenter * math.sin(start);
    final endDx = center.dx + dotRadiusFromCenter * math.cos(end);
    final endDy = center.dy + dotRadiusFromCenter * math.sin(end);

    canvas.drawCircle(Offset(startDx, startDy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(endDx, endDy), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SmileyPainter old) {
    return old.rotationProgress != rotationProgress ||
        old.sweep != sweep ||
        old.color != color ||
        old.strokeWidth != strokeWidth;
  }
}
