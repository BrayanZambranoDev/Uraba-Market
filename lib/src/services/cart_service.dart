import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String nombre;
  final double precio;
  final String unidad;
  final String vendedorId;
  final String vendedor;
  final String categoria;
  final String? imagenUrl;
  int cantidad;

  CartItem({
    required this.productId,
    required this.nombre,
    required this.precio,
    required this.unidad,
    required this.vendedorId,
    required this.vendedor,
    this.categoria = '',
    this.imagenUrl,
    required this.cantidad,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> d) => CartItem(
        productId: d['productId'] as String,
        nombre: d['nombre'] as String,
        precio: (d['precio'] as num).toDouble(),
        unidad: d['unidad'] as String? ?? 'c/u',
        vendedorId: d['vendedorId'] as String? ?? '',
        vendedor: d['vendedor'] as String? ?? 'Comerciante',
        categoria: d['categoria'] as String? ?? '',
        imagenUrl: d['imagenUrl'] as String?,
        cantidad: (d['cantidad'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'nombre': nombre,
        'precio': precio,
        'unidad': unidad,
        'vendedorId': vendedorId,
        'vendedor': vendedor,
        'categoria': categoria,
        'imagenUrl': imagenUrl,
        'cantidad': cantidad,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  double get subtotal => precio * cantidad;
}

class CartService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _cartRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('carts').doc(uid).collection('items');
  }

  // ── Stream de ítems del carrito ──────────────────────────────────
  Stream<List<CartItem>> get cartStream {
    final ref = _cartRef;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map((snap) =>
        snap.docs.map((d) => CartItem.fromFirestore(d.data())).toList());
  }

  // ── Total de ítems (para el badge) ──────────────────────────────
  Stream<int> get itemCountStream {
    final ref = _cartRef;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map((snap) =>
        snap.docs.fold<int>(0, (acc, d) => acc + ((d['cantidad'] as num?)?.toInt() ?? 1)));
  }

  // ── Agregar o aumentar cantidad (con validación de stock) ────────
  /// Lanza [Exception] si el stock es insuficiente.
  Future<void> addItem({
    required String productId,
    required String nombre,
    required double precio,
    required String unidad,
    required String vendedorId,
    required String vendedor,
    String categoria = '',
    String? imagenUrl,
    int cantidad = 1,
  }) async {
    final ref = _cartRef;
    if (ref == null) return;

    // Validar stock disponible en Firestore
    final productoSnap =
        await _db.collection('productos').doc(productId).get();
    final stockDisponible =
        (productoSnap.data()?['stock'] as num?)?.toInt() ?? 0;

    final cartDoc = ref.doc(productId);
    final cartSnap = await cartDoc.get();
    final enCarrito =
        cartSnap.exists ? (cartSnap['cantidad'] as num).toInt() : 0;

    if (enCarrito + cantidad > stockDisponible) {
      final disponible = stockDisponible - enCarrito;
      if (disponible <= 0) {
        throw Exception('Este producto ya no tiene stock disponible.');
      }
      throw Exception(
          'Solo quedan $disponible unidades disponibles de este producto.');
    }

    try {
      if (cartSnap.exists) {
        await cartDoc.update({
          'cantidad': enCarrito + cantidad,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartDoc.set(CartItem(
          productId: productId,
          nombre: nombre,
          precio: precio,
          unidad: unidad,
          vendedorId: vendedorId,
          vendedor: vendedor,
          categoria: categoria,
          imagenUrl: imagenUrl,
          cantidad: cantidad,
        ).toMap());
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('CartService.addItem error: $e');
    }
  }

  // ── Cambiar cantidad (0 = eliminar) ─────────────────────────────
  /// Lanza [Exception] si la nueva cantidad excede el stock disponible.
  Future<void> updateQuantity(String productId, int cantidad) async {
    final ref = _cartRef;
    if (ref == null) return;
    try {
      if (cantidad <= 0) {
        await ref.doc(productId).delete();
      } else {
        // Validar stock disponible
        final productoSnap =
            await _db.collection('productos').doc(productId).get();
        final stockDisponible =
            (productoSnap.data()?['stock'] as num?)?.toInt() ?? 0;
        if (cantidad > stockDisponible) {
          throw Exception(
              'Solo hay $stockDisponible unidades disponibles.');
        }
        await ref.doc(productId).update(
            {'cantidad': cantidad, 'updatedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('CartService.updateQuantity error: $e');
    }
  }

  // ── Eliminar ítem ────────────────────────────────────────────────
  Future<void> removeItem(String productId) async {
    final ref = _cartRef;
    if (ref == null) return;
    try {
      await ref.doc(productId).delete();
    } catch (e) {
      debugPrint('CartService.removeItem error: $e');
    }
  }

  // ── Vaciar carrito ───────────────────────────────────────────────
  Future<void> clearCart() async {
    final ref = _cartRef;
    if (ref == null) return;
    try {
      final snap = await ref.get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('CartService.clearCart error: $e');
    }
  }
}
