import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'services/cart_service.dart';
import 'chat_screen.dart';
import 'delivery_address_screen.dart';
import 'package:iconsax/iconsax.dart';

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
  final CartService _cartService = CartService();
  final _notasController = TextEditingController();
  int _heroPage = 0;
  int _cantidad = 1;

  Map<String, dynamic> get data => widget.productData;
  String get nombre => data['nombre'] ?? 'Producto';
  String get vendedor => data['vendedor'] ?? 'Vendedor';
  String get vendedorId => data['vendedorId'] ?? '';
  String get vendedorRol => data['vendedorRol'] as String? ?? 'Comerciante';
  String get descripcion => data['descripcion'] ?? 'Sin descripción disponible.';
  String get categoria => data['categoria'] ?? 'Otros';
  String get unidad => data['unidad'] ?? 'c/u';
  double get precio => (data['precio'] ?? 0).toDouble();
  int get stock => (data['stock'] ?? 0).toInt();
  String? get imagenUrl => data['imagenUrl'] as String?;
  List<String> get imagenUrls {
    final raw = data['imagenUrls'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<String>().toList();
    }
    final single = imagenUrl;
    return single != null ? [single] : [];
  }

  Future<void> _reportProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    const motivos = [
      'Producto falso o engañoso',
      'Precio abusivo',
      'Contenido inapropiado',
      'Vendedor sospechoso',
      'Producto prohibido',
      'Otro',
    ];
    String? motivoSel;
    final detalleCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
          title: Text('Reportar producto',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Por qué reportas este producto?',
                    style: AppTheme.caption),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: motivos.map((m) {
                    final sel = motivoSel == m;
                    return GestureDetector(
                      onTap: () => setStateDlg(() => motivoSel = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.error.withValues(alpha: 0.1)
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
                TextField(
                  controller: detalleCtrl,
                  maxLines: 2,
                  style: AppTheme.body,
                  decoration: InputDecoration(
                    hintText: 'Detalle adicional (opcional)...',
                    hintStyle: AppTheme.bodyMuted,
                    filled: true,
                    fillColor: AppTheme.bg,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusM,
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusM,
                      borderSide:
                          const BorderSide(color: AppTheme.orange, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: AppTheme.bodyMuted),
            ),
            ElevatedButton(
              onPressed: motivoSel == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.border,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusM),
                elevation: 0,
              ),
              child: Text('Enviar reporte',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || motivoSel == null || !mounted) return;

    try {
      await FirestoreService().reportContent(
        reporterId: user.uid,
        tipo: 'producto',
        targetId: widget.productId,
        motivo: motivoSel!,
        detalle: detalleCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reporte enviado. Gracias por ayudarnos a mejorar.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    } catch (_) {}
  }

  void _shareProduct() {
    final precioFmt = precio % 1 == 0
        ? precio.toInt().toString()
        : precio.toStringAsFixed(2);
    Share.share(
      '¡Mira este producto en Urabá Market!\n\n'
      '$nombre\n'
      '\$$precioFmt / $unidad\n'
      'Vendedor: $vendedor\n\n'
      'Descarga Urabá Market para más productos locales del Urabá.',
    );
  }

  @override
  void initState() {
    super.initState();
    _firestoreService.incrementViews(widget.productId);
    _saveRecentlyViewed(widget.productId);
  }

  Future<void> _saveRecentlyViewed(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recently_viewed') ?? [];
    list.remove(productId);
    list.insert(0, productId);
    if (list.length > 10) list.removeLast();
    await prefs.setStringList('recently_viewed', list);
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.getCategoryStyle(categoria);
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == vendedorId;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header — carousel de imágenes o placeholder por categoría
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fondo: PageView de imágenes o placeholder
                imagenUrls.isNotEmpty
                    ? PageView.builder(
                        itemCount: imagenUrls.length,
                        onPageChanged: (i) => setState(() => _heroPage = i),
                        itemBuilder: (_, i) => InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: imagenUrls[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                              color: style['color'] as Color,
                              child: Center(
                                child: Icon(style['icon'] as IconData,
                                    color: (style['accent'] as Color)
                                        .withValues(alpha: 0.3),
                                    size: 80),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: style['color'] as Color,
                              child: Center(
                                child: Icon(style['icon'] as IconData,
                                    color: (style['accent'] as Color)
                                        .withValues(alpha: 0.3),
                                    size: 80),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: style['color'] as Color,
                        child: Center(
                          child: Icon(style['icon'] as IconData,
                              color: (style['accent'] as Color)
                                  .withValues(alpha: 0.3),
                              size: 140),
                        ),
                      ),
                // Gradiente para legibilidad de los controles
                if (imagenUrls.isNotEmpty)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x88000000), Colors.transparent],
                        stops: [0.0, 0.5],
                      ),
                    ),
                  ),
                // Controles superpuestos
                SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: imagenUrls.isNotEmpty
                                  ? Colors.black.withValues(alpha: 0.30)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Icon(Iconsax.arrow_left,
                                color: imagenUrls.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                size: 20),
                          ),
                        ),
                      ),
                      // Botón compartir
                      Positioned(
                        top: 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: _shareProduct,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: imagenUrls.isNotEmpty
                                  ? Colors.black.withValues(alpha: 0.30)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Icon(Iconsax.share,
                                color: imagenUrls.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                size: 20),
                          ),
                        ),
                      ),
                      // Pill de categoría
                      Positioned(
                        top: 60,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: style['accent'] as Color,
                            borderRadius: AppTheme.radiusFull,
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Text(categoria,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                      // Indicadores de página (solo si hay > 1 imagen)
                      if (imagenUrls.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imagenUrls.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _heroPage ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _heroPage
                                      ? AppTheme.orange
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
                      color: AppTheme.bg,
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
                                if (() {
                                  final po = (data['precioOriginal'] as num?)
                                      ?.toDouble();
                                  return po != null &&
                                      po > precio &&
                                      precio > 0;
                                }()) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${(data['precioOriginal'] as num).toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textMuted,
                                            decoration:
                                                TextDecoration.lineThrough),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: AppTheme.radiusFull,
                                        ),
                                        child: Text(
                                          '-${((( (data['precioOriginal'] as num).toDouble() - precio) / (data['precioOriginal'] as num).toDouble()) * 100).round()}%',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ],
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
                        const SizedBox(height: 10),

                        // Mini stats: categoría + vistas + stock
                        Row(children: [
                          _miniChip(Iconsax.category, categoria,
                              const Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          _miniChip(Iconsax.eye,
                              '${(data['vistas'] as num?)?.toInt() ?? 0} vistas',
                              AppTheme.textMuted),
                          const SizedBox(width: 8),
                          _miniChip(
                            stock > 0
                                ? Iconsax.tick_circle
                                : Iconsax.close_circle,
                            stock > 0 ? '$stock disp.' : 'Agotado',
                            stock > 5
                                ? AppTheme.green
                                : stock > 0
                                    ? AppTheme.warning
                                    : AppTheme.error,
                          ),
                        ]),

                        const SizedBox(height: 12),

                        // Vendedor
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: AppTheme.radiusM,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.green.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.green.withValues(alpha: 0.3),
                                          width: 1.5),
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
                                        if (vendedorRol == 'Productor')
                                          Container(
                                            margin: const EdgeInsets.only(top: 3),
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.green.withValues(alpha: 0.12),
                                              borderRadius: AppTheme.radiusFull,
                                              border: Border.all(color: AppTheme.green.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Iconsax.tree, size: 11, color: Color(0xFF16A34A)),
                                              const SizedBox(width: 3),
                                              Text('Directo del productor',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.green)),
                                            ]),
                                          )
                                        else
                                          Text(vendedorRol == 'Comerciante' ? 'Comerciante local' : 'Vendedor',
                                              style: AppTheme.caption),
                                      ],
                                    ),
                                  ),
                                  if (!isOwner) ...[
                                    GestureDetector(
                                      onTap: () => _contactSeller(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.green.withValues(alpha: 0.1),
                                          borderRadius: AppTheme.radiusFull,
                                          border: Border.all(
                                              color: AppTheme.green.withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Iconsax.message,
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
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _hacerOferta(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.orange.withValues(alpha: 0.1),
                                          borderRadius: AppTheme.radiusFull,
                                          border: Border.all(
                                              color: AppTheme.orange.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Iconsax.discount_circle,
                                                size: 14, color: AppTheme.orange),
                                            const SizedBox(width: 4),
                                            Text('Oferta',
                                                style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.orange)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // WhatsApp si el vendedor tiene teléfono
                              if (!isOwner)
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(vendedorId)
                                      .get(),
                                  builder: (_, snap) {
                                    final raw = snap.data?.data()
                                        as Map<String, dynamic>?;
                                    final phone = raw?['telefono'] as String?;
                                    if (phone == null || phone.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: GestureDetector(
                                        onTap: () => _openWhatsApp(phone),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366)
                                                .withValues(alpha: 0.1),
                                            borderRadius: AppTheme.radiusM,
                                            border: Border.all(
                                                color: const Color(0xFF25D366)
                                                    .withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Iconsax.call,
                                                  size: 15,
                                                  color: Color(0xFF25D366)),
                                              const SizedBox(width: 6),
                                              Text('Contactar por WhatsApp',
                                                  style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF25D366))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock
                        Row(
                          children: [
                            _infoChip(Iconsax.box,
                                'Stock: $stock $unidad'),
                            const SizedBox(width: 8),
                            _infoChip(
                                Iconsax.truck, 'Urabá'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Descripción
                        Text('Descripción', style: AppTheme.heading3),
                        const SizedBox(height: 8),
                        Text(descripcion,
                            style: AppTheme.body.copyWith(
                                color: AppTheme.textSecondary, height: 1.5)),

                        // Reportar (solo para no propietarios)
                        if (!isOwner) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _reportProduct,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.flag,
                                    size: 13,
                                    color: AppTheme.textMuted
                                        .withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text('Reportar este producto',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppTheme.textMuted
                                            .withValues(alpha: 0.7),
                                        decoration:
                                            TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ],

                        // Rating resumen
                        const SizedBox(height: 20),
                        _buildRatingSummary(),
                      ],
                    ),
                  ),

                  // Preguntas al vendedor
                  _buildQASection(),

                  // Reseñas
                  _buildReviewsList(),

                  // Más de este vendedor
                  _buildSellerProducts(),

                  // También te puede interesar
                  _buildRelatedProducts(),
                ],
              ),
            ),
          ),

          // Barra inferior: cantidad + botón pedir
          if (!isOwner)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: SafeArea(
                top: false,
                child: stock == 0
                    // ── Sin stock: banner agotado ──────────────────
                    ? Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: AppTheme.radiusM,
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.bag_cross,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Text('Producto agotado',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.error)),
                          ],
                        ),
                      )
                    // ── Con stock: notas + selector + botón ───────
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _notasController,
                            style: AppTheme.body.copyWith(fontSize: 13),
                            maxLines: 1,
                            maxLength: 150,
                            decoration: InputDecoration(
                              hintText: 'Instrucciones para el vendedor (opcional)',
                              hintStyle: AppTheme.caption,
                              counterText: '',
                              prefixIcon: const Icon(Iconsax.document_text,
                                  size: 18, color: AppTheme.textMuted),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.bg,
                              border: OutlineInputBorder(
                                  borderRadius: AppTheme.radiusM,
                                  borderSide:
                                      const BorderSide(color: AppTheme.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.radiusM,
                                  borderSide:
                                      const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.radiusM,
                                  borderSide: const BorderSide(
                                      color: AppTheme.orange, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                          // Selector de cantidad
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.bg,
                              borderRadius: AppTheme.radiusM,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                _quantityBtn(Iconsax.minus_cirlce, () {
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
                                _quantityBtn(Iconsax.add, () {
                                  if (_cantidad < stock) {
                                    setState(() => _cantidad++);
                                  }
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón agregar al carrito
                          GestureDetector(
                            onTap: _addToCart,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.orange.withValues(alpha: 0.1),
                                borderRadius: AppTheme.radiusM,
                                border: Border.all(
                                    color: AppTheme.orange.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Iconsax.shopping_cart,
                                  color: AppTheme.orange, size: 22),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón pedir
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _createOrder(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.orange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppTheme.radiusFull),
                                  elevation: 0,
                                ),
                                child: Text(
                                  precio > 0
                                      ? 'Pedir • \$${(precio * _cantidad).toStringAsFixed(0)}'
                                      : 'Realizar pedido',
                                  style: AppTheme.buttonText,
                                ),
                              ),
                            ),
                          ),
                        ],
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
        borderRadius: AppTheme.radiusFull,
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

    // Obtener nombre del comprador antes de navegar
    final buyerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final buyerName =
        buyerDoc.data()?['nombre'] ?? user.displayName ?? 'Comprador';
    final notas = _notasController.text.trim();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryAddressScreen(
          total: precio * _cantidad,
          itemCount: _cantidad,
          onConfirm: (metodoPago, direccion) => _firestoreService.createOrder(
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
            notasComprador: notas,
            metodoPago: metodoPago,
            direccionEntrega: direccion,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    _questionController.dispose();
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Rating resumen (promedio + estrellas) ─────────────────────────
  Widget _buildRatingSummary() {
    final avg = (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
    final count = (data['ratingCount'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: AppTheme.radiusL,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          // Número grande + estrellas
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count > 0 ? avg.toStringAsFixed(1) : '—',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < avg.round()
                      ? Iconsax.star5
                      : Iconsax.star,
                  color: const Color(0xFFF59E0B),
                  size: 16,
                )),
              ),
              const SizedBox(height: 4),
              Text(
                count == 0
                    ? 'Sin reseñas'
                    : '$count ${count == 1 ? "reseña" : "reseñas"}',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Divider vertical manual (no VerticalDivider)
          Container(
            width: 1,
            height: 60,
            color: const Color(0xFFFDE68A),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              count == 0
                  ? 'Sé el primero en calificar este producto después de tu compra.'
                  : 'Basado en calificaciones de compradores verificados de Urabá Market.',
              style: AppTheme.caption.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista de reseñas ──────────────────────────────────────────────
  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getRatings(widget.productId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(20),
          color: AppTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reseñas', style: AppTheme.heading3),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final r = doc.data() as Map<String, dynamic>;
                final stars = (r['estrellas'] as num?)?.toInt() ?? 5;
                final comment = r['comentario'] as String? ?? '';
                final userName = r['userName'] as String? ?? 'Usuario';
                final ts = r['fechaCreacion'] as Timestamp?;
                final fecha = ts != null
                    ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                    : '';
                return _buildReviewCard(
                    userName, stars, comment, fecha);
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Preguntas al vendedor ─────────────────────────────────────────
  final _questionController = TextEditingController();
  final _answerControllers = <String, TextEditingController>{};

  Widget _buildQASection() {
    final user = FirebaseAuth.instance.currentUser;
    final canAsk = user != null && user.uid != vendedorId;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: AppTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Iconsax.info_circle,
                color: AppTheme.orange, size: 20),
            const SizedBox(width: 8),
            Text('Preguntas al vendedor', style: AppTheme.heading3),
          ]),
          const SizedBox(height: 14),

          // Campo para hacer pregunta
          if (canAsk) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  maxLines: 2,
                  minLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '¿Tienes alguna pregunta sobre este producto?',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textDisabled),
                    filled: true,
                    fillColor: AppTheme.bg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusM,
                        borderSide:
                            const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusM,
                        borderSide: const BorderSide(
                            color: AppTheme.border, width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.radiusM,
                        borderSide: const BorderSide(
                            color: AppTheme.orange, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final texto = _questionController.text.trim();
                  if (texto.isEmpty) return;
                  try {
                    await _firestoreService.addQuestion(
                      productId: widget.productId,
                      compradorId: user.uid,
                      compradorNombre: user.displayName ?? 'Comprador',
                      texto: texto,
                    );
                    _questionController.clear();
                  } catch (_) {}
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppTheme.orangeGradient,
                    borderRadius: AppTheme.radiusM,
                  ),
                  child: const Icon(Iconsax.send_1,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // Lista de preguntas
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getQuestions(widget.productId),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Text('Sé el primero en preguntar.',
                    style: AppTheme.bodyMuted);
              }
              final docs = snap.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final qId = docs[i].id;
                  final pregunta = d['texto'] as String? ?? '';
                  final respuesta = d['respuesta'] as String?;
                  final autor = d['compradorNombre'] as String? ?? 'Usuario';
                  final isOwner = user != null && user.uid == vendedorId;

                  _answerControllers.putIfAbsent(
                      qId, () => TextEditingController());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pregunta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.user,
                                size: 16, color: AppTheme.orange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(autor,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMuted)),
                                const SizedBox(height: 2),
                                Text(pregunta,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Respuesta o campo para responder
                      if (respuesta != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 38),
                            Container(
                              width: 3,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.green.withValues(alpha: 0.4),
                                borderRadius: AppTheme.radiusFull,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vendedor',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.green)),
                                  const SizedBox(height: 2),
                                  Text(respuesta,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else if (isOwner) ...[
                        const SizedBox(height: 8),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(width: 38),
                              Expanded(
                                child: TextField(
                                  controller: _answerControllers[qId],
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Escribe tu respuesta...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppTheme.textDisabled),
                                    filled: true,
                                    fillColor: AppTheme.bg,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius: AppTheme.radiusM,
                                        borderSide: const BorderSide(
                                            color: AppTheme.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: AppTheme.radiusM,
                                        borderSide: const BorderSide(
                                            color: AppTheme.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: AppTheme.radiusM,
                                        borderSide: const BorderSide(
                                            color: AppTheme.green, width: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final ans =
                                      _answerControllers[qId]!.text.trim();
                                  if (ans.isEmpty) return;
                                  await _firestoreService.answerQuestion(
                                    productId: widget.productId,
                                    questionId: qId,
                                    respuesta: ans,
                                  );
                                  _answerControllers[qId]!.clear();
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.green,
                                    borderRadius: AppTheme.radiusM,
                                  ),
                                  child: const Icon(Iconsax.check,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ]),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Más de este vendedor ─────────────────────────────────────────
  Widget _miniChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildSellerProducts() {
    if (vendedorId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('productos')
          .where('vendedorId', isEqualTo: vendedorId)
          .where('activo', isEqualTo: true)
          .limit(9)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs
            .where((d) => d.id != widget.productId)
            .take(8)
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
          color: AppTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Más de $vendedor', style: AppTheme.heading3),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final imgUrl = d['imagenUrl'] as String?;
                    final catStyle =
                        AppTheme.getCategoryStyle(d['categoria']);
                    final pNombre = d['nombre'] ?? 'Producto';
                    final pPrecio =
                        (d['precio'] as num?)?.toDouble() ?? 0;
                    final pUnidad = d['unidad'] ?? '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        ctx,
                        AppTheme.pageRoute(ProductDetailScreen(
                          productId: doc.id,
                          productData: Map<String, dynamic>.from(d),
                        )),
                      ),
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: AppTheme.radiusL,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: imgUrl != null && imgUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      width: 130,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _relatedPlaceholder(catStyle),
                                    )
                                  : _relatedPlaceholder(catStyle),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 8, 8, 6),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(pNombre,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${pPrecio % 1 == 0 ? pPrecio.toInt() : pPrecio.toStringAsFixed(2)}/$pUnidad',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── También te puede interesar ────────────────────────────────────
  Widget _buildRelatedProducts() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('productos')
          .where('categoria', isEqualTo: categoria)
          .where('activo', isEqualTo: true)
          .limit(10)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs
            .where((d) => d.id != widget.productId)
            .take(6)
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
          color: AppTheme.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('También te puede interesar',
                    style: AppTheme.heading3),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final imgUrl = d['imagenUrl'] as String?;
                    final catStyle = AppTheme.getCategoryStyle(d['categoria']);
                    final pNombre = d['nombre'] ?? 'Producto';
                    final pPrecio = (d['precio'] as num?)?.toDouble() ?? 0;
                    final pUnidad = d['unidad'] ?? '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        ctx,
                        AppTheme.pageRoute(ProductDetailScreen(
                          productId: doc.id,
                          productData: Map<String, dynamic>.from(d),
                        )),
                      ),
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: AppTheme.radiusL,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: imgUrl != null && imgUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      width: 130,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _relatedPlaceholder(catStyle),
                                    )
                                  : _relatedPlaceholder(catStyle),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pNombre,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${pPrecio % 1 == 0 ? pPrecio.toInt() : pPrecio.toStringAsFixed(2)}/$pUnidad',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(
      String userName, int stars, String comment, String fecha) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: AppTheme.radiusM,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.orange),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    if (fecha.isNotEmpty)
                      Text(fecha, style: AppTheme.caption),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars
                        ? Iconsax.star5
                        : Iconsax.star,
                    color: const Color(0xFFF59E0B),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: AppTheme.body
                    .copyWith(color: AppTheme.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _relatedPlaceholder(Map<String, dynamic> style) {
    return Container(
      width: 130,
      height: 100,
      color: (style['accent'] as Color).withValues(alpha: 0.12),
      child: Center(
        child: Icon(style['icon'] as IconData,
            color: style['accent'] as Color, size: 32),
      ),
    );
  }

  Future<void> _addToCart() async {
    final data = widget.productData;
    try {
      await _cartService.addItem(
        productId: widget.productId,
        nombre: data['nombre'] ?? 'Producto',
        precio: (data['precio'] as num?)?.toDouble() ?? 0,
        unidad: data['unidad'] ?? 'c/u',
        vendedorId: data['vendedorId'] ?? '',
        vendedor: data['vendedor'] ?? 'Comerciante',
        categoria: data['categoria'] as String? ?? '',
        imagenUrl: data['imagenUrl'] as String?,
        cantidad: _cantidad,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Agregado al carrito',
              style: AppTheme.body.copyWith(color: Colors.white)),
        ]),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Error al agregar al carrito';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse(
        'https://wa.me/57$cleaned?text=${Uri.encodeComponent('Hola, vi tu producto en Urabá Market y me interesa.')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo abrir WhatsApp',
            style: AppTheme.body.copyWith(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> _hacerOferta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final precioCtrl = TextEditingController(
      text: precio % 1 == 0
          ? precio.toInt().toString()
          : precio.toStringAsFixed(2),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: Text('Hacer oferta',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Precio publicado: \$${precio % 1 == 0 ? precio.toInt() : precio.toStringAsFixed(2)} / $unidad',
                style: AppTheme.bodyMuted),
            const SizedBox(height: 14),
            Text('Tu oferta (\$):', style: AppTheme.caption),
            const SizedBox(height: 6),
            TextField(
              controller: precioCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.orange),
                filled: true,
                fillColor: AppTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.radiusM,
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.radiusM,
                  borderSide:
                      const BorderSide(color: AppTheme.orange, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: AppTheme.bodyMuted),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusM),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Enviar oferta',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ofertaStr = precioCtrl.text.trim();
    final ofertaVal = double.tryParse(ofertaStr);
    if (ofertaVal == null || ofertaVal <= 0) return;

    final msg =
        'Hola $vendedor, me interesa "$nombre" y te hago una oferta de \$$ofertaStr / $unidad. ¿Lo tienes disponible?';
    await _contactSeller(initialMessage: msg);
  }

  Future<void> _contactSeller({String? initialMessage}) async {
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
      AppTheme.pageRoute(ChatScreen(
        otherUserId: vendedorId,
        otherUserName: vendedor,
        currentUserName: buyerName,
        initialMessage: initialMessage,
      )),
    );
  }
}

