import 'package:flutter/material.dart';

class SuggestedReels extends StatelessWidget {
  /// topPadding permite ajustar la separación desde arriba cuando se inserta
  /// dentro de una pantalla que ya contiene `InputSearch` y `FilterSearch`.
  final double topPadding;

  const SuggestedReels({super.key, this.topPadding = 140});

  // Datos simulados para mostrar en las cards
  List<Map<String, dynamic>> get _mockItems {
    final images = [
      'assets/images/onboarding_1.png',
      'assets/images/onboarding_2.png',
      'assets/images/onboarding_3.png',
      'assets/images/profileBackground.jpg',
      'assets/images/otp_image.png',
    ];

    return List.generate(12, (i) {
      return {
        'image': images[i % images.length],
        'name': [
          'Javier Cole',
          'Logan Reed',
          'Emily Dawson',
          'Eli West',
          'Andre Knox',
        ][i % 5],
        'location': [
          'Miami, FL',
          'Dallas, TX',
          'Portland, OR',
          'Eugene, OR',
          'Tucson, AZ',
        ][i % 5],
        'views': '${(i + 1) * 1}M',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _mockItems;

    final size = MediaQuery.of(context).size;
    final scale = size.width / 375.0;
    final horizontalMargin = (12.0 * scale).clamp(8.0, 20.0);
    final bottomMargin = (100.0 * scale).clamp(60.0, 160.0);

    final crossAxisCount = size.width > 650 ? 3 : 2;
    final crossAxisSpacing = (12.0 * scale).clamp(8.0, 20.0);
    final mainAxisSpacing = (12.0 * scale).clamp(8.0, 20.0);
    // Adjust aspect ratio a bit based on scale to keep cards pleasant
    final childAspectRatio = (0.72 / (scale.clamp(0.85, 1.25))).clamp(0.6, 1.1);

    return Container(
      // permite posicionar el grid cuando se inserta dentro de otras capas
      margin: EdgeInsets.only(
        top: topPadding,
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: bottomMargin,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _SuggestionCard(
            image: item['image'] as String,
            name: item['name'] as String,
            location: item['location'] as String,
            views: item['views'] as String,
            // pass scale for internal sizing
            scale: scale,
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String image;
  final String name;
  final String location;
  final String views;
  final double scale;

  const _SuggestionCard({
    required this.image,
    required this.name,
    required this.location,
    required this.views,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cornerRadius = (12.0 * scale).clamp(8.0, 20.0);
    final topIconPadding = (8.0 * scale).clamp(6.0, 12.0);
    final topIconSize = (16.0 * scale).clamp(12.0, 22.0);
    final gradientPadding = (8.0 * scale).clamp(6.0, 14.0);
    final avatarSize = (40.0 * scale).clamp(28.0, 56.0);
    final nameFont = (13.0 * scale).clamp(11.0, 18.0);
    final locationFont = (11.0 * scale).clamp(9.0, 14.0);
    final iconSize = (18.0 * scale).clamp(14.0, 22.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Material(
        color: Colors.grey.shade900,
        child: InkWell(
          onTap: () {},
          child: Stack(
            children: [
              // Imagen de fondo
              Positioned.fill(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
                ),
              ),

              // Pequeño icono en la esquina superior derecha
              Positioned(
                top: topIconPadding,
                right: topIconPadding,
                child: Container(
                  padding: EdgeInsets.all((6.0 * scale).clamp(4.0, 10.0)),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(
                      (8.0 * scale).clamp(6.0, 12.0),
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: topIconSize,
                    color: Colors.white70,
                  ),
                ),
              ),

              // Gradiente inferior y texto
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(gradientPadding),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar pequeño
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white24,
                            width: (1.5 * scale).clamp(1.0, 2.5),
                          ),
                          image: DecorationImage(
                            image: AssetImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: (8.0 * scale).clamp(6.0, 12.0)),
                      // Nombre y ubicación
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: nameFont,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: (2.0 * scale).clamp(2.0, 6.0)),
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: locationFont,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contador de views
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white70,
                            size: iconSize,
                          ),
                          Text(
                            views,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: locationFont,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
