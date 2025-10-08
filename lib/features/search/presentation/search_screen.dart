import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/search/components/Input_search.dart';
import 'package:migozz_app/features/search/components/filter_search.dart';
import 'package:migozz_app/features/search/components/Suggested_Reels.dart';
import 'package:migozz_app/features/search/components/result_search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _tab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Alturas base (mantenemos tus proporciones)
    final bottomGradientHeight = size.height * 0.22;

    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            // dar un color de fondo
            Container(color: Color.fromARGB(223, 0, 0, 0)),

            // Tintes y gradientes
            TintesGradients(child: Container(height: bottomGradientHeight)),

            // input search en top 0 y un arrow back
            InputSearch(
              controller: _searchController,
              onChanged: (txt) => setState(() => _query = txt.trim()),
            ),

            // filtros de busqueda ("For You", "Accounts", "Reels", "Audio", "Hashtags")
            FilterSearch(),

            // Contenido: mostramos sugerencias si no hay texto, o resultados cuando el usuario escribe
            if (_query.isEmpty)
              SuggestedReels(topPadding: 140)
            else
              // ResultSearch mostrará 'no se encontraron coincidencias' cuando aplique
              Positioned.fill(top: 180, child: ResultSearch(query: _query)),

            // Navegación inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: GradientBottomNav(
                currentIndex: _tab,
                onItemSelected: (i) => setState(() => _tab = i),
                onCenterTap: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
