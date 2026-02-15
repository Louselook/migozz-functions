import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/search/web/components/filter_search.dart';
import 'package:migozz_app/features/search/web/components/result_search.dart';
import 'package:migozz_app/features/search/web/components/input_search.dart';
import 'package:migozz_app/features/search/web/components/bottom_gradient.dart';
import 'package:migozz_app/features/search/web/components/search_content_container.dart';
import 'package:migozz_app/features/search/web/components/suggested_reels.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileWidth = size.width < 600;
    final bottomGradientHeight = size.height * 0.22;
    final sideMenuWidth = isMobileWidth ? 0.0 : 100.0;
    final availableWidth = size.width - sideMenuWidth;
    final horizontalPadding = isMobileWidth
        ? 16.0
        : availableWidth * 0.15;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: Stack(
        children: [
          // Tintes y gradientes
          _buildTopGradient(size),
          // Gradiente inferior
          BottomGradient(height: bottomGradientHeight),
          // Menú lateral izquierdo (hidden on mobile width)
          if (!isMobileWidth)
            const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),
          // Contenido principal
          SearchContentContainer(
            sideMenuWidth: sideMenuWidth,
            horizontalPadding: horizontalPadding,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient(Size size) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: TintesGradients(child: Container(height: size.height * 0.4)),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Input search
        InputSearch(
          controller: _searchController,
          onChanged: (txt) => setState(() => _query = txt.trim()),
        ),
        // Filtros de búsqueda
        const FilterSearch(),
        // Contenido: sugerencias o resultados
        Expanded(
          child: _query.isEmpty
              ? const SuggestedReels()
              : ResultSearch(query: _query),
        ),
      ],
    );
  }
}
