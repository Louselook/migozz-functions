import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';

class GoRouterNotifier extends ChangeNotifier {
  final AuthCubit authCubit;
  AuthStatus _authStatus;
  StreamSubscription? _sub;

  GoRouterNotifier(this.authCubit) : _authStatus = authCubit.state.status {
    // Suscribirse al cubit y actualizar estado local
    _sub = authCubit.stream.listen((state) {
      if (state.status != _authStatus) {
        _authStatus = state.status;
        notifyListeners();
      }
    });
  }

  AuthStatus get authStatus => _authStatus;

  // Exponer el AuthCubit para lecturas seguras desde el redirect
  AuthCubit get getAuthCubit => authCubit;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
