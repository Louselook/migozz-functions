import 'package:flutter/widgets.dart';

// remplazar mas adelante por una modelo para el registro
class FlowManager extends ChangeNotifier {
  Map<String, dynamic> userData = {
    "language": null,
    "name": null,
    "username": null,
    "gender": null,
    "socials": [],
    "location": null,
    // agregar mas
  };

  void updateField(String key, dynamic value) {
    userData[key] = value;
    notifyListeners();
  }
}
