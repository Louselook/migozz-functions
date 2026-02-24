import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/image_proxy_helper.dart';

/// A wrapper around CachedNetworkImage that automatically uses proxy for web
class ProxiedCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final double? width;
  final double? height;

  const ProxiedCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: ImageProxyHelper.getProxiedUrl(imageUrl),
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      width: width,
      height: height,
    );
  }
}

