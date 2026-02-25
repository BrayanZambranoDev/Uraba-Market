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
        'lastLogin':
            FieldValue.serverTimestamp(), // Usar tiempo del servidor es mejor
        'fechaRegistro': FieldValue.serverTimestamp(),
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

  // Nueva función: Para publicar un producto
  Future<void> publicarProducto(Map<String, dynamic> productoData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      // Obtener el nombre del vendedor desde su perfil de usuario
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final vendedor =
          userDoc.data()?['nombre'] ?? user.displayName ?? 'Comerciante';

      // Completar los datos del producto
      Map<String, dynamic> dataToSave = {
        ...productoData,
        'vendedor': vendedor,
        'vendedorId': user.uid,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      await _db.collection('productos').add(dataToSave);
    } catch (e) {
      throw Exception('Error al publicar el producto: $e');
    }
  }

  // Nueva función: Para obtener las conversaciones de un usuario
  Stream<QuerySnapshot> getConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('ultimoTimestamp', descending: true)
        .snapshots();
  }

  // Nueva función: Para contar productos por categoría
  Future<Map<String, int>> getProductCountByCategory() async {
    try {
      QuerySnapshot snapshot = await _db.collection('productos').get();
      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['categoria'] as String?;
        if (category != null) {
          counts[category] = (counts[category] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  // Nueva función: Para obtener estadísticas de precios por categoría
  Future<Map<String, dynamic>> getPriceStats(String category) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('productos')
          .where('categoria', isEqualTo: category)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
      }

      double sum = 0;
      double minPrice = double.maxFinite;
      double maxPrice = 0;

      for (var doc in snapshot.docs) {
        final price =
            (doc.data() as Map<String, dynamic>)['precio'] as num? ?? 0;
        sum += price;
        if (price < minPrice) minPrice = price.toDouble();
        if (price > maxPrice) maxPrice = price.toDouble();
      }
      return {
        'count': snapshot.docs.length,
        'avg': sum / snapshot.docs.length,
        'min': minPrice,
        'max': maxPrice
      };
    } catch (e) {
      return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
    }
  }
}
