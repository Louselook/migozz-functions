/// Valida la respuesta del usuario según el índice del bot
bool validateCurrentField({required int botIndex, String? userResponse}) {
  if (userResponse == null || userResponse.trim().isEmpty) return false;

  switch (botIndex) {
    case 9: // teléfono
      return RegExp(r"^\+?\d{7,15}$").hasMatch(userResponse);
    case 20: // email
      return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(userResponse);
    // case 8: // teléfono
    //   return RegExp(r"^\+?\d{7,15}$").hasMatch(userResponse);
    default:
      return true;
  }
}
