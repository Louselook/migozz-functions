import 'package:flutter/foundation.dart';

/// Bus simple para solicitar la reproducción del tutorial del perfil.
///
/// Se usa para pedir el replay desde otra pantalla (ej. EditProfile),
/// navegar a /profile y ejecutar el tutorial cuando la pantalla ya está montada.
class ProfileTutorialReplayBus {
  static final ValueNotifier<int> _token = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _token;

  static void requestReplay() {
    _token.value = _token.value + 1;
  }
}
