import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';

class DraggableSocialRail extends StatefulWidget {
  final List<SocialLink> links;
  final double itemSize;
  final double iconSize;
  final Offset? initialPosition;

  const DraggableSocialRail({
    super.key,
    required this.links,
    this.itemSize = 50,
    this.iconSize = 45,
    this.initialPosition,
  });

  @override
  State<DraggableSocialRail> createState() => _DraggableSocialRailState();
}

class _DraggableSocialRailState extends State<DraggableSocialRail>
    with SingleTickerProviderStateMixin {
  late Offset position;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;
  Size? _lastScreenSize;

  @override
  void initState() {
    super.initState();
    // Posición inicial por defecto o la proporcionada
    position = widget.initialPosition ?? const Offset(300, 200);

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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

    // Calcular dimensiones del rail social
    final railHeight =
        (widget.itemSize * widget.links.length) +
        ((widget.links.length - 1) * 8) +
        16; // 8 spacing + 16 padding vertical
    final railWidth = widget.itemSize + 16; // itemSize + 16 padding horizontal

    // Detectar cambio de tamaño de ventana y ajustar posición
    if (_lastScreenSize != null && _lastScreenSize != screenSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Ajustar posición para mantener el componente visible
            final leftMargin = screenSize.width < 600 ? 90.0 : 120.0;
            double newX = position.dx.clamp(
              leftMargin,
              screenSize.width - railWidth,
            );
            double newY = position.dy.clamp(
              safeArea.top,
              screenSize.height - railHeight - safeArea.bottom,
            );
            position = Offset(newX, newY);
          });
        }
      });
    }
    _lastScreenSize = screenSize;

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
            // Calcular nueva posición con margen para el menú lateral
            final leftMargin = screenSize.width < 600 ? 90.0 : 120.0;
            double newX = (position.dx + details.delta.dx).clamp(
              leftMargin,
              screenSize.width - railWidth,
            );
            double newY = (position.dy + details.delta.dy).clamp(
              safeArea.top,
              screenSize.height - railHeight - safeArea.bottom,
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
          _snapToEdges(screenSize, safeArea, railWidth, railHeight);

          // Vibración háptica de confirmación
          HapticFeedback.selectionClick();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? _scaleAnimation.value : 1.0,
              child: _buildDraggableSocialRail(),
            );
          },
        ),
      ),
    );
  }

  void _snapToEdges(
    Size screenSize,
    EdgeInsets safeArea,
    double railWidth,
    double railHeight,
  ) {
    const snapDistance = 60.0;
    double newX = position.dx;
    double newY = position.dy;

    // Snap horizontal - preferencia por los bordes
    if (position.dx < snapDistance) {
      newX = 0;
    } else if (position.dx > screenSize.width - railWidth - snapDistance) {
      newX = screenSize.width - railWidth;
    }

    // Snap vertical (opcional, solo si está muy cerca del borde)
    if (position.dy < safeArea.top + snapDistance) {
      newY = safeArea.top;
    } else if (position.dy >
        screenSize.height - railHeight - safeArea.bottom - snapDistance) {
      newY = screenSize.height - railHeight - safeArea.bottom;
    }

    // Animar el snap si hay cambio
    if (newX != position.dx || newY != position.dy) {
      setState(() {
        position = Offset(newX, newY);
      });
    }
  }

  Widget _buildDraggableSocialRail() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _isDragging ? Colors.black38 : Colors.black26,
            blurRadius: _isDragging ? 12 : 6,
            offset: Offset(0, _isDragging ? 4 : 2),
            spreadRadius: _isDragging ? 1 : 0,
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isDragging ? 0.9 : 1.0,
        child: SocialRail(
          links: widget.links,
          itemSize: widget.itemSize,
          iconSize: widget.iconSize,
          isDragging: _isDragging,
        ),
      ),
    );
  }
}
