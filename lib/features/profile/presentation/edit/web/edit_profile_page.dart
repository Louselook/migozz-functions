import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_background.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_form.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_image_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_navigation_bar.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/edit_profile_options.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Breakpoints
    final isMobile = screenWidth < 900;
    final isSmallScreen = screenWidth < 600;

    // Ancho mínimo para evitar errores de constraints
    const minWidth = 400.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      ),
      backgroundColor: Colors.black,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // Validar si hay usuario
          if (authState.isLoadingProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authState.userProfile;
          if (user == null) {
            return const Center(
              child: Text(
                'No user data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            children: [
              // Gradientes de fondo
              const EditProfileBackground(),

              // Barra de navegación
              EditProfileNavigationBar(
                onBack: () => context.go('/profile'),
                onClose: () => context.go('/profile'),
              ),

              // Contenido principal
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: minWidth,
                      maxWidth: isMobile
                          ? screenWidth.clamp(minWidth, double.infinity)
                          : 1200,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 20 : 40,
                        right: isSmallScreen ? 20 : 40,
                        top: isSmallScreen ? 150 : 180,
                        bottom: 20,
                      ),
                      child: isMobile
                          ? Column(
                              children: [
                                _buildLeftColumn(isSmallScreen, user.avatarUrl),
                                const SizedBox(height: 30),
                                _buildRightColumn(context, authState),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLeftColumn(isSmallScreen, user.avatarUrl),
                                SizedBox(width: isSmallScreen ? 20 : 40),
                                Expanded(
                                  child: _buildRightColumn(context, authState),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftColumn(bool isSmallScreen, String? avatarUrl) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        // Usar ancho flexible en mobile, fijo en desktop
        final containerWidth = screenWidth < 900
            ? double.infinity
            : (isSmallScreen ? 280.0 : 360.0);

        // Tamaño de imagen adaptativo
        final imageSize = screenWidth < 900
            ? (screenWidth * 0.7).clamp(200.0, 320.0)
            : (isSmallScreen ? 250.0 : 320.0);

        // Usar avatar desde parámetro
        String imageProfile = "";
        if (avatarUrl == null || avatarUrl.isEmpty) {
          imageProfile = "assets/images/Migozz.webp";
        } else {
          imageProfile = avatarUrl;
        }

        return SizedBox(
          width: containerWidth,
          child: EditProfileImageSection(
            isSmallScreen: isSmallScreen,
            imageSize: imageSize,
            avatarUrl: imageProfile,
            onDeleteAccount: () {
              // TODO: Implementar lógica de eliminación de cuenta
            },
            onSave: () {
              // TODO: Implementar lógica de guardado
            },
          ),
        );
      },
    );
  }

  Widget _buildRightColumn(BuildContext context, AuthState authState) {
    final userId = authState.firebaseUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formulario con todos los campos
        const EditProfileForm(),

        const SizedBox(height: 30),
        // Opciones de edición
        EditProfileOptions(
          onEditRecord: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Use the app to change your audio")),
            );
          },
          onEditInterest: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditInterestsScreen()),
          ),
          onEditSocials: () {
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: User not logged in'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final editCubit = context.read<EditCubit>();
            editCubit.setEditItem(EditItem.socialEcosystem);

            debugPrint(
              '🔹 [EditProfileScreen] Navegando a MoreUserDetails en modo EDIT',
            );
            debugPrint('🔹 userId: $userId');

            // Pasar modo, userId y EditCubit
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: editCubit,
                  child: MoreUserDetails(
                    pageIndicator: 0,
                    mode: MoreUserDetailsMode.edit,
                    userId: userId,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
