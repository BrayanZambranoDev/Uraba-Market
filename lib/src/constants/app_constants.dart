/// Constantes globales de la aplicación.
/// Centraliza valores que antes estaban duplicados en múltiples pantallas.
class AppConstants {
  AppConstants._();

  // ─────────────────────────── CATEGORÍAS ───────────────────────────
  /// Lista de categorías de productos. Usar en:
  /// home_screen, search_screen, publicar_producto_screen, ai_assistant_screen
  static const List<String> categorias = [
    'Frutas',
    'Verduras',
    'Artesanías',
    'Gastronomía',
    'Otros',
  ];

  // ─────────────────────────── UNIDADES ───────────────────────────
  /// Unidades de medida para productos.
  static const List<String> unidades = [
    'kg',
    'libra',
    'unidad',
    'docena',
    'bulto',
    'canasta',
    'litro',
  ];

  // ─────────────────────────── ESTADOS DE PEDIDO ───────────────────────────
  static const String estadoPendiente = 'pendiente';
  static const String estadoConfirmado = 'confirmado';
  static const String estadoEnCamino = 'en_camino';
  static const String estadoEntregado = 'entregado';
  static const String estadoCancelado = 'cancelado';

  static const List<String> estadosPedido = [
    estadoPendiente,
    estadoConfirmado,
    estadoEnCamino,
    estadoEntregado,
    estadoCancelado,
  ];

  // ─────────────────────────── MUNICIPIOS ───────────────────────────
  static const List<String> municipios = [
    'Apartadó',
    'Carepa',
    'Chigorodó',
    'Mutatá',
    'Turbo',
    'Arboletes',
    'Necoclí',
    'San Juan de Urabá',
    'San Pedro de Urabá',
    'Vigía del Fuerte',
    'Murindó',
  ];

  // ─────────────────────────── ROLES ───────────────────────────
  static const String rolComprador = 'Comprador';
  static const String rolComerciante = 'Comerciante';
  static const String rolProductor = 'Productor';

  // ─────────────────────────── LÍMITES ───────────────────────────
  static const int limiteProductosHome = 6;
  static const int limiteProductosStats = 500;
  static const int limiteProductosCategoria = 200;
  static const int longitudMaximaMensaje = 500;
  static const int longitudMinimaPassword = 6;
  static const int longitudMinimaNombre = 3;
}
