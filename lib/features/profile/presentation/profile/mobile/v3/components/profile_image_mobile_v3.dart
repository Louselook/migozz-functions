import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/assets_constants.dart';

class ProfileImageMobileV3 extends StatelessWidget {
  final String? avatarUrl;
  final Size size;
  final double? height;
  final int minHeight;
  final bool isOwnProfile;
  final VoidCallback? onTapAddCover;

  const ProfileImageMobileV3({
    super.key,
    this.avatarUrl,
    required this.size,
    this.height,
    this.minHeight = 600,
    this.isOwnProfile = false,
    this.onTapAddCover,
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
      height: size.height,
      fit: BoxFit.cover,
      // opcional: placeholderBuilder
      placeholderBuilder: (context) => Container(color: Colors.grey.shade900),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : size.width;
        final effectiveHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (height ?? size.height);
        final effectiveSize = Size(effectiveWidth, effectiveHeight);

        return SizedBox(
          width: effectiveSize.width,
          height: effectiveSize.height,
          child: FutureBuilder<bool>(
            future: _isHighQuality(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(color: Colors.grey.shade900);
              }
              return _buildFullImage(effectiveSize);
            },
          ),
        );
      },
    );
  }

  Widget _buildFullImage(Size effectiveSize) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // fondo base (siempre fullscreen)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purpleAccent.withValues(alpha: 0.5),
                Colors.black,
              ],
            ),
          ),
        ),


        // Imagen real SOLO si existe
        if (hasAvatar)
          CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _buildPlaceholderOverlay(effectiveSize),
          ),

        // Placeholder SOLO cuando NO hay avatar
        if (!hasAvatar)
          _buildPlaceholderOverlay(effectiveSize),

        // 4️⃣ Gradiente inferior (siempre)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: effectiveSize.height * 0.45,
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

  Widget _buildPlaceholderOverlay([Size? effectiveSize]) {
    final s = effectiveSize ?? size;
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.2),
          child: SizedBox(
            width: s.width,
            height: s.width,
            child: SvgPicture.asset(
              AssetsConstants.placeholderIcon,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        // Empty state overlay for own profile
        if (isOwnProfile)
          Positioned.fill(
            child: GestureDetector(
              onTap: onTapAddCover,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'profile.customization.coverImage.add'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'profile.customization.coverImage.subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
