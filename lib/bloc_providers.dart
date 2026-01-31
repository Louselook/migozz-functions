import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/features/profile/data/datasources/follower_service.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit.dart';
import 'package:migozz_app/injection.dart';

// ✅ Crear instancias de los cubits ANTES de los providers
final loginCubit = LoginCubit();
final registerCubit = RegisterCubit(locator<LocationService>());
final authCubit = AuthCubit(locator<AuthUseCases>(), locator<UserService>());
late final EditCubit editCubit;
late final FollowerCubit followerCubit;
late final WalletCubit walletCubit;

// ✅ Inicializar los cubits y configurar callbacks
void initializeBlocProviders() {
  // Configurar callback de logout en AuthCubit
  authCubit.onLogoutRequested = () {
    debugPrint('🧹 [Logout] Limpiando LoginCubit...');
    loginCubit.resetState();

    debugPrint('🧹 [Logout] Limpiando RegisterCubit...');
    registerCubit.reset();

    debugPrint('🧹 [Logout] Limpiando EditCubit...');
    editCubit.reset();

    debugPrint('🧹 [Logout] Limpiando FollowerCubit...');
    followerCubit.reset();

    debugPrint('✅ [Logout] Todos los cubits limpiados');
  };

  // Crear EditCubit después de configurar el callback
  editCubit = EditCubit(locator<UserService>(), authCubit);
  
  // Crear FollowerCubit
  followerCubit = FollowerCubit(locator<FollowerService>());
  //Passing authCubit to Wallet cubit
  walletCubit = WalletCubit(authCubit: authCubit);

}

/// Lista de providers globales de la app - ESTÁTICA, creada UNA SOLA VEZ
final List<BlocProvider> blocProviders = [
  BlocProvider<AuthCubit>(create: (_) => authCubit),
  BlocProvider<LoginCubit>(create: (_) => loginCubit),
  BlocProvider<RegisterCubit>(create: (_) => registerCubit),
  BlocProvider<EditCubit>(create: (_) => editCubit),
  BlocProvider<FollowerCubit>(create: (_) => followerCubit),
  BlocProvider<WalletCubit>(create: (_) => walletCubit)
];
