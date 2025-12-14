import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/assets_constants.dart';

class ProfileImageMobileV3 extends StatelessWidget {
  final String? avatarUrl;
  final Size size;
  final int minHeight;

  const ProfileImageMobileV3({
    super.key,
    this.avatarUrl,
    required this.size,
    this.minHeight = 600,
  });

  bool _isSvg(String? url) =>
      url != null && url.toLowerCase().trim().endsWith('.svg');

  Future<bool> _isHighQuality(BuildContext context) async {
    // null/empty or svg -> no chequeo (devuelvo false por defecto)
    if (avatarUrl == null || avatarUrl!.isEmpty || _isSvg(avatarUrl)) {
      return false;
    }

    try {
      final provider = avatarUrl!.startsWith('http')
          ? NetworkImage(avatarUrl!)
          : AssetImage(avatarUrl!) as ImageProvider;

      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      final completer = Completer<ui.Image>();

      ImageStreamListener? listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener!);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          if (!completer.isCompleted) completer.completeError(error ?? 'error');
          stream.removeListener(listener!);
        },
      );

      stream.addListener(listener);

      final image = await completer.future.timeout(const Duration(seconds: 5));
      return image.height > minHeight;
    } catch (e) {
      return false;
    }
  }

  Widget placeHolderWidget(Size size) {
    // Si tu placeholder es svg:
    return SvgPicture.asset(
      AssetsConstants.placeholderIcon,
      width: size.width,
      height: size.height * 0.5,
      fit: BoxFit.cover,
      // opcional: placeholderBuilder
      placeholderBuilder: (context) => Container(color: Colors.grey.shade900),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height * 0.5,
      child: FutureBuilder<bool>(
        future: _isHighQuality(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(color: Colors.grey.shade900);
          }
          return _buildFullImage();
        },
      ),
    );
  }

  Widget _buildFullImage() {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // fondo base (siempre fullscreen)
        Container(color: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purpleAccent.withValues(alpha: 0.5),
              Colors.black,
            ],
          ),
        ).color),

        // Imagen real SOLO si existe
        if (hasAvatar)
          CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _buildPlaceholderOverlay(),
          ),

        // Placeholder SOLO cuando NO hay avatar
        if (!hasAvatar)
          _buildPlaceholderOverlay(),

        // 4️⃣ Gradiente inferior (siempre)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * 0.1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildPlaceholderOverlay() {
    return Align(
      alignment: const Alignment(0, 0), 
      child: SizedBox(
        width: size.width,  
        height: size.width,
        child: SvgPicture.asset(
          AssetsConstants.placeholderIcon,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
