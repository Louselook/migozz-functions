import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';

class GoRouterNotifier extends ChangeNotifier {
  final AuthCubit authCubit;
  AuthStatus _authStatus = AuthStatus.checking;

  GoRouterNotifier(this.authCubit) {
    // Suscribirse al cubit
    authCubit.stream.listen((state) {
      _authStatus = state.status;
      notifyListeners();
    });
  }

  AuthStatus get authStatus => _authStatus;
}
