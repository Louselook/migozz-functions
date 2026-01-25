// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:migozz_app/core/di/app_module.dart' as _i433;
import 'package:migozz_app/features/auth/data/datasources/auth_service.dart'
    as _i315;
import 'package:migozz_app/features/auth/data/domain/repository/auth_repository.dart'
    as _i974;
import 'package:migozz_app/features/auth/data/domain/use_cases/auth_use_cases.dart'
    as _i467;
import 'package:migozz_app/features/auth/services/location_service.dart'
    as _i530;
import 'package:migozz_app/features/auth/services/media_service.dart' as _i341;
import 'package:migozz_app/features/profile/data/datasources/follower_service.dart'
    as _i440;
import 'package:migozz_app/features/profile/data/datasources/user_service.dart'
    as _i867;
import 'package:migozz_app/features/profile/data/domain/repository/user_repository.dart'
    as _i345;
import 'package:migozz_app/features/profile/data/domain/use_cases/user_use_cases.dart'
    as _i484;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.factory<_i315.AuthService>(() => appModule.authService);
    gh.factory<_i974.AuthRepository>(() => appModule.authRepository);
    gh.factory<_i467.AuthUseCases>(() => appModule.authUseCases);
    gh.lazySingleton<_i530.LocationService>(() => appModule.locationService);
    gh.lazySingleton<_i341.UserMediaService>(() => appModule.userMediaService);
    gh.lazySingleton<_i867.UserService>(() => appModule.userService);
    gh.lazySingleton<_i440.FollowerService>(() => appModule.followerService);
    gh.lazySingleton<_i345.UserRepository>(() => appModule.userRepository);
    gh.lazySingleton<_i484.UserUseCases>(() => appModule.userUseCases);
    return this;
  }
}

class _$AppModule extends _i433.AppModule {}
