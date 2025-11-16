import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/login_cubit/login_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/data/datasources/user_service.dart';
import 'package:migozz_app/injection.dart'; // Tu archivo de inyección de dependencias

/// Lista de providers globales de la app
final List<BlocProvider> blocProviders = [
  // AuthCubit con arquitectura limpia
  BlocProvider<AuthCubit>(
    create: (context) =>
        AuthCubit(locator<AuthUseCases>(), locator<UserService>()),
  ),

  // LoginCubit - mantener como está por ahora
  BlocProvider<LoginCubit>(create: (context) => LoginCubit()),

  // RegisterCubit - mantener como está por ahora
  BlocProvider<RegisterCubit>(
    create: (context) => RegisterCubit(locator<LocationService>()),
  ),

  // EditCubit - mantener como está por ahora
  BlocProvider<EditCubit>(
    create: (context) =>
        EditCubit(locator<UserService>(), context.read<AuthCubit>()),
  ),
];
