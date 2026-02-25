import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────── USUARIOS ───────────────────────────

  Future<void> saveUser(User user,
      {Map<String, dynamic>? additionalData}) async {
    try {
      final ref = _db.collection('users').doc(user.uid);
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'fechaRegistro': FieldValue.serverTimestamp(),
      };
      if (additionalData != null) {
        userData.addAll(additionalData);
      }
      await ref.set(userData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['perfilCompleto'] ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Obtener datos de un usuario por uid
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────── PRODUCTOS ───────────────────────────

  Future<void> publicarProducto(Map<String, dynamic> productoData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final vendedor =
          userDoc.data()?['nombre'] ?? user.displayName ?? 'Comerciante';
      final dataToSave = {
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

  /// Productos de un vendedor específico
  Stream<QuerySnapshot> getVendorProducts(String vendorId) {
    return _db
        .collection('productos')
        .where('vendedorId', isEqualTo: vendorId)
        .where('activo', isEqualTo: true)
        .snapshots();
  }

  // ─────────────────────────── PEDIDOS ───────────────────────────

  /// Crear un nuevo pedido
  Future<String?> createOrder({
    required String compradorId,
    required String compradorNombre,
    required String vendedorId,
    required String vendedorNombre,
    required String productoId,
    required String productoNombre,
    required String productoCategoria,
    required int cantidad,
    required double precioUnitario,
    required String unidad,
  }) async {
    try {
      final ref = await _db.collection('pedidos').add({
        'compradorId': compradorId,
        'compradorNombre': compradorNombre,
        'vendedorId': vendedorId,
        'vendedorNombre': vendedorNombre,
        'productoId': productoId,
        'productoNombre': productoNombre,
        'productoCategoria': productoCategoria,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'precioTotal': precioUnitario * cantidad,
        'unidad': unidad,
        'estado': 'pendiente',
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Obtener pedidos del usuario (como comprador o vendedor)
  Stream<QuerySnapshot> getMyOrders(String userId, {required bool asVendedor}) {
    final field = asVendedor ? 'vendedorId' : 'compradorId';
    return _db
        .collection('pedidos')
        .where(field, isEqualTo: userId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots();
  }

  /// Actualizar el estado de un pedido
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('pedidos').doc(orderId).update({
        'estado': newStatus,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─────────────────────────── CONVERSACIONES ───────────────────────────

  /// Obtener o crear conversación entre dos usuarios
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userName1,
    required String userId2,
    required String userName2,
  }) async {
    // Buscar conversación existente
    final query = await _db
        .collection('conversations')
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in query.docs) {
      final ids = List<String>.from(doc['participantIds'] ?? []);
      if (ids.contains(userId2)) {
        return doc.id;
      }
    }

    // Crear nueva conversación
    final ref = await _db.collection('conversations').add({
      'participantIds': [userId1, userId2],
      'participantes': {
        userId1: userName1,
        userId2: userName2,
      },
      'ultimoMensaje': '',
      'ultimoTimestamp': FieldValue.serverTimestamp(),
      'ultimoSenderId': '',
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Stream de conversaciones de un usuario
  Stream<QuerySnapshot> getConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('ultimoTimestamp', descending: true)
        .snapshots();
  }

  /// Enviar un mensaje en una conversación
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      final batch = _db.batch();

      // Agregar mensaje a la subcolección
      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': senderId,
        'senderName': senderName,
        'texto': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Actualizar metadata de la conversación
      final convRef = _db.collection('conversations').doc(conversationId);
      batch.update(convRef, {
        'ultimoMensaje': text,
        'ultimoTimestamp': FieldValue.serverTimestamp(),
        'ultimoSenderId': senderId,
      });

      await batch.commit();
    } catch (_) {}
  }

  /// Stream de mensajes de una conversación
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ─────────────────────────── IA / ESTADÍSTICAS ───────────────────────────

  Future<Map<String, int>> getProductCountByCategory() async {
    try {
      final snapshot = await _db.collection('productos').get();
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['categoria'] as String?;
        if (category != null) {
          counts[category] = (counts[category] ?? 0) + 1;
        }
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getPriceStats(String category) async {
    try {
      final snapshot = await _db
          .collection('productos')
          .where('categoria', isEqualTo: category)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
      }

      double sum = 0;
      double minPrice = double.maxFinite;
      double maxPrice = 0;

      for (final doc in snapshot.docs) {
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
        'max': maxPrice,
      };
    } catch (_) {
      return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
    }
  }
}
