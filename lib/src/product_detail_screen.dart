import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _cantidad = 1;
  bool _isOrdering = false;

  Map<String, dynamic> get data => widget.productData;
  String get nombre => data['nombre'] ?? 'Producto';
  String get vendedor => data['vendedor'] ?? 'Comerciante';
  String get vendedorId => data['vendedorId'] ?? '';
  String get descripcion => data['descripcion'] ?? 'Sin descripción disponible.';
  String get categoria => data['categoria'] ?? 'Otros';
  String get unidad => data['unidad'] ?? 'c/u';
  double get precio => (data['precio'] ?? 0).toDouble();
  int get stock => (data['stock'] ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.getCategoryStyle(categoria);
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == vendedorId;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header con imagen
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: style['color'] as Color,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Icon(style['icon'] as IconData,
                        color: (style['accent'] as Color).withOpacity(0.3),
                        size: 140),
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.radiusM,
                          boxShadow: [AppTheme.shadowSmall],
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: style['accent'] as Color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(categoria,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info principal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(nombre,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    precio > 0
                                        ? '\$${precio.toStringAsFixed(0)}'
                                        : 'Consultar',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.orange)),
                                Text('por $unidad', style: AppTheme.caption),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Vendedor
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: AppTheme.radiusM,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.green.withOpacity(0.1),
                                  borderRadius: AppTheme.radiusS,
                                ),
                                child: Center(
                                  child: Text(
                                    vendedor.isNotEmpty
                                        ? vendedor[0].toUpperCase()
                                        : 'C',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vendedor,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary)),
                                    Text('Comerciante local',
                                        style: AppTheme.caption),
                                  ],
                                ),
                              ),
                              if (!isOwner)
                                GestureDetector(
                                  onTap: () => _contactSeller(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.chat_outlined,
                                            size: 14, color: AppTheme.green),
                                        const SizedBox(width: 4),
                                        Text('Contactar',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.green)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock
                        Row(
                          children: [
                            _infoChip(Icons.inventory_2_outlined,
                                'Stock: $stock $unidad'),
                            const SizedBox(width: 8),
                            _infoChip(
                                Icons.local_shipping_outlined, 'Urabá'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Descripción
                        Text('Descripción', style: AppTheme.heading3),
                        const SizedBox(height: 8),
                        Text(descripcion,
                            style: AppTheme.body.copyWith(
                                color: AppTheme.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra inferior: cantidad + botón pedir
          if (!isOwner)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Selector de cantidad
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: AppTheme.radiusM,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          _quantityBtn(Icons.remove_rounded, () {
                            if (_cantidad > 1) {
                              setState(() => _cantidad--);
                            }
                          }),
                          SizedBox(
                            width: 36,
                            child: Text('$_cantidad',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                          ),
                          _quantityBtn(Icons.add_rounded, () {
                            if (_cantidad < stock || stock == 0) {
                              setState(() => _cantidad++);
                            }
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botón pedir
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isOrdering ? null : () => _createOrder(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.radiusM),
                            elevation: 4,
                            shadowColor: AppTheme.orange.withOpacity(0.35),
                          ),
                          child: _isOrdering
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  precio > 0
                                      ? 'Pedir • \$${(precio * _cantidad).toStringAsFixed(0)}'
                                      : 'Realizar pedido',
                                  style: AppTheme.buttonText),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(borderRadius: AppTheme.radiusS),
        child: Icon(icon, size: 18, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTheme.caption),
        ],
      ),
    );
  }

  Future<void> _createOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isOrdering = true);

    // Obtener nombre del comprador
    final buyerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final buyerName =
        buyerDoc.data()?['nombre'] ?? user.displayName ?? 'Comprador';

    final orderId = await _firestoreService.createOrder(
      compradorId: user.uid,
      compradorNombre: buyerName,
      vendedorId: vendedorId,
      vendedorNombre: vendedor,
      productoId: widget.productId,
      productoNombre: nombre,
      productoCategoria: categoria,
      cantidad: _cantidad,
      precioUnitario: precio,
      unidad: unidad,
    );

    if (!mounted) return;
    setState(() => _isOrdering = false);

    if (orderId != null) {
      _showOrderSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al crear el pedido',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
      ));
    }
  }

  void _showOrderSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.success, size: 40),
          ),
          const SizedBox(height: 16),
          Text('¡Pedido realizado!',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(
              '$_cantidad $unidad de $nombre\nTotal: \$${(precio * _cantidad).toStringAsFixed(0)}',
              style: AppTheme.bodyMuted,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('El comerciante recibirá tu pedido',
              style: AppTheme.caption, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusM),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Volver al inicio',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _contactSeller() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final buyerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final buyerName =
        buyerDoc.data()?['nombre'] ?? user.displayName ?? 'Usuario';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: vendedorId,
          otherUserName: vendedor,
          currentUserName: buyerName,
        ),
      ),
    );
  }
}
