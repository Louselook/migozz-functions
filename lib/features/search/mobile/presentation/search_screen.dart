// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/search/mobile/components/input_search.dart';
import 'package:migozz_app/features/search/mobile/components/filter_search.dart';
import 'package:migozz_app/features/search/mobile/components/result_search.dart';
import 'package:migozz_app/features/search/mobile/components/suggested_reels.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // int _tab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Alturas base (mantenemos tus proporciones)
    final bottomGradientHeight = size.height * 0.22;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo oscuro
          Container(color: const Color.fromARGB(223, 0, 0, 0)),

          // Tintes y gradientes en la parte inferior
          TintesGradients(child: Container(height: bottomGradientHeight)),

          // Contenido principal: Column con InputSearch, FilterSearch y contenido
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Barra de búsqueda (top)
                  InputSearch(
                    controller: _searchController,
                    onChanged: (txt) => setState(() => _query = txt.trim()),
                  ),

                  // 2) Filtros de búsqueda
                  FilterSearch(topPadding: 0),

                  // 3) Contenido que ocupa el resto de la pantalla
                  Expanded(
                    child: _query.isEmpty
                        // Muestra sugerencias cuando no hay texto
                        ? SuggestedReels(topPadding: 0)
                        // Muestra resultados cuando hay query
                        : ResultSearch(query: _query),
                  ),
                ],
              ),
            ),
          ),

          // (Opcional) Si quieres mantener algo absolutamente posicionado
          // como un botón flotante, añádelo aquí a la Stack.
        ],
      ),
    );
  }
}
