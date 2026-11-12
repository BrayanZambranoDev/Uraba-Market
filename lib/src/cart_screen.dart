import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'services/cart_service.dart';
import 'services/firestore_service.dart';
import 'delivery_address_screen.dart';
import 'package:iconsax/iconsax.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _firestoreService = FirestoreService();

  double _total(List<CartItem> items) =>
      items.fold(0, (acc, i) => acc + i.subtotal);

  void _goToPayment(List<CartItem> items) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || items.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryAddressScreen(
          total: _total(items),
          itemCount: items.length,
          onConfirm: (metodoPago, direccion) async {
            final errores = <String>[];
            for (final item in items) {
              try {
                await _firestoreService.createOrder(
                  compradorId: user.uid,
                  compradorNombre: user.displayName ?? 'Comprador',
                  vendedorId: item.vendedorId,
                  vendedorNombre: item.vendedor,
                  productoId: item.productId,
                  productoNombre: item.nombre,
                  productoCategoria: item.categoria,
                  cantidad: item.cantidad,
                  precioUnitario: item.precio,
                  unidad: item.unidad,
                  metodoPago: metodoPago,
                  direccionEntrega: direccion,
                );
              } catch (e) {
                errores.add(item.nombre);
              }
            }
            await _cartService.clearCart();
            if (errores.isNotEmpty) {
              throw Exception(
                  'No se pudieron crear pedidos para: ${errores.join(", ")}. '
                  'Revisa tu historial de pedidos.');
            }
          },
        ),
      ),
    );
  }

  static const _bg = Color(0xFF0A0F0A);
  static const _card = Color(0xFF131C13);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<CartItem>>(
            stream: _cartService.cartStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) return _buildEmpty();
              return _buildList(items);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mi carrito 🌿', style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              StreamBuilder<List<CartItem>>(
                stream: _cartService.cartStream,
                builder: (_, snap) {
                  final n = snap.data?.length ?? 0;
                  return Text('$n producto${n != 1 ? 's' : ''} en tu carrito',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.5)));
                },
              ),
            ]),
            const Spacer(),
            StreamBuilder<List<CartItem>>(
              stream: _cartService.cartStream,
              builder: (_, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _confirmClear(items),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Text('Vaciar', style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.shopping_cart, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Tu carrito está vacío', style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Agrega productos desde el catálogo para hacer tu pedido.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.search_normal, size: 18),
              label: Text('Explorar productos', style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(List<CartItem> items) {
    return Column(children: [
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _cartTile(items[i]),
        ),
      ),
      _buildSummary(items),
    ]);
  }

  Widget _cartTile(CartItem item) {
    final style = AppTheme.getCategoryStyle('');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        // Badge + imagen
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imagenUrl != null
                ? CachedNetworkImage(imageUrl: item.imagenUrl!, width: 72, height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imagePlaceholder(style))
                : _imagePlaceholder(style),
          ),
          Positioned(
            top: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Producto fresco', style: GoogleFonts.plusJakartaSans(
                  fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nombre, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Iconsax.user, size: 12, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 3),
              Text(item.vendedor, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 6),
            Text('\$${item.precio.toStringAsFixed(0)} / ${item.unidad}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          GestureDetector(
            onTap: () => _cartService.removeItem(item.productId),
            child: Icon(Iconsax.close_circle, size: 18, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _qtyBtn(Iconsax.minus_cirlce,
                () => _cartService.updateQuantity(item.productId, item.cantidad - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('${item.cantidad}', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            _qtyBtn(Iconsax.add, () async {
              try {
                await _cartService.updateQuantity(item.productId, item.cantidad + 1);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', ''),
                      style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            }),
          ]),
          const SizedBox(height: 4),
          Text('\$${item.subtotal.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }

  Widget _imagePlaceholder(Map<String, dynamic> style) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B1B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Iconsax.tree, color: AppTheme.primary, size: 32),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.white)),
      ]);

  Widget _buildSummary(List<CartItem> items) {
    final total = _total(items);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 16),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Desglose del total
        _summaryRow('Subtotal (${items.length} producto${items.length != 1 ? 's' : ''})',
            '\$${total.toStringAsFixed(0)}'),
        const SizedBox(height: 6),
        _summaryRow('Envío', 'Gratis',
            valueColor: AppTheme.primary),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total a pagar', style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('\$${total.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Iconsax.shield, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text('Compra segura y protegida',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _goToPayment(items),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Iconsax.card_tick, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Elegir método de pago',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Iconsax.arrow_right, color: Colors.white, size: 18),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmClear(List<CartItem> items) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Text('¿Vaciar carrito?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
            'Se eliminarán los ${items.length} productos del carrito.',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
              elevation: 0,
            ),
            child: Text('Vaciar',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _cartService.clearCart();
  }
}
