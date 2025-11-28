import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/search/mobile/components/input_search.dart';
import 'package:migozz_app/features/search/mobile/components/filter_search.dart';
import 'package:migozz_app/features/search/mobile/components/result_search.dart';
import 'package:migozz_app/features/search/mobile/components/suggested_reels.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class SearchScreen extends StatefulWidget {
  final TutorialKeys tutorialKeys;
  const SearchScreen({super.key, required this.tutorialKeys,});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(223, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de búsqueda
                  InputSearch(
                    controller: _searchController,
                    onChanged: (txt) {
                      setState(() {
                        _query = txt.trim();
                      });
                    },
                  ),

                  // Filtros
                  FilterSearch(topPadding: 0),

                  // Contenido dinámico (sin wrapper de pull-to-refresh)
                  Expanded(
                    child: _query.isEmpty
                        ? const SuggestedReels(
                            topPadding: 0,
                          ) // Con pull-to-refresh interno
                        : ResultSearch(query: _query), // Sin pull-to-refresh
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
