import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Instancia de la base de datos
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Función mejorada para guardar o actualizar usuario
  // Agregamos el parámetro opcional 'additionalData'
  Future<void> saveUser(User user,
      {Map<String, dynamic>? additionalData}) async {
    try {
      DocumentReference ref = _db.collection('users').doc(user.uid);

      // Datos básicos que siempre queremos tener
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(), // Usar tiempo del servidor es mejor
      };

      // Si vienen datos adicionales (desde la pantalla de completar perfil), los mezclamos
      if (additionalData != null) {
        userData.addAll(additionalData);
      }

      // Guardamos con merge: true para no sobreescribir campos existentes que no enviamos ahora
      await ref.set(userData, SetOptions(merge: true));
    } catch (e) {
      // Error silencioso - se maneja en la UI
    }
  }

  // Nueva función: Para saber si el usuario ya completó su perfil
  Future<bool> isProfileComplete(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Si el campo 'profileCompleted' es true, el perfil está listo
       return data['perfilCompleto'] ?? false;

      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
