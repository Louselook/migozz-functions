import 'dart:math';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class WebNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingBuilder;
  final double borderRadius;

  const WebNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingBuilder,
    this.borderRadius = 0,
  });

  @override
  State<WebNetworkImage> createState() => _WebNetworkImageState();
}

class _WebNetworkImageState extends State<WebNetworkImage> {
  late String viewId;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Generate a unique view ID for this specific image instance
    viewId =
        'web-image-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(10000)}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final img = html.ImageElement();
      // Use a CORS proxy to bypass restriction
      // We use wsrv.nl which is a reliable open source image proxy
      final proxyUrl =
          'https://wsrv.nl/?url=${Uri.encodeComponent(widget.imageUrl)}';

      img.src = proxyUrl;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = _mapBoxFit(widget.fit);
      // Prevent referrer leakage which can also cause blocking
      img.referrerPolicy = 'no-referrer';
      img.style.border = 'none';
      img.style.borderRadius = '${widget.borderRadius}px';

      // Handle error to switch to error widget if needed?
      // HtmlElementView doesn't easily notify Flutter of errors.
      // We can listen to onError inside the element, but updating Flutter state from there requires interop.
      img.onError.listen((event) {
        // We can't easily rebuild Flutter widget from here efficiently without some setup.
        // For now, we rely on the browser's broken image icon or try to hide it.
        // But better: we can try to use standard Image.network behavior logic
        // or just accept browser handling.
        // However, if we want to show our custom errorWidget, we need to know.
        if (mounted) {
          setState(() {
            _isError = true;
          });
        }
      });

      return img;
    });
  }

  String _mapBoxFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
      case BoxFit.none:
      case BoxFit.scaleDown:
        return 'none';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError && widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return HtmlElementView(viewType: viewId);
  }
}
