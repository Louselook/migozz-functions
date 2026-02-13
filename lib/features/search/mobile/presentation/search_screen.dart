import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'package:migozz_app/features/search/mobile/components/input_search.dart';
// import 'package:migozz_app/features/search/mobile/components/filter_search.dart';
import 'package:migozz_app/features/search/mobile/components/result_search.dart';
import 'package:migozz_app/features/search/mobile/components/suggested_reels.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class SearchScreen extends StatefulWidget {
  final TutorialKeys tutorialKeys;
  const SearchScreen({super.key, required this.tutorialKeys});

  /// Variable estática que indica si el usuario ya descartó el diálogo de intereses
  /// durante esta sesión de la app. Se resetea al cerrar y volver a abrir la app.
  static bool hasSkippedInterestsThisSession = false;

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _checkedInterests = false; // evita chequear varias veces

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> checkAndMaybeOpenEditInterests() async {
    if (_checkedInterests) return;
    _checkedInterests = true;

    // Si el usuario ya descartó el diálogo de intereses en esta sesión, no mostrar
    if (SearchScreen.hasSkippedInterestsThisSession) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return; // usuario no logueado -> no forzar nada

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userInterests = doc.data()?['interests'] as Map<String, dynamic>?;

      final bool empty = _isInterestsEmpty(userInterests);

      if (!mounted) return; // protege el uso de context después del await

      if (empty) {
        // Abrir pantalla de editar intereses y esperar resultado
        final _ = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EditInterestsScreen(),
            fullscreenDialog: true,
          ),
        );

        // Tras volver, re-chequeamos si ya puso intereses
        final doc2 = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userInterests2 =
            doc2.data()?['interests'] as Map<String, dynamic>?;
        final bool nowHas = !_isInterestsEmpty(userInterests2);

        if (!mounted) return;

        if (!nowHas) {
          // Si sigue vacío, marcar que ya descartó el diálogo en esta sesión
          SearchScreen.hasSkippedInterestsThisSession = true;

          // Avisamos y dejamos al usuario en search (puede salir a explorar igual)
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('search.validations.emptyInterest'.tr()),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        // si nowHas == true -> ya tiene intereses, todo ok
      }
    } catch (e, st) {
      debugPrint('Error checking interests on SearchScreen: $e\n$st');
      // no rompas la experiencia si falla: solo loguea
    }
  }

  bool _isInterestsEmpty(Map<String, dynamic>? userInterests) {
    if (userInterests == null) return true;
    for (final v in userInterests.values) {
      if (v is List && v.isNotEmpty) return false;
      if (v is Iterable && v.isNotEmpty) return false;
      if (v is Map && v.isNotEmpty) return false;
    }
    return true;
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
                  // FilterSearch(topPadding: 0),

                  // Contenido dinámico (sin wrapper de pull-to-refresh)
                  Expanded(
                    child: _query.isEmpty
                        ? const SuggestedReels(
                            topPadding: 20,
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
