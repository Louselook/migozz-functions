import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  Future<bool> _isHighQuality(BuildContext context) async {
    if (avatarUrl == null || avatarUrl!.isEmpty) return false;

    try {
      final provider = avatarUrl!.startsWith('http')
          ? NetworkImage(avatarUrl!)
          : AssetImage(avatarUrl!) as ImageProvider;

      final stream = provider.resolve(createLocalImageConfiguration(context));
      final completer = Completer<ui.Image>();

      stream.addListener(
        ImageStreamListener((info, _) {
          completer.complete(info.image);
        }),
      );

      final image = await completer.future.timeout(const Duration(seconds: 5));
      return image.height > minHeight;
    } catch (e) {
      return false;
    }
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

          return snapshot.data! ? _buildFullImage() : _buildCircleAvatar();
        },
      ),
    );
  }

  Widget _buildFullImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
         imageUrl: avatarUrl!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Image.asset(
            'assets/images/profileBackground.webp',
            fit: BoxFit.cover,
          ),
        ),
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

  Widget _buildCircleAvatar() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/profileBackground.webp', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.3)),
        Center(
          child: CircleAvatar(
            radius: size.width * 0.25,
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : const AssetImage('assets/images/profileBackground.webp')
                      as ImageProvider,
          ),
        ),
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
                colors: [Colors.transparent, Colors.black],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
