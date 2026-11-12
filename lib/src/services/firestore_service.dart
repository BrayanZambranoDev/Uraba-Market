import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

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
    } catch (e) {
      debugPrint('[FirestoreService] saveUser error: $e');
    }
  }

  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['perfilCompleto'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('[FirestoreService] isProfileComplete error: $e');
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
    } catch (e) {
      debugPrint('[FirestoreService] getUserData error: $e');
      return null;
    }
  }

  // ─────────────────────────── PRODUCTOS ───────────────────────────

  Future<void> publicarProducto(Map<String, dynamic> productoData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final vendedor = userData?['nombre'] ?? user.displayName ?? 'Vendedor';
      final vendedorRol = userData?['rol'] as String? ?? 'Comerciante';
      final dataToSave = {
        ...productoData,
        'vendedor': vendedor,
        'vendedorId': user.uid,
        'vendedorRol': vendedorRol,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };
      await _db.collection('productos').add(dataToSave);
    } catch (e) {
      throw Exception('Error al publicar el producto: $e');
    }
  }

  /// Productos de un vendedor específico (solo activos — para su perfil público)
  Stream<QuerySnapshot> getVendorProducts(String vendorId) {
    return _db
        .collection('productos')
        .where('vendedorId', isEqualTo: vendorId)
        .where('activo', isEqualTo: true)
        .snapshots();
  }

  /// Todos los productos del comerciante autenticado (activos e inactivos)
  Stream<QuerySnapshot> getMyProducts(String vendedorId) {
    return _db
        .collection('productos')
        .where('vendedorId', isEqualTo: vendedorId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots();
  }

  /// Actualizar un producto existente
  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      await _db.collection('productos').doc(productId).update({
        ...data,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] updateProduct error: $e');
      rethrow;
    }
  }

  /// Activar o desactivar un producto
  Future<void> toggleProductActive(String productId, bool activo) async {
    try {
      await _db.collection('productos').doc(productId).update({
        'activo': activo,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] toggleProductActive error: $e');
      rethrow;
    }
  }

  /// Incrementar el contador de vistas de un producto (best-effort, sin rethrow)
  Future<void> incrementViews(String productId) async {
    try {
      await _db.collection('productos').doc(productId).update({
        'vistas': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[FirestoreService] incrementViews: $e');
    }
  }

  /// Eliminar un producto permanentemente
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('productos').doc(productId).delete();
    } catch (e) {
      debugPrint('[FirestoreService] deleteProduct error: $e');
      rethrow;
    }
  }

  // ─────────────────────────── PEDIDOS ───────────────────────────

  /// Crear un nuevo pedido y descontar stock atómicamente con una transacción
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
    String notasComprador = '',
    String metodoPago = 'Contra entrega',
    Map<String, dynamic>? direccionEntrega,
  }) async {
    try {
      final productoRef = _db.collection('productos').doc(productoId);
      final pedidoRef = _db.collection('pedidos').doc();

      await _db.runTransaction((txn) async {
        final productoSnap = await txn.get(productoRef);
        if (!productoSnap.exists) {
          throw Exception('El producto ya no existe.');
        }
        final stockActual =
            (productoSnap.data()?['stock'] as num?)?.toInt() ?? 0;
        if (stockActual < cantidad) {
          throw Exception('Stock insuficiente. Disponible: $stockActual.');
        }

        txn.update(productoRef, {'stock': stockActual - cantidad});

        txn.set(pedidoRef, {
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
          'metodoPago': metodoPago,
          if (notasComprador.isNotEmpty) 'notasComprador': notasComprador,
          if (direccionEntrega != null) 'direccionEntrega': direccionEntrega,
        });

        // Entrada inicial en historial
        txn.set(
          pedidoRef.collection('historial').doc(),
          {
            'estado': 'pendiente',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      });

      // Notificar al vendedor (fire-and-forget, no bloquea el flujo)
      NotificationService.notifyNuevoPedido(
        vendedorId: vendedorId,
        compradorNombre: compradorNombre,
        productoNombre: productoNombre,
        cantidad: cantidad,
      );

      // Alerta de stock bajo después de la venta
      final prodSnap = await productoRef.get();
      final stockRestante = (prodSnap.data()?['stock'] as num?)?.toInt() ?? 0;
      if (stockRestante <= 5) {
        NotificationService.notifyStockBajo(
          vendedorId: vendedorId,
          productoNombre: productoNombre,
          stockRestante: stockRestante,
        );
      }

      return pedidoRef.id;
    } catch (e) {
      debugPrint('[FirestoreService] createOrder error: $e');
      rethrow;
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

  /// Cancelar un pedido y restaurar el stock del producto atómicamente
  Future<void> cancelOrder(String orderId, {String? motivo}) async {
    try {
      final orderRef = _db.collection('pedidos').doc(orderId);
      await _db.runTransaction((txn) async {
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) throw Exception('El pedido no existe.');
        final data = orderSnap.data()!;
        final estado = data['estado'] as String?;
        if (estado == 'cancelado') {
          throw Exception('El pedido ya fue cancelado.');
        }
        if (estado == 'entregado') {
          throw Exception('No se puede cancelar un pedido ya entregado.');
        }
        final productoId = data['productoId'] as String?;
        final cantidad = (data['cantidad'] as num?)?.toInt() ?? 0;
        // Restaurar stock si el producto aún existe
        if (productoId != null && productoId.isNotEmpty && cantidad > 0) {
          final productoRef = _db.collection('productos').doc(productoId);
          final productoSnap = await txn.get(productoRef);
          if (productoSnap.exists) {
            final stockActual =
                (productoSnap.data()?['stock'] as num?)?.toInt() ?? 0;
            txn.update(productoRef, {'stock': stockActual + cantidad});
          }
        }
        txn.update(orderRef, {
          'estado': 'cancelado',
          'fechaActualizacion': FieldValue.serverTimestamp(),
          if (motivo != null) 'motivoCancelacion': motivo,
        });
        txn.set(
          orderRef.collection('historial').doc(),
          {
            'estado': 'cancelado',
            'timestamp': FieldValue.serverTimestamp(),
            if (motivo != null) 'motivo': motivo,
          },
        );
      });
    } catch (e) {
      debugPrint('[FirestoreService] cancelOrder error: $e');
      rethrow;
    }
  }

  /// Actualizar el estado de un pedido y registrar en historial.
  /// [compradorId] y [productoNombre] opcionales — si se pasan, se envía
  /// notificación push al comprador.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? compradorId,
    String? productoNombre,
  }) async {
    try {
      final batch = _db.batch();
      batch.update(_db.collection('pedidos').doc(orderId), {
        'estado': newStatus,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      batch.set(
        _db.collection('pedidos').doc(orderId).collection('historial').doc(),
        {
          'estado': newStatus,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();

      // Notificar al comprador si se pasaron los datos necesarios
      if (compradorId != null && productoNombre != null) {
        NotificationService.notifyEstadoPedido(
          compradorId: compradorId,
          productoNombre: productoNombre,
          nuevoEstado: newStatus,
        );
      }
    } catch (e) {
      debugPrint('[FirestoreService] updateOrderStatus error: $e');
      rethrow;
    }
  }

  /// Stream del historial de estados de un pedido
  Stream<QuerySnapshot> getOrderHistory(String orderId) {
    return _db
        .collection('pedidos')
        .doc(orderId)
        .collection('historial')
        .orderBy('timestamp', descending: false)
        .snapshots();
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

  /// Enviar un mensaje e incrementar el contador de no leídos del destinatario
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    required String recipientId,
    String tipo = 'texto', // 'texto' | 'imagen' | 'audio'
    String? imagenUrl,
    int? duracion,
    Map<String, dynamic>? replyTo,
  }) async {
    try {
      final batch = _db.batch();

      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': senderId,
        'senderName': senderName,
        'texto': text,
        'tipo': tipo,
        if (imagenUrl != null) 'imagenUrl': imagenUrl,
        if (duracion != null) 'duracion': duracion,
        if (replyTo != null) 'replyTo': replyTo,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final convRef = _db.collection('conversations').doc(conversationId);
      batch.update(convRef, {
        'ultimoMensaje': tipo == 'imagen'
            ? 'Imagen'
            : tipo == 'audio'
                ? 'Audio'
                : text,
        'ultimoTimestamp': FieldValue.serverTimestamp(),
        'ultimoSenderId': senderId,
        'unreadCounts.$recipientId': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] sendMessage error: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'texto': 'Mensaje eliminado', 'eliminado': true});
  }

  /// Marca una conversación como leída y guarda el timestamp de última lectura
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'unreadCounts.$userId': 0,
        'lastRead.$userId': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] markConversationRead error: $e');
    }
  }

  /// Indica que el usuario está escribiendo (o dejó de escribir)
  Future<void> setTyping(
      String conversationId, String userId, bool isTyping) async {
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'typing.$userId':
            isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// Stream con el total de mensajes no leídos del usuario
  Stream<int> getTotalUnreadStream(String userId) {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final counts = data['unreadCounts'] as Map<String, dynamic>?;
        total += (counts?[userId] as num?)?.toInt() ?? 0;
      }
      return total;
    });
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

  // ─────────────────────────── FAVORITOS ───────────────────────────

  /// Stream que emite la lista de IDs de productos favoritos del usuario
  Stream<List<String>> getFavoritesStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['favoritos'] ?? []);
    });
  }

  /// Agrega o quita un producto de favoritos
  Future<void> toggleFavorite(
      String userId, String productId, bool isCurrentlyFavorite) async {
    try {
      await _db.collection('users').doc(userId).update({
        'favoritos': isCurrentlyFavorite
            ? FieldValue.arrayRemove([productId])
            : FieldValue.arrayUnion([productId]),
      });
    } catch (e) {
      debugPrint('[FirestoreService] toggleFavorite error: $e');
      rethrow;
    }
  }

  /// Obtiene los productos favoritos del usuario usando whereIn (1 query por cada 30 ids)
  Future<List<Map<String, dynamic>>> getFavoriteProducts(
      List<String> productIds) async {
    if (productIds.isEmpty) return [];
    try {
      const chunkSize = 30;
      final chunks = <List<String>>[];
      for (var i = 0; i < productIds.length; i += chunkSize) {
        final end = (i + chunkSize < productIds.length)
            ? i + chunkSize
            : productIds.length;
        chunks.add(productIds.sublist(i, end));
      }
      final snapshots = await Future.wait(
        chunks.map((chunk) => _db
            .collection('productos')
            .where(FieldPath.documentId, whereIn: chunk)
            .get()),
      );
      return snapshots
          .expand((snap) => snap.docs)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getFavoriteProducts error: $e');
      return [];
    }
  }

  // ─────────────────────────── CALIFICACIONES ───────────────────────────

  /// Verifica si un pedido ya fue calificado
  Future<bool> hasRated(String productId, String orderId) async {
    try {
      final query = await _db
          .collection('productos')
          .doc(productId)
          .collection('calificaciones')
          .where('pedidoId', isEqualTo: orderId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[FirestoreService] hasRated error: $e');
      return false;
    }
  }

  /// Agrega una calificación al producto y marca el pedido como calificado
  Future<void> addRating({
    required String productId,
    required String userId,
    required String userName,
    required int estrellas,
    required String comentario,
    required String orderId,
  }) async {
    try {
      final batch = _db.batch();

      final ratingRef = _db
          .collection('productos')
          .doc(productId)
          .collection('calificaciones')
          .doc();

      batch.set(ratingRef, {
        'userId': userId,
        'userName': userName,
        'estrellas': estrellas,
        'comentario': comentario,
        'pedidoId': orderId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      batch.update(_db.collection('pedidos').doc(orderId), {
        'calificado': true,
      });

      await batch.commit();
      await _recalculateProductRating(productId);
    } catch (e) {
      debugPrint('[FirestoreService] addRating error: $e');
      rethrow;
    }
  }

  Future<void> _recalculateProductRating(String productId) async {
    try {
      final snapshot = await _db
          .collection('productos')
          .doc(productId)
          .collection('calificaciones')
          .get();
      if (snapshot.docs.isEmpty) return;
      double sum = 0;
      for (final doc in snapshot.docs) {
        sum += (doc.data()['estrellas'] as num?)?.toDouble() ?? 0;
      }
      await _db.collection('productos').doc(productId).update({
        'ratingAvg': sum / snapshot.docs.length,
        'ratingCount': snapshot.docs.length,
      });
    } catch (e) {
      debugPrint('[FirestoreService] _recalculateProductRating error: $e');
    }
  }

  /// Stream de calificaciones de un producto (más recientes primero)
  Stream<QuerySnapshot> getRatings(String productId) {
    return _db
        .collection('productos')
        .doc(productId)
        .collection('calificaciones')
        .orderBy('fechaCreacion', descending: true)
        .limit(20)
        .snapshots();
  }

  // ─────────────────────────── ESTADÍSTICAS VENDEDOR ───────────────────────────

  /// Estadísticas reales del comerciante
  Future<Map<String, dynamic>> getSellerStats(String vendedorId) async {
    try {
      final results = await Future.wait([
        _db
            .collection('pedidos')
            .where('vendedorId', isEqualTo: vendedorId)
            .limit(500)
            .get(),
        _db
            .collection('productos')
            .where('vendedorId', isEqualTo: vendedorId)
            .where('activo', isEqualTo: true)
            .limit(200)
            .get(),
      ]);

      final pedidosSnap = results[0];
      final productosSnap = results[1];

      int pedidosEntregados = 0;
      double totalVentas = 0;

      for (final doc in pedidosSnap.docs) {
        final data = doc.data();
        if (data['estado'] == 'entregado') {
          pedidosEntregados++;
          totalVentas += (data['precioTotal'] as num?)?.toDouble() ?? 0;
        }
      }

      double ratingSum = 0;
      int ratingCount = 0;
      for (final doc in productosSnap.docs) {
        final data = doc.data();
        final avg = (data['ratingAvg'] as num?)?.toDouble() ?? 0;
        final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
        if (count > 0) {
          ratingSum += avg * count;
          ratingCount += count;
        }
      }

      return {
        'totalPedidos': pedidosSnap.docs.length,
        'pedidosEntregados': pedidosEntregados,
        'totalVentas': totalVentas,
        'productosActivos': productosSnap.docs.length,
        'ratingAvg': ratingCount > 0 ? ratingSum / ratingCount : 0.0,
        'ratingCount': ratingCount,
      };
    } catch (e) {
      debugPrint('[FirestoreService] getSellerStats error: $e');
      return {
        'totalPedidos': 0,
        'pedidosEntregados': 0,
        'totalVentas': 0.0,
        'productosActivos': 0,
        'ratingAvg': 0.0,
        'ratingCount': 0,
      };
    }
  }

  /// Estadísticas detalladas para el dashboard del comerciante
  Future<Map<String, dynamic>> getSellerDetailedStats(String vendedorId) async {
    try {
      final results = await Future.wait([
        _db
            .collection('pedidos')
            .where('vendedorId', isEqualTo: vendedorId)
            .limit(500)
            .get(),
        _db
            .collection('productos')
            .where('vendedorId', isEqualTo: vendedorId)
            .where('activo', isEqualTo: true)
            .limit(200)
            .get(),
      ]);

      final pedidosSnap = results[0];
      final productosSnap = results[1];

      // Contadores por estado
      int pendientes = 0, confirmados = 0, entregados = 0, cancelados = 0;
      double totalVentas = 0;
      double last30DaysVentas = 0;
      final productCount = <String, int>{};
      final productNames = <String, String>{};
      final categoriaVentas = <String, double>{};
      final ventasPorDia = <String, double>{};
      final pedidosPorDia = <String, int>{};
      final now = DateTime.now();
      final cutoff30 = now.subtract(const Duration(days: 30));
      final cutoff7 = now.subtract(const Duration(days: 7));

      // Inicializar últimos 7 días
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.day}/${d.month}';
        ventasPorDia[key] = 0;
        pedidosPorDia[key] = 0;
      }

      for (final doc in pedidosSnap.docs) {
        final d = doc.data();
        final estado = d['estado'] as String? ?? '';
        switch (estado) {
          case 'pendiente':
            pendientes++;
            break;
          case 'confirmado':
            confirmados++;
            break;
          case 'entregado':
            entregados++;
            final precio = (d['precioTotal'] as num?)?.toDouble() ?? 0;
            totalVentas += precio;
            final ts = d['fechaCreacion'];
            if (ts is Timestamp) {
              final fecha = ts.toDate();
              if (fecha.isAfter(cutoff30)) last30DaysVentas += precio;
              // Ventas por día (últimos 7 días)
              if (fecha.isAfter(cutoff7)) {
                final key = '${fecha.day}/${fecha.month}';
                ventasPorDia[key] = (ventasPorDia[key] ?? 0) + precio;
                pedidosPorDia[key] = (pedidosPorDia[key] ?? 0) + 1;
              }
              // Ventas por categoría
              final cat = d['categoria'] as String? ?? d['productoCategoria'] as String? ?? '';
              if (cat.isNotEmpty) {
                categoriaVentas[cat] = (categoriaVentas[cat] ?? 0) + precio;
              }
            }
            break;
          case 'cancelado':
            cancelados++;
            break;
        }
        // Contar por producto
        final pid = d['productoId'] as String? ?? '';
        final pnombre = d['productoNombre'] as String? ?? 'Producto';
        if (pid.isNotEmpty && estado != 'cancelado') {
          productCount[pid] = (productCount[pid] ?? 0) + 1;
          productNames[pid] = pnombre;
        }
      }

      // Rating promedio
      double ratingSum = 0;
      int ratingCount = 0;
      for (final doc in productosSnap.docs) {
        final d = doc.data();
        final avg = (d['ratingAvg'] as num?)?.toDouble() ?? 0;
        final cnt = (d['ratingCount'] as num?)?.toInt() ?? 0;
        if (cnt > 0) {
          ratingSum += avg * cnt;
          ratingCount += cnt;
        }
      }

      // Top 5 productos
      final sortedProducts = productCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topProductos = sortedProducts
          .take(5)
          .map((e) => {
                'productId': e.key,
                'nombre': productNames[e.key] ?? 'Producto',
                'pedidos': e.value,
              })
          .toList();

      return {
        'totalPedidos': pedidosSnap.docs.length,
        'pendientes': pendientes,
        'confirmados': confirmados,
        'entregados': entregados,
        'cancelados': cancelados,
        'totalVentas': totalVentas,
        'last30DaysVentas': last30DaysVentas,
        'productosActivos': productosSnap.docs.length,
        'ratingAvg': ratingCount > 0 ? ratingSum / ratingCount : 0.0,
        'ratingCount': ratingCount,
        'topProductos': topProductos,
        'ventasPorDia': ventasPorDia,
        'pedidosPorDia': pedidosPorDia,
        'categoriaVentas': categoriaVentas,
      };
    } catch (e) {
      debugPrint('[FirestoreService] getSellerDetailedStats error: $e');
      return {
        'totalPedidos': 0,
        'pendientes': 0,
        'confirmados': 0,
        'entregados': 0,
        'cancelados': 0,
        'totalVentas': 0.0,
        'last30DaysVentas': 0.0,
        'productosActivos': 0,
        'ratingAvg': 0.0,
        'ratingCount': 0,
        'topProductos': <Map<String, dynamic>>[],
        'ventasPorDia': <String, double>{},
        'pedidosPorDia': <String, int>{},
        'categoriaVentas': <String, double>{},
      };
    }
  }

  // ─────────────────────────── IA / ESTADÍSTICAS ───────────────────────────

  /// Cuenta productos activos agrupados por categoría.
  /// Usa un límite de 500 documentos para evitar descargas masivas.
  Future<Map<String, int>> getProductCountByCategory() async {
    try {
      final snapshot = await _db
          .collection('productos')
          .where('activo', isEqualTo: true)
          .limit(500)
          .get();
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['categoria'] as String?;
        if (category != null) {
          counts[category] = (counts[category] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('[FirestoreService] getProductCountByCategory error: $e');
      return {};
    }
  }

  /// Estadísticas de precios por categoría.
  /// Limita a 200 documentos por categoría.
  Future<Map<String, dynamic>> getPriceStats(String category) async {
    try {
      final snapshot = await _db
          .collection('productos')
          .where('categoria', isEqualTo: category)
          .where('activo', isEqualTo: true)
          .limit(200)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
      }

      double sum = 0;
      double minPrice = double.maxFinite;
      double maxPrice = 0;

      for (final doc in snapshot.docs) {
        final price = (doc.data()['precio'] as num?) ?? 0;
        final p = price.toDouble();
        sum += p;
        if (p < minPrice) minPrice = p;
        if (p > maxPrice) maxPrice = p;
      }

      return {
        'count': snapshot.docs.length,
        'avg': sum / snapshot.docs.length,
        'min': minPrice == double.maxFinite ? 0.0 : minPrice,
        'max': maxPrice,
      };
    } catch (e) {
      debugPrint('[FirestoreService] getPriceStats error: $e');
      return {'count': 0, 'avg': 0.0, 'min': 0.0, 'max': 0.0};
    }
  }

  // ─────────────────────────── SEGUIR VENDEDORES ───────────────────────────

  Future<void> followSeller(String uid, String sellerId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('siguiendo')
          .doc(sellerId)
          .set({'sellerId': sellerId, 'fechaSeguido': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('[FirestoreService] followSeller error: $e');
    }
  }

  Future<void> unfollowSeller(String uid, String sellerId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('siguiendo')
          .doc(sellerId)
          .delete();
    } catch (e) {
      debugPrint('[FirestoreService] unfollowSeller error: $e');
    }
  }

  Stream<bool> isFollowingStream(String uid, String sellerId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('siguiendo')
        .doc(sellerId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  // ─────────────────────────── PREGUNTAS AL VENDEDOR ───────────────────────────

  Stream<QuerySnapshot> getQuestions(String productId) {
    return _db
        .collection('productos')
        .doc(productId)
        .collection('preguntas')
        .orderBy('fechaPregunta', descending: false)
        .snapshots();
  }

  Future<void> addQuestion({
    required String productId,
    required String compradorId,
    required String compradorNombre,
    required String texto,
  }) async {
    try {
      await _db
          .collection('productos')
          .doc(productId)
          .collection('preguntas')
          .add({
        'compradorId': compradorId,
        'compradorNombre': compradorNombre,
        'texto': texto,
        'respuesta': null,
        'fechaPregunta': FieldValue.serverTimestamp(),
        'fechaRespuesta': null,
      });
    } catch (e) {
      debugPrint('[FirestoreService] addQuestion error: $e');
      rethrow;
    }
  }

  Future<void> answerQuestion({
    required String productId,
    required String questionId,
    required String respuesta,
  }) async {
    try {
      await _db
          .collection('productos')
          .doc(productId)
          .collection('preguntas')
          .doc(questionId)
          .update({
        'respuesta': respuesta,
        'fechaRespuesta': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] answerQuestion error: $e');
      rethrow;
    }
  }

  // ─────────────────────────── RECOMENDACIONES ───────────────────────────

  /// Obtiene categorías más compradas por el usuario y recomienda productos similares
  Future<List<Map<String, dynamic>>> getRecommendations(String userId, {int limit = 10}) async {
    try {
      // 1. Obtener las categorías que más compra el usuario
      final pedidos = await _db
          .collection('pedidos')
          .where('compradorId', isEqualTo: userId)
          .where('estado', isEqualTo: 'entregado')
          .limit(50)
          .get();

      final catCount = <String, int>{};
      final comprados = <String>{};
      for (final doc in pedidos.docs) {
        final d = doc.data();
        final cat = d['productoCategoria'] as String? ?? '';
        final pid = d['productoId'] as String? ?? '';
        if (cat.isNotEmpty) catCount[cat] = (catCount[cat] ?? 0) + 1;
        if (pid.isNotEmpty) comprados.add(pid);
      }

      if (catCount.isEmpty) {
        // Sin historial, devolver productos populares
        final pop = await _db
            .collection('productos')
            .where('activo', isEqualTo: true)
            .orderBy('fechaCreacion', descending: true)
            .limit(limit)
            .get();
        return pop.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      }

      // 2. Ordenar categorías por frecuencia
      final sortedCats = catCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCats = sortedCats.take(3).map((e) => e.key).toList();

      // 3. Buscar productos de esas categorías que NO haya comprado
      final snap = await _db
          .collection('productos')
          .where('activo', isEqualTo: true)
          .where('categoria', whereIn: topCats)
          .limit(30)
          .get();

      final results = snap.docs
          .where((d) => !comprados.contains(d.id))
          .map((d) => {'id': d.id, ...d.data()})
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      debugPrint('[FirestoreService] getRecommendations error: $e');
      return [];
    }
  }

  /// Sugerencias de búsqueda basadas en nombres de productos
  Future<List<String>> getSearchSuggestions(String query, {int limit = 8}) async {
    if (query.length < 2) return [];
    try {
      final queryLower = query.toLowerCase();
      final snap = await _db
          .collection('productos')
          .where('activo', isEqualTo: true)
          .limit(200)
          .get();

      final suggestions = <String>{};
      for (final doc in snap.docs) {
        final nombre = (doc.data()['nombre'] as String? ?? '').toLowerCase();
        final cat = (doc.data()['categoria'] as String? ?? '').toLowerCase();
        if (nombre.contains(queryLower)) {
          suggestions.add(doc.data()['nombre'] as String);
        }
        if (cat.contains(queryLower)) {
          suggestions.add(doc.data()['categoria'] as String);
        }
      }
      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('[FirestoreService] getSearchSuggestions error: $e');
      return [];
    }
  }

  // ─────────────────────────── DEVOLUCIONES ───────────────────────────

  /// Solicitar devolución de un pedido entregado
  Future<void> requestReturn({
    required String orderId,
    required String compradorId,
    required String motivo,
    String? detalle,
  }) async {
    try {
      final batch = _db.batch();
      final orderRef = _db.collection('pedidos').doc(orderId);

      batch.update(orderRef, {
        'estado': 'devolucion_solicitada',
        'devolucion': {
          'motivo': motivo,
          'detalle': detalle ?? '',
          'fecha': FieldValue.serverTimestamp(),
          'estado': 'pendiente',
        },
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      batch.set(
        orderRef.collection('historial').doc(),
        {
          'estado': 'devolucion_solicitada',
          'motivo': motivo,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] requestReturn error: $e');
      rethrow;
    }
  }

  /// Responder a solicitud de devolución (vendedor acepta o rechaza)
  Future<void> respondReturn({
    required String orderId,
    required bool accepted,
    String? respuesta,
  }) async {
    try {
      final newStatus = accepted ? 'devolucion_aceptada' : 'devolucion_rechazada';
      final batch = _db.batch();
      final orderRef = _db.collection('pedidos').doc(orderId);

      batch.update(orderRef, {
        'estado': newStatus,
        'devolucion.estado': accepted ? 'aceptada' : 'rechazada',
        'devolucion.respuesta': respuesta ?? '',
        'devolucion.fechaRespuesta': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      batch.set(
        orderRef.collection('historial').doc(),
        {
          'estado': newStatus,
          'respuesta': respuesta ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      // Si se acepta, restaurar stock
      if (accepted) {
        final orderSnap = await orderRef.get();
        final data = orderSnap.data();
        if (data != null) {
          final productoId = data['productoId'] as String? ?? '';
          final cantidad = (data['cantidad'] as num?)?.toInt() ?? 0;
          if (productoId.isNotEmpty && cantidad > 0) {
            await _db.collection('productos').doc(productoId).update({
              'stock': FieldValue.increment(cantidad),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[FirestoreService] respondReturn error: $e');
      rethrow;
    }
  }

  // ─────────────────────────── INVENTARIO ───────────────────────────

  /// Ajustar stock manualmente y registrar el movimiento
  Future<void> adjustStock({
    required String productId,
    required int delta,
    required String motivo,
    required String userId,
  }) async {
    try {
      final prodRef = _db.collection('productos').doc(productId);
      await _db.runTransaction((txn) async {
        final snap = await txn.get(prodRef);
        if (!snap.exists) throw Exception('Producto no existe');
        final stockActual = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
        final nuevoStock = (stockActual + delta).clamp(0, 999999);
        txn.update(prodRef, {
          'stock': nuevoStock,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
        // Registrar movimiento
        txn.set(
          prodRef.collection('movimientos').doc(),
          {
            'tipo': delta > 0 ? 'entrada' : 'salida',
            'cantidad': delta.abs(),
            'stockAnterior': stockActual,
            'stockNuevo': nuevoStock,
            'motivo': motivo,
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      });
    } catch (e) {
      debugPrint('[FirestoreService] adjustStock error: $e');
      rethrow;
    }
  }

  /// Stream de movimientos de inventario de un producto
  Stream<QuerySnapshot> getStockMovements(String productId) {
    return _db
        .collection('productos')
        .doc(productId)
        .collection('movimientos')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Resumen de inventario del vendedor (contadores por nivel de stock)
  Future<Map<String, int>> getInventorySummary(String vendedorId) async {
    try {
      final snap = await _db
          .collection('productos')
          .where('vendedorId', isEqualTo: vendedorId)
          .limit(500)
          .get();
      int total = 0, ok = 0, bajo = 0, critico = 0, agotado = 0, inactivo = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final activo = d['activo'] as bool? ?? true;
        if (!activo) { inactivo++; continue; }
        total++;
        final stock = (d['stock'] as num?)?.toInt() ?? 0;
        if (stock == 0) agotado++;
        else if (stock <= 3) critico++;
        else if (stock <= 10) bajo++;
        else ok++;
      }
      return {
        'total': total,
        'ok': ok,
        'bajo': bajo,
        'critico': critico,
        'agotado': agotado,
        'inactivo': inactivo,
      };
    } catch (e) {
      debugPrint('[FirestoreService] getInventorySummary error: $e');
      return {'total': 0, 'ok': 0, 'bajo': 0, 'critico': 0, 'agotado': 0, 'inactivo': 0};
    }
  }

  // ─────────────────────────── REPORTES ───────────────────────────

  Future<void> reportContent({
    required String reporterId,
    required String tipo, // 'producto' | 'usuario' | 'publicacion'
    required String targetId,
    required String motivo,
    String? detalle,
  }) async {
    await _db.collection('reportes').add({
      'reporterId': reporterId,
      'tipo': tipo,
      'targetId': targetId,
      'motivo': motivo,
      if (detalle != null && detalle.isNotEmpty) 'detalle': detalle,
      'estado': 'pendiente',
      'fecha': FieldValue.serverTimestamp(),
    });
  }
}
