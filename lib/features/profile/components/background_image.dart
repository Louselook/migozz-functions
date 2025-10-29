import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/info_user_profile.dart';
import 'package:migozz_app/features/profile/components/scroll_sheet.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final double minHeaderFraction;
  final String? avatarUrl;
  final String name;
  final String displayName;
  final String comunityCount;
  final String nameComunity;
  final String voiceNoteUrl;
  final bool isOwnProfile;
  final String userId;
  final TutorialKeys? tutorialKeys;

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
    this.isOwnProfile = true,
    this.userId = '',
    this.tutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;
    final bottomPaddingForCard = size.height * 0.15;

    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          bottom: false,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileHeaderDelegate(
                    maxHeight: size.height,
                    minHeight: size.height * minHeaderFraction,
                    bottomPaddingForCard: bottomPaddingForCard,
                    avatarUrl: avatarUrl,
                    name: name,
                    displayName: displayName,
                    comunityCount: comunityCount,
                    nameComunity: nameComunity,
                    voiceNoteUrl: voiceNoteUrl,
                    tutorialKeys: tutorialKeys,
                    isOwnProfile: isOwnProfile, // Nuevo
                    userId: userId, // Nuevo
                  ),
                ),
              ];
            },
            body: buildProfileCardsGrid(
              context,
              count: 30,
              onTap: (i) => debugPrint("Card $i tocada"),
              bottomExtraPadding: bottomGradientHeight,
            ),
          ),
        ),

        TintesGradients(child: Container(height: bottomGradientHeight)),
        child,
      ],
    );
  }
}

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
  final bool isOwnProfile; // Nuevo
  final String userId; // Nuevo
  final TutorialKeys? tutorialKeys;

  // Cacheamos el future para que no se regenere en cada build
  Future<bool>? _imageHeightFuture;

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
    required this.isOwnProfile, 
    required this.userId, 
    this.tutorialKeys,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.bottomPaddingForCard != bottomPaddingForCard ||
        oldDelegate.avatarUrl != avatarUrl;
  }

  /// Obtiene la ui.Image desde un ImageProvider (NetworkImage / AssetImage)
  Future<ui.Image?> _getImageFromProvider(
    ImageProvider provider,
    ImageConfiguration config,
  ) {
    final completer = Completer<ui.Image?>();
    final stream = provider.resolve(config);
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        debugPrint(
          "🟢 _getImageFromProvider: image resolved ${info.image.width}x${info.image.height}",
        );
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        debugPrint("❌ _getImageFromProvider: error -> $error");
        completer.complete(null);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        try {
          stream.removeListener(listener);
        } catch (_) {}
        debugPrint("⚠️ _getImageFromProvider: timeout");
        return null;
      },
    );
  }

  /// Devuelve true si la imagen tiene altura mayor que threshold (ej. 600)
  Future<bool> _isImageTallEnough(
    BuildContext context,
    String? avatarUrl, {
    int threshold = 600,
  }) async {
    debugPrint("➡️ Evaluando altura de imagen: $avatarUrl");
    if (avatarUrl == null || avatarUrl.isEmpty) {
      debugPrint("⚠️ avatarUrl vacía -> usar modo pequeño");
      return false;
    }

    final ImageProvider provider = avatarUrl.startsWith('http')
        ? NetworkImage(avatarUrl)
        : AssetImage(avatarUrl) as ImageProvider;

    try {
      final config = createLocalImageConfiguration(context);
      final ui.Image? img = await _getImageFromProvider(provider, config);
      if (img == null) {
        debugPrint("⚠️ Imagen no disponible o no pudo decodificarse");
        return false;
      }
      debugPrint("📏 Altura imagen: ${img.height} (threshold: $threshold)");
      return img.height > threshold;
    } catch (e, st) {
      debugPrint("❌ Error en _isImageTallEnough: $e\n$st");
      return false;
    }
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Inicializamos el future solo una vez por instancia del delegate
    _imageHeightFuture ??= _isImageTallEnough(context, avatarUrl);

    return FutureBuilder<bool>(
      future: _imageHeightFuture,
      builder: (context, snapshot) {
        final bool useFullBackground = snapshot.data ?? false;

        // Opcional: mostrar logs del estado del snapshot para depuración
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("🕐 FutureBuilder: waiting for image size...");
        } else if (snapshot.hasError) {
          debugPrint("❌ FutureBuilder error: ${snapshot.error}");
        } else {
          debugPrint(
            "ℹ️ FutureBuilder result: useFullBackground=$useFullBackground",
          );
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🔁 Fondo según tamaño de imagen
              useFullBackground
                  ? _buildFullBackground()
                  : _buildCircleAvatarBackground(context),

              // 📇 Card con info del usuario
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
                        isOwnProfile: isOwnProfile, // Agregado para search
                        userId: userId, // Agregado para search
                        tutorialKeys: tutorialKeys,
                      ),
                    ),
                  ),
                ),
              ),

              // 🌙 Oscurecido inferior
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
      },
    );
  }

  // Modo: imagen completa
  Widget _buildFullBackground() {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        1.15,0,0,0,0,0,1.15,0,0,0,0,0,1.25,0,0,0,1,1,2,0,
      ]),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                "assets/images/profileBackground.webp",
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              "assets/images/profileBackground.webp",
              fit: BoxFit.cover,
            ),
    );
  }

  // Modo: imagen pequeña (CircleAvatar)
  Widget _buildCircleAvatarBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset("assets/images/profileBackground.webp", fit: BoxFit.cover),
        Center(
          child: CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.25,
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : const AssetImage("assets/images/profileBackground.webp")
                      as ImageProvider,
          ),
        ),
      ],
    );
  }
}
