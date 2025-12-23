import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/interests/interests_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_simple_step.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';

//  Modo de operación del componente
enum MoreUserDetailsMode { register, edit }

class MoreUserDetails extends StatefulWidget {
  final int pageIndicator;
  final MoreUserDetailsMode mode;
  final String? userId;

  const MoreUserDetails({
    super.key,
    this.pageIndicator = 0,
    this.mode = MoreUserDetailsMode.register,
    this.userId,
  });

  @override
  State<MoreUserDetails> createState() => _MoreUserDetailsState();
}

class _MoreUserDetailsState extends State<MoreUserDetails> {
  late PageController pageController;

  // For register mode: track which view to show
  // false = simple list view (default)
  // true = full grid view with categories
  bool _showFullSocialView = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.pageIndicator);

    // Si estamos en modo edición, inicializar los datos del usuario
    if (widget.mode == MoreUserDetailsMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditMode();
      });
    }
  }

  // Inicializar datos del usuario en modo edición
  void _initializeEditMode() {
    debugPrint('🔹 [MoreUserDetails] Intentando inicializar modo edición');

    final authState = context.read<AuthCubit>().state;
    debugPrint(
      '🔹 [MoreUserDetails] AuthState disponible: ${authState.userProfile != null}',
    );

    if (authState.userProfile == null) {
      debugPrint('❌ [MoreUserDetails] userProfile es NULL');
      return;
    }

    final editCubit = context.read<EditCubit>();
    final userProfile = authState.userProfile!;

    debugPrint(
      '🔹 [MoreUserDetails] Inicializando EditCubit con datos del perfil',
    );
    debugPrint('🔹 socialEcosystem: ${userProfile.socialEcosystem}');
    debugPrint('🔹 category: ${userProfile.category}');
    debugPrint('🔹 interests: ${userProfile.interests}');

    editCubit.initializeFromUser(
      socialEcosystem: userProfile.socialEcosystem,
      category: userProfile.category,
      interests: userProfile.interests,
    );

    // Verificar que se haya guardado
    debugPrint(
      '🔹 EditCubit después de init: ${editCubit.state.socialEcosystem}',
    );
  }

  void _navigateToFullSocialView() {
    // Navigate from simple list to full grid view
    setState(() {
      _showFullSocialView = true;
    });
  }

  void _navigateBackToSimpleView() {
    // Navigate back to simple list view
    setState(() {
      _showFullSocialView = false;
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> steps;

    if (widget.mode == MoreUserDetailsMode.register) {
      // In register mode, show simple or full view based on state
      if (_showFullSocialView) {
        // Full view with all categories and search
        steps = [
          SocialEcosystemStepV3(controller: pageController, mode: widget.mode),
          InterestsStep(controller: pageController, mode: widget.mode),
        ];
      } else {
        // Simple view with main networks only
        steps = [
          SocialEcosystemSimpleStep(
            controller: pageController,
            onAddOtherNetworks: _navigateToFullSocialView,
          ),
          InterestsStep(controller: pageController, mode: widget.mode),
        ];
      }
    } else {
      // In edit mode, always show full v3 view
      steps = [
        SocialEcosystemStepV3(controller: pageController, mode: widget.mode),
        InterestsStep(controller: pageController, mode: widget.mode),
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: widget.mode == MoreUserDetailsMode.edit
          ? AppBar(
              backgroundColor: AppColors.backgroundDark,
              title: const Text('Edit Profile'),
              elevation: 0,
            )
          : null,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: PageView.builder(
              controller: pageController,
              itemCount: steps.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {});
              },
              itemBuilder: (_, index) => steps[index],
            ),
          ),
        ],
      ),
    );
  }
}
