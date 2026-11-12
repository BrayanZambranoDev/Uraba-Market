import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'services/cart_service.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'package:iconsax/iconsax.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final bool isVendedor;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.isVendedor,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isActing = false;
  bool _isRating = false;
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _data = widget.orderData;
    // Escuchar cambios en tiempo real
    _sub = FirebaseFirestore.instance
        .collection('pedidos')
        .doc(widget.orderId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        setState(() => _data = snap.data() as Map<String, dynamic>);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Calificar compra ─────────────────────────────────────────────
  Future<void> _showRatingDialog() async {
    int stars = 5;
    final commentCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: AppTheme.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Calificar compra',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('¿Cómo calificarías este producto?',
                  style: AppTheme.bodyMuted),
              const SizedBox(height: 20),
              // Estrellas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < stars;
                  return GestureDetector(
                    onTap: () => setModalState(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled
                            ? Iconsax.star5
                            : Iconsax.star,
                        color:
                            filled ? const Color(0xFFF59E0B) : AppTheme.border,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  stars == 1
                      ? 'Muy malo'
                      : stars == 2
                          ? 'Malo'
                          : stars == 3
                              ? 'Regular'
                              : stars == 4
                                  ? 'Bueno'
                                  : 'Excelente',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.surface),
                ),
              ),
              const SizedBox(height: 20),
              // Comentario opcional
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: AppTheme.body,
                decoration: AppTheme.inputDecoration(
                  hint: 'Comenta tu experiencia (opcional)',
                  icon: Iconsax.star,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _submitRating(stars, commentCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusFull),
                    elevation: 0,
                  ),
                  child:
                      Text('Enviar calificación', style: AppTheme.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(int stars, String comment) async {
    if (_currentUser == null) return;
    final productoId = _data['productoId'] as String?;
    if (productoId == null || productoId.isEmpty) return;

    setState(() => _isRating = true);
    try {
      final userData = await _firestoreService.getUserData(_currentUser!.uid);
      final userName =
          userData?['nombre'] ?? _currentUser!.displayName ?? 'Usuario';

      await _firestoreService.addRating(
        productId: productoId,
        userId: _currentUser!.uid,
        userName: userName,
        estrellas: stars,
        comentario: comment,
        orderId: widget.orderId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('¡Gracias por tu calificación!',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al enviar calificación',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } finally {
      if (mounted) setState(() => _isRating = false);
    }
  }

  // ── Confirmar o entregar ─────────────────────────────────────────
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await _firestoreService.updateOrderStatus(
        widget.orderId,
        newStatus,
        compradorId: _data['compradorId'] as String?,
        productoNombre: _data['productoNombre'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            newStatus == 'confirmado'
                ? 'Pedido confirmado'
                : newStatus == 'en_camino'
                    ? 'Pedido marcado en camino'
                    : 'Pedido marcado como entregado',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al actualizar el pedido',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  // ── Cancelar con motivo y confirmación ──────────────────────────
  Future<void> _cancelOrder() async {
    const motivos = [
      'Cambié de opinión',
      'El precio no me conviene',
      'Encontré una mejor opción',
      'El vendedor no responde',
      'Error en el pedido',
      'Otro',
    ];
    String? motivoSeleccionado;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
          title: Text('¿Cancelar pedido?',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Motivo de cancelación (opcional):',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: motivos.map((m) {
                  final sel = motivoSeleccionado == m;
                  return GestureDetector(
                    onTap: () =>
                        setStateDlg(() => motivoSeleccionado = sel ? null : m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.error.withValues(alpha: 0.12)
                            : AppTheme.bg,
                        borderRadius: AppTheme.radiusFull,
                        border: Border.all(
                            color: sel
                                ? AppTheme.error.withValues(alpha: 0.5)
                                : AppTheme.border),
                      ),
                      child: Text(m,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppTheme.error
                                  : AppTheme.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                  'El stock del producto será restaurado automáticamente.',
                  style: AppTheme.caption),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No, volver',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape:
                    RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
                elevation: 0,
              ),
              child: Text('Sí, cancelar',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await _firestoreService.cancelOrder(widget.orderId,
          motivo: motivoSeleccionado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pedido cancelado',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Error al cancelar el pedido';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(msg, style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _volverAPedir() async {
    setState(() => _isActing = true);
    try {
      final cartService = CartService();
      await cartService.addItem(
        productId: _data['productoId'] as String? ?? '',
        nombre: _data['productoNombre'] as String? ?? 'Producto',
        precio: ((_data['precioUnitario'] ?? _data['precioTotal'] ?? 0) as num)
            .toDouble(),
        unidad: _data['unidad'] as String? ?? 'c/u',
        vendedorId: _data['vendedorId'] as String? ?? '',
        vendedor: _data['vendedorNombre'] as String? ?? 'Vendedor',
        imagenUrl: _data['imagenUrl'] as String?,
        cantidad: (_data['cantidad'] as num?)?.toInt() ?? 1,
      );
      if (!mounted) return;
      Navigator.push(context, AppTheme.pageRoute(const CartScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.plusJakartaSans(color: AppTheme.surface)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _data['estado'] ?? 'pendiente';
    final producto = _data['productoNombre'] ?? 'Producto';
    final cantidad = _data['cantidad'] ?? 0;
    final unidad = _data['unidad'] ?? 'c/u';
    final precioUnit = _data['precioUnitario'] ?? 0;
    final total = _data['precioTotal'] ?? 0;
    final comprador = _data['compradorNombre'] ?? 'Comprador';
    final vendedorName = _data['vendedorNombre'] ?? 'Vendedor';
    final metodoPago = _data['metodoPago'] as String?;
    final dirMap = _data['direccionEntrega'] as Map<String, dynamic>?;
    final fecha = _data['fechaCreacion'] as Timestamp?;
    final fechaStr = fecha != null
        ? '${fecha.toDate().day}/${fecha.toDate().month}/${fecha.toDate().year}'
        : '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppTheme.bg,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.arrow_left,
                          color: AppTheme.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Detalle del pedido',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primary)),
                ],
              ),
            ),

            // ── Contenido ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  children: [
                    _statusCard(status),
                    const SizedBox(height: 16),
                    _infoSection('Producto', [
                      _infoRow(
                          Iconsax.box, 'Producto', producto),
                      _infoRow(Iconsax.category, 'Categoría',
                          _data['productoCategoria'] ?? 'N/A'),
                      _infoRow(Iconsax.element_3, 'Cantidad',
                          '$cantidad $unidad'),
                      _infoRow(Iconsax.dollar_circle, 'Precio unitario',
                          '\$$precioUnit'),
                      _infoRow(Iconsax.receipt_2, 'Total', '\$$total',
                          highlight: true),
                      if (metodoPago != null)
                        _infoRow(Iconsax.card_tick, 'Método de pago',
                            metodoPago),
                    ]),
                    const SizedBox(height: 16),
                    _infoSection('Participantes', [
                      _infoRow(
                          Iconsax.bag, 'Comprador', comprador),
                      _infoRow(
                          Iconsax.shop, 'Vendedor', vendedorName),
                      if (fechaStr.isNotEmpty)
                        _infoRow(
                            Iconsax.clock, 'Fecha', fechaStr),
                    ]),
                    if (dirMap != null) ...[
                      const SizedBox(height: 16),
                      _infoSection('Dirección de entrega', [
                        if ((dirMap['municipio'] as String?)?.isNotEmpty ==
                            true)
                          _infoRow(Iconsax.buildings_2, 'Municipio',
                              dirMap['municipio'] as String),
                        if ((dirMap['barrio'] as String?)?.isNotEmpty == true)
                          _infoRow(Iconsax.buildings_2, 'Barrio',
                              dirMap['barrio'] as String),
                        if ((dirMap['direccion'] as String?)?.isNotEmpty ==
                            true)
                          _infoRow(Iconsax.home, 'Dirección',
                              dirMap['direccion'] as String),
                        if ((dirMap['referencia'] as String?)?.isNotEmpty ==
                            true)
                          _infoRow(Iconsax.info_circle, 'Referencia',
                              dirMap['referencia'] as String),
                        if ((dirMap['telefono'] as String?)?.isNotEmpty == true)
                          _infoRow(Iconsax.call, 'Teléfono',
                              dirMap['telefono'] as String),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    _buildOrderHistory(),
                    const SizedBox(height: 24),

                    // ── Acciones del comerciante ─────────────────
                    if (_isActing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child:
                            CircularProgressIndicator(color: AppTheme.primary),
                      )
                    else ...[
                      if (widget.isVendedor && status == 'pendiente') ...[
                        _actionButton(
                          label: 'Confirmar pedido',
                          icon: Iconsax.tick_circle,
                          color: AppTheme.success,
                          onTap: () => _updateStatus('confirmado'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (widget.isVendedor && status == 'confirmado') ...[
                        _actionButton(
                          label: 'Marcar en camino',
                          icon: Iconsax.truck,
                          color: const Color(0xFF7C3AED),
                          onTap: () => _updateStatus('en_camino'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (widget.isVendedor && status == 'en_camino') ...[
                        _actionButton(
                          label: 'Marcar como entregado',
                          icon: Iconsax.location_tick,
                          color: AppTheme.success,
                          onTap: () => _updateStatus('entregado'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // ── Cancelar (comprador, pedido pendiente) ──────────
                      if (!widget.isVendedor && status == 'pendiente') ...[
                        _actionButton(
                          label: 'Cancelar pedido',
                          icon: Iconsax.close_circle,
                          color: AppTheme.error,
                          onTap: _cancelOrder,
                        ),
                        const SizedBox(height: 10),
                      ],
                      // ── Calificar (comprador, pedido entregado, no calificado) ──
                      if (!widget.isVendedor &&
                          status == 'entregado' &&
                          _data['calificado'] != true) ...[
                        _actionButton(
                          label: _isRating ? 'Enviando...' : 'Calificar compra',
                          icon: Iconsax.star,
                          color: AppTheme.surface,
                          onTap: _isRating ? () {} : _showRatingDialog,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!widget.isVendedor &&
                          status == 'entregado' &&
                          _data['calificado'] == true) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.08),
                            borderRadius: AppTheme.radiusM,
                            border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.tick_circle,
                                  color: AppTheme.success, size: 18),
                              const SizedBox(width: 8),
                              Text('Ya calificaste esta compra',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // ── Volver a pedir (comprador, pedido entregado) ──
                      if (!widget.isVendedor && status == 'entregado') ...[
                        _actionButton(
                          label: 'Volver a pedir',
                          icon: Iconsax.undo,
                          color: AppTheme.green,
                          onTap: _volverAPedir,
                        ),
                        const SizedBox(height: 10),
                        // ── Solicitar devolución ──
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _showReturnDialog,
                            icon: const Icon(Iconsax.undo,
                                color: Color(0xFF1C3320), size: 20),
                            label: Text('Solicitar devolución',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1C3320))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF1C3320), width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTheme.radiusM),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // ── Vendedor: responder devolución ──
                      if (widget.isVendedor && status == 'devolucion_solicitada') ...[
                        _buildReturnRequest(),
                        const SizedBox(height: 10),
                      ],
                      // ── Info devolución (ambos) ──
                      if (status == 'devolucion_aceptada' || status == 'devolucion_rechazada') ...[
                        _buildReturnResult(),
                        const SizedBox(height: 10),
                      ],
                      if (status == 'pendiente' || status == 'confirmado') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _cancelOrder,
                            icon: const Icon(Iconsax.close_circle,
                                color: AppTheme.error, size: 20),
                            label: Text('Cancelar pedido',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.error)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.error, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ],
                      // ── Contactar contraparte ─────────────────────
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final otherUserId = widget.isVendedor
                                ? (_data['compradorId'] as String? ?? '')
                                : (_data['vendedorId'] as String? ?? '');
                            final otherUserName = widget.isVendedor
                                ? (_data['compradorNombre'] as String? ??
                                    'Comprador')
                                : (_data['vendedorNombre'] as String? ??
                                    'Vendedor');
                            final myName = widget.isVendedor
                                ? (_data['vendedorNombre'] as String? ??
                                    'Vendedor')
                                : (_data['compradorNombre'] as String? ??
                                    'Comprador');
                            if (otherUserId.isEmpty) return;
                            Navigator.push(
                              context,
                              AppTheme.pageRoute(ChatScreen(
                                otherUserId: otherUserId,
                                otherUserName: otherUserName,
                                currentUserName: myName,
                              )),
                            );
                          },
                          icon: const Icon(Iconsax.message,
                              color: AppTheme.green, size: 20),
                          label: Text(
                            widget.isVendedor
                                ? 'Contactar comprador'
                                : 'Contactar vendedor',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.green),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppTheme.green, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Historial de estados ─────────────────────────────────────────
  Widget _buildOrderHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getOrderHistory(widget.orderId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.radiusL,
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text('HISTORIAL',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5)),
              ),
              ...docs.asMap().entries.map((entry) {
                final i = entry.key;
                final doc = entry.value;
                final h = doc.data() as Map<String, dynamic>;
                final estado = h['estado'] as String? ?? '';
                final ts = h['timestamp'] as Timestamp?;
                final isLast = i == docs.length - 1;
                return _historyRow(estado, ts, isLast);
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _historyRow(String estado, Timestamp? ts, bool isLast) {
    Color color;
    IconData icon;
    String label;
    switch (estado) {
      case 'pendiente':
        color = AppTheme.warning;
        icon = Iconsax.clock;
        label = 'Pedido recibido';
        break;
      case 'confirmado':
        color = AppTheme.info;
        icon = Iconsax.tick_circle;
        label = 'Pedido confirmado';
        break;
      case 'entregado':
        color = AppTheme.success;
        icon = Iconsax.truck;
        label = 'Entregado al comprador';
        break;
      case 'cancelado':
        color = AppTheme.error;
        icon = Iconsax.close_circle;
        label = 'Pedido cancelado';
        break;
      default:
        color = AppTheme.textMuted;
        icon = Iconsax.info_circle;
        label = estado;
    }

    final fechaStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical + icono
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(left: 15),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.only(left: 30.5),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Texto
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, 6, 16, isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  if (fechaStr.isNotEmpty)
                    Text(fechaStr, style: AppTheme.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Devoluciones ─────────────────────────────────────────────────

  void _showReturnDialog() {
    String? selectedMotivo;
    final detalleCtrl = TextEditingController();
    final motivos = [
      'Producto en mal estado',
      'Producto diferente al publicado',
      'Cantidad incorrecta',
      'No llegó a tiempo',
      'Ya no lo necesito',
      'Otro',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Iconsax.undo,
                  color: Color(0xFF1C3320), size: 22),
              const SizedBox(width: 10),
              Text('Solicitar devolución',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Por qué deseas devolver este producto?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textMuted)),
                const SizedBox(height: 12),
                ...motivos.map((m) => RadioListTile<String>(
                  value: m,
                  groupValue: selectedMotivo,
                  onChanged: (v) => setD(() => selectedMotivo = v),
                  title: Text(m, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                  activeColor: const Color(0xFF1C3320),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: detalleCtrl,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Detalle adicional (opcional)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textMuted),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF1C3320), width: 2)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: selectedMotivo == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await _firestoreService.requestReturn(
                          orderId: widget.orderId,
                          compradorId:
                              FirebaseAuth.instance.currentUser?.uid ?? '',
                          motivo: selectedMotivo!,
                          detalle: detalleCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Devolución solicitada correctamente'),
                              backgroundColor: Color(0xFF1C3320),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C3320),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Enviar solicitud',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnRequest() {
    final dev = _data['devolucion'] as Map<String, dynamic>? ?? {};
    final motivo = dev['motivo'] as String? ?? '';
    final detalle = dev['detalle'] as String? ?? '';
    final respuestaCtrl = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C3320).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.undo,
                  color: Color(0xFF1C3320), size: 20),
              const SizedBox(width: 8),
              Text('Solicitud de devolución',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C3320))),
            ],
          ),
          const SizedBox(height: 10),
          Text('Motivo: $motivo',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Detalle: $detalle',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppTheme.textMuted)),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: respuestaCtrl,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Respuesta al comprador (opcional)',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppTheme.textMuted),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(10),
              filled: true,
              fillColor: AppTheme.inputBg,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _firestoreService.respondReturn(
                        orderId: widget.orderId,
                        accepted: true,
                        respuesta: respuestaCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Devolución aceptada. Stock restaurado.'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Iconsax.check, size: 18),
                  label: Text('Aceptar',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _firestoreService.respondReturn(
                        orderId: widget.orderId,
                        accepted: false,
                        respuesta: respuestaCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Devolución rechazada'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Iconsax.close_circle, size: 18),
                  label: Text('Rechazar',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnResult() {
    final dev = _data['devolucion'] as Map<String, dynamic>? ?? {};
    final motivo = dev['motivo'] as String? ?? '';
    final estado = dev['estado'] as String? ?? '';
    final respuesta = dev['respuesta'] as String? ?? '';
    final accepted = estado == 'aceptada';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accepted
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (accepted
                ? const Color(0xFF16A34A)
                : const Color(0xFFEF4444))
            .withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accepted ? Iconsax.tick_circle : Iconsax.close_circle,
                color: accepted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                accepted ? 'Devolución aceptada' : 'Devolución rechazada',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: accepted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Motivo: $motivo',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppTheme.textMuted)),
          if (respuesta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Respuesta del vendedor: $respuesta',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          if (accepted) ...[
            const SizedBox(height: 8),
            Text('El stock fue restaurado automáticamente.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF16A34A),
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: AppTheme.buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
        ),
      ),
    );
  }

  Widget _statusCard(String status) {
    Color color;
    IconData icon;
    String label;
    String desc;

    switch (status) {
      case 'pendiente':
        color = AppTheme.warning;
        icon = Iconsax.clock;
        label = 'Pendiente';
        desc = 'Esperando confirmación del comerciante';
        break;
      case 'confirmado':
        color = AppTheme.info;
        icon = Iconsax.tick_circle;
        label = 'Confirmado';
        desc = 'El comerciante ha confirmado el pedido';
        break;
      case 'en_camino':
        color = const Color(0xFF7C3AED);
        icon = Iconsax.truck;
        label = 'En camino';
        desc = 'El pedido está en camino hacia ti';
        break;
      case 'entregado':
        color = AppTheme.success;
        icon = Iconsax.location_tick;
        label = 'Entregado';
        desc = 'El pedido ha sido entregado exitosamente';
        break;
      case 'cancelado':
        color = AppTheme.error;
        icon = Iconsax.close_circle;
        label = 'Cancelado';
        desc = 'Este pedido fue cancelado';
        break;
      case 'devolucion_solicitada':
        color = const Color(0xFF1C3320);
        icon = Iconsax.undo;
        label = 'Devolución solicitada';
        desc = 'El comprador solicita devolver este producto';
        break;
      case 'devolucion_aceptada':
        color = const Color(0xFF16A34A);
        icon = Iconsax.tick_circle;
        label = 'Devolución aceptada';
        desc = 'La devolución fue aprobada por el vendedor';
        break;
      case 'devolucion_rechazada':
        color = const Color(0xFFEF4444);
        icon = Iconsax.clock;
        label = 'Devolución rechazada';
        desc = 'La devolución fue rechazada por el vendedor';
        break;
      default:
        color = AppTheme.textMuted;
        icon = Iconsax.info_circle;
        label = status;
        desc = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusL,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(desc,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusL,
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5)),
          ),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.caption),
          const Spacer(),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: highlight ? 16 : 13,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? AppTheme.primary : AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
