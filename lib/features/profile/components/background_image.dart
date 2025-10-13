import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/scroll_sheet.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;

  /// Qué tanto puede colapsar el header (0.5 = se detiene a mitad de pantalla)
  final double minHeaderFraction;
  // Datos del perfil
  final String? avatarUrl;
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final String voiceNoteUrl;

  const BackgroundImage({
    super.key,
    required this.child,
    this.minHeaderFraction = 0.4,
    this.avatarUrl,
    this.name = 'John Doe',
    this.displayName = '@johndoe',
    this.comunityCount = '1M',
    this.nameComunity = 'Community',
    this.voiceNoteUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Alturas base (mantenemos tus proporciones)
    final bottomGradientHeight = size.height * 0.22;
    final bottomPaddingForCard = size.height * 0.15;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Contenido scrollable: header + grid
        SafeArea(
          bottom: false,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileHeaderDelegate(
                    maxHeight: size.height, // estado expandido
                    minHeight:
                        size.height *
                        minHeaderFraction, // colapso mínimo (50% de alto)
                    bottomPaddingForCard: bottomPaddingForCard,
                    avatarUrl: avatarUrl,
                    name: name,
                    displayName: displayName,
                    comunityCount: comunityCount,
                    nameComunity: nameComunity,
                    voiceNoteUrl: voiceNoteUrl,
                  ),
                ),
              ];
            },
            // El body maneja su propio scroll (arriba/abajo según cantidad)
            body: buildProfileCardsGrid(
              context,
              count: 30,
              onTap: (i) => debugPrint("Card $i tocada"),
              // Deja un padding inferior para no chocar con tu bottom nav
              bottomExtraPadding: bottomGradientHeight,
            ),
          ),
        ),

        TintesGradients(child: Container(height: bottomGradientHeight)),
        // Overlays por encima (IA, rail, bottom nav, etc.)
        child,
      ],
    );
  }
}

/// Delegate del header que colapsa hasta minHeight y muestra tu imagen + card de perfil
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final double bottomPaddingForCard;
  final String? avatarUrl;
  final String voiceNoteUrl;
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;

  _ProfileHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.bottomPaddingForCard,
    this.avatarUrl,
    required this.voiceNoteUrl,
    required this.name,
    required this.displayName,
    required this.comunityCount,
    required this.nameComunity,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.bottomPaddingForCard != bottomPaddingForCard;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Progreso de colapso 0..1
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen base (con tu filtro)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.15, 0, 0, 0, 0, // R
              0, 1.15, 0, 0, 0, // G
              0, 0, 1.25, 0, 0, // B
              0, 1, 1, 2, 0, // A
            ]),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    key: ValueKey<String>(
                      avatarUrl!,
                    ), // fuerza refresh cuando cambia la URL
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      "assets/images/profileBackground.jpg",
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    "assets/images/profileBackground.jpg",
                    fit: BoxFit.cover,
                  ),
          ),

          // Card de perfil centrada abajo (mantiene posición relativa)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottomPaddingForCard * (1.2 - 0.25 * t),
                  left: 16,
                  right: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                    minHeight: 80,
                    maxHeight: 180,
                  ),
                  child: const IntrinsicHeight(child: SizedBox.shrink()),
                ),
              ),
            ),
          ),

          // Info card (separada para inyectar datos dinámicos sin const)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottomPaddingForCard * (1.2 - 0.17 * t),
                  left: 16,
                  right: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    minHeight: 80,
                    maxHeight: 180,
                  ),
                  child: InfoUserProfile(
                    name: name,
                    displayName: displayName,
                    comunityCount: comunityCount,
                    nameComunity: nameComunity,
                    voiceNoteUrl: voiceNoteUrl,
                  ),
                ),
              ),
            ),
          ),

          // Suave oscurecido inferior para legibilidad cuando se acerca el content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15 + 0.17 * t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
