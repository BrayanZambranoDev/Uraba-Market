import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// Modelo de datos para un pedido.
class OrderModel {
  final String id;
  final String compradorId;
  final String compradorNombre;
  final String vendedorId;
  final String vendedorNombre;
  final String productoId;
  final String productoNombre;
  final String productoCategoria;
  final int cantidad;
  final double precioUnitario;
  final double precioTotal;
  final String unidad;
  final String estado;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const OrderModel({
    required this.id,
    required this.compradorId,
    required this.compradorNombre,
    required this.vendedorId,
    required this.vendedorNombre,
    required this.productoId,
    required this.productoNombre,
    required this.productoCategoria,
    required this.cantidad,
    required this.precioUnitario,
    required this.precioTotal,
    required this.unidad,
    required this.estado,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      compradorId: data['compradorId'] as String? ?? '',
      compradorNombre: data['compradorNombre'] as String? ?? 'Comprador',
      vendedorId: data['vendedorId'] as String? ?? '',
      vendedorNombre: data['vendedorNombre'] as String? ?? 'Comerciante',
      productoId: data['productoId'] as String? ?? '',
      productoNombre: data['productoNombre'] as String? ?? 'Producto',
      productoCategoria: data['productoCategoria'] as String? ?? 'Otros',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 1,
      precioUnitario: (data['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      precioTotal: (data['precioTotal'] as num?)?.toDouble() ?? 0.0,
      unidad: data['unidad'] as String? ?? 'c/u',
      estado: data['estado'] as String? ?? AppConstants.estadoPendiente,
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPendiente => estado == AppConstants.estadoPendiente;
  bool get isConfirmado => estado == AppConstants.estadoConfirmado;
  bool get isEntregado => estado == AppConstants.estadoEntregado;
  bool get isCancelado => estado == AppConstants.estadoCancelado;

  String get precioTotalFormateado => '\$${precioTotal.toStringAsFixed(0)}';
}
