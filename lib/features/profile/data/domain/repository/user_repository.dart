abstract class UserRepository {
  // Actualiza campos parciales del perfil
  Future<void> updateUserProfile(String userId, Map<String, dynamic> fields);

  // Cambia el avatar del usuario y devuelve la nueva URL
  Future<String?> changeAvatar(String userId);
}
