import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:migozz_app/core/color.dart';

class AIAssistant extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final Offset? initialPosition;

  const AIAssistant({
    super.key,
    this.size = 10,
    this.onTap,
    this.initialPosition,
  });

  @override
  State<AIAssistant> createState() => _AIAssistantState();
}

class _AIAssistantState extends State<AIAssistant>
    with SingleTickerProviderStateMixin {
  late Offset position;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Posición inicial por defecto o la proporcionada
    position = widget.initialPosition ?? const Offset(300, 500);

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
          _animationController.forward();
          // Vibración háptica suave
          HapticFeedback.lightImpact();
        },
        onPanUpdate: (details) {
          setState(() {
            // Calcular nueva posición
            double newX = (position.dx + details.delta.dx).clamp(
              0.0,
              screenSize.width - widget.size,
            );
            double newY = (position.dy + details.delta.dy).clamp(
              safeArea.top,
              screenSize.height - widget.size - safeArea.bottom,
            );
            position = Offset(newX, newY);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          _animationController.reverse();

          // Snap a bordes si está cerca (magnético)
          _snapToEdges(screenSize, safeArea);

          // Vibración háptica de confirmación
          HapticFeedback.selectionClick();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? _scaleAnimation.value : 1.0,
              child: _buildAssistantButton(),
            );
          },
        ),
      ),
    );
  }

  void _snapToEdges(Size screenSize, EdgeInsets safeArea) {
    const snapDistance = 50.0;
    double newX = position.dx;
    double newY = position.dy;

    // Snap horizontal
    if (position.dx < snapDistance) {
      newX = 0;
    } else if (position.dx > screenSize.width - widget.size - snapDistance) {
      newX = screenSize.width - widget.size;
    }

    // Snap vertical (opcional, solo si está muy cerca del borde)
    if (position.dy < safeArea.top + snapDistance) {
      newY = safeArea.top;
    } else if (position.dy >
        screenSize.height - widget.size - safeArea.bottom - snapDistance) {
      newY = screenSize.height - widget.size - safeArea.bottom;
    }

    // Animar el snap si hay cambio
    if (newX != position.dx || newY != position.dy) {
      setState(() {
        position = Offset(newX, newY);
      });
    }
  }

  Widget _buildAssistantButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      elevation: _isDragging ? 12 : 6,
      shadowColor: Colors.black45,
      child: InkWell(
        onTap: _isDragging ? null : widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 2),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDragging
                  ? AppColors.verticalPinkPurple.colors
                  : AppColors.primaryGradient.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: _isDragging ? Colors.black38 : Colors.black26,
                blurRadius: _isDragging ? 15 : 8,
                offset: Offset(0, _isDragging ? 6 : 3),
                spreadRadius: _isDragging ? 2 : 0,
              ),
            ],
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isDragging ? 0.8 : 1.0,
            child: Image.asset(
              'assets/icons/Assistans_Icon.png',
              fit: BoxFit.none,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
          ),
        ),
      ),
    );
  }
}
