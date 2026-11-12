import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un producto del marketplace.
/// Elimina el uso de Map<String, dynamic> crudo en las pantallas.
class ProductModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String unidad;
  final String categoria;
  final int stock;
  final String vendedor;
  final String vendedorId;
  final bool activo;
  final DateTime? fechaCreacion;

  const ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.unidad,
    required this.categoria,
    required this.stock,
    required this.vendedor,
    required this.vendedorId,
    required this.activo,
    this.fechaCreacion,
  });

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? 'Producto',
      descripcion: data['descripcion'] as String? ?? '',
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
      unidad: data['unidad'] as String? ?? 'c/u',
      categoria: data['categoria'] as String? ?? 'Otros',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      vendedor: data['vendedor'] as String? ?? 'Comerciante',
      vendedorId: data['vendedorId'] as String? ?? '',
      activo: data['activo'] as bool? ?? false,
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'unidad': unidad,
        'categoria': categoria,
        'stock': stock,
        'vendedor': vendedor,
        'vendedorId': vendedorId,
        'activo': activo,
      };

  String get precioFormateado =>
      precio > 0 ? '\$${precio.toStringAsFixed(0)}' : 'Consultar';
}
