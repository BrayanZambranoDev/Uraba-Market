import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'chat_screen.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  final Map<String, dynamic> sellerData;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerData,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = sellerData['nombre'] ?? 'Vendedor';
    final email = sellerData['email'] ?? '';
    final bio = (sellerData['bio'] as String?)?.trim() ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'V';
    final rol = sellerData['rol'] as String? ?? 'Comerciante';
    final esProductor = rol == 'Productor';
    final esVerificado = sellerData['verificado'] == true;
    final municipio = sellerData['municipio'] as String?;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == sellerId;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0A),
      body: Column(
        children: [
          // Header del vendedor
          Container(
            width: double.infinity,
            color: const Color(0xFF0A0F0A),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Nav bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                            child: Icon(Iconsax.arrow_left,
                                color: AppTheme.primary, size: 20))),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Share.share(
                            '¡Conoce a $nombre en Urabá Market!\n\n'
                            '${esProductor ? 'Productor directo' : 'Comerciante local'}\n\n'
                            'Descarga Urabá Market para comprar productos frescos y locales del Urabá.'),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131C13),
                              shape: BoxShape.circle),
                            child: Icon(Iconsax.share,
                                color: AppTheme.primary, size: 18))),
                        if (!isOwnProfile) ...[
                          // Botón Seguir
                          if (currentUser != null)
                            StreamBuilder<bool>(
                              stream: firestoreService.isFollowingStream(
                                  currentUser.uid, sellerId),
                              builder: (context, snap) {
                                final following = snap.data ?? false;
                                return GestureDetector(
                                  onTap: () {
                                    if (following) {
                                      firestoreService.unfollowSeller(
                                          currentUser.uid, sellerId);
                                    } else {
                                      firestoreService.followSeller(
                                          currentUser.uid, sellerId);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: following
                                          ? AppTheme.primary
                                          : const Color(0xFF131C13),
                                      borderRadius: AppTheme.radiusFull),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          following
                                              ? Iconsax.profile_remove
                                              : Iconsax.user_add,
                                          size: 15,
                                          color: following
                                              ? Colors.white
                                              : AppTheme.primary),
                                        const SizedBox(width: 5),
                                        Text(
                                          following ? 'Siguiendo' : 'Seguir',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: following
                                                  ? Colors.white
                                                  : AppTheme.primary)),
                                      ])));
                              }),
                          // Botón Contactar
                          GestureDetector(
                            onTap: () => _contactSeller(context, currentUser),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: AppTheme.radiusFull),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.message,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('Contactar',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ]))),
                        ],
                      ])),
                  const SizedBox(height: 16),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2),
                      ]),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary),
                      child: sellerData['photoURL'] != null
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: CachedNetworkImageProvider(
                                  sellerData['photoURL'] as String),
                              backgroundColor: const Color(0xFF131C13))
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF131C13),
                              child: Text(inicial,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary))))),
                  const SizedBox(height: 10),
                  Text(nombre,
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppTheme.radiusFull),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esProductor
                              ? Iconsax.tree
                              : esVerificado
                                  ? Iconsax.verify
                                  : Iconsax.shop,
                          color: AppTheme.primary,
                          size: 14),
                        const SizedBox(width: 4),
                        Text(
                          esProductor
                              ? 'Productor directo'
                              : esVerificado
                                  ? 'Comerciante verificado'
                                  : 'Comerciante local',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                      ])),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(email,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                  ],
                  if (municipio != null) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.location,
                          size: 13, color: Colors.white.withValues(alpha: 0.45)),
                      const SizedBox(width: 4),
                      Text(municipio,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                    ]),
                  ],
                  // Rating promedio del vendedor
                  const SizedBox(height: 8),
                  FutureBuilder<double>(
                    future: _getSellerRating(sellerId),
                    builder: (_, snap) {
                      final avg = snap.data ?? 0.0;
                      if (avg <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131C13),
                          borderRadius: AppTheme.radiusFull),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Iconsax.star5,
                              color: const Color(0xFF131C13), size: 14),
                          const SizedBox(width: 4),
                          Text(avg.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary)),
                          Text(' promedio',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                        ]));
                    }),
                  // Bio del vendedor
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(bio,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.5))),
                  ],
                  // Botón WhatsApp si tiene teléfono
                  if (!isOwnProfile &&
                      (sellerData['telefono'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openWhatsApp(
                          context, sellerData['telefono'] as String, nombre),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: AppTheme.radiusFull,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                          ]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.call,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('WhatsApp',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]))),
                  ],
                  const SizedBox(height: 20),
                ]))),

          // Reportar vendedor (solo si no es el mismo usuario)
          if (currentUser != null && currentUser.uid != sellerId)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GestureDetector(
                onTap: () => _reportSeller(context, currentUser),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.flag,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('Reportar vendedor',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45).withValues(alpha: 0.7),
                            decoration: TextDecoration.underline)),
                  ]))),

          // Productos del vendedor
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text('Productos', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Icon(Iconsax.box,
                    size: 16, color: Colors.white.withValues(alpha: 0.45)),
              ])),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getVendorProducts(sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.box,
                            size: 48, color: AppTheme.textDisabled),
                        const SizedBox(height: 8),
                        Text('Este comerciante aún no tiene productos',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                      ]));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final style =
                        AppTheme.getCategoryStyle(data['categoria']);
                    return _productCard(
                        context, docs[i].id, data, style);
                  });
              })),
        ]));
  }

  Widget _productCard(BuildContext context, String productId,
      Map<String, dynamic> data, Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final precioStr =
        precio != null ? '\$${precio.toString()}' : 'Consultar';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(ProductDetailScreen(
          productId: productId,
          productData: data))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          borderRadius: AppTheme.radiusL),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: data['imagenUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: data['imagenUrl'] as String,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: style['color'] as Color,
                        child: Center(
                          child: Icon(style['icon'] as IconData,
                              color: (style['accent'] as Color)
                                  .withValues(alpha: 0.4),
                              size: 40))),
                      errorWidget: (_, __, ___) => Container(
                        color: style['color'] as Color,
                        child: Center(
                          child: Icon(style['icon'] as IconData,
                              color: style['accent'] as Color, size: 48))))
                  : Container(
                      color: style['color'] as Color,
                      child: Center(
                        child: Icon(style['icon'] as IconData,
                            color: style['accent'] as Color, size: 48))))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(precioStr,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                    Text(unidad, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
                  ]),
              ])),
        ])));
  }

  Future<double> _getSellerRating(String vendedorId) async {
    final snap = await FirebaseFirestore.instance
        .collection('productos')
        .where('vendedorId', isEqualTo: vendedorId)
        .where('activo', isEqualTo: true)
        .get();
    double totalSum = 0;
    int totalCount = 0;
    for (final doc in snap.docs) {
      final d = doc.data();
      final avg = (d['ratingAvg'] as num?)?.toDouble() ?? 0.0;
      final count = (d['ratingCount'] as num?)?.toInt() ?? 0;
      if (count > 0) {
        totalSum += avg * count;
        totalCount += count;
      }
    }
    return totalCount > 0 ? totalSum / totalCount : 0.0;
  }

  Future<void> _openWhatsApp(
      BuildContext context, String phone, String name) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/57$cleaned'
        '?text=${Uri.encodeComponent('Hola $name, vi tu perfil en Urabá Market y me interesa conocer tus productos.')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo abrir WhatsApp',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF131C13))),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12)));
    }
  }

  void _contactSeller(BuildContext context, User? currentUser) async {
    if (currentUser == null) return;

    final buyerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final buyerName =
        buyerDoc.data()?['nombre'] ?? currentUser.displayName ?? 'Usuario';

    if (!context.mounted) return;

    Navigator.push(
      context,
      AppTheme.pageRoute(ChatScreen(
        otherUserId: sellerId,
        otherUserName: sellerData['nombre'] ?? 'Comerciante',
        currentUserName: buyerName)));
  }

  Future<void> _reportSeller(BuildContext context, User currentUser) async {
    const motivos = [
      'Vendedor falso o estafador',
      'Contenido inapropiado',
      'No entrega los pedidos',
      'Acoso o comportamiento abusivo',
      'Precios engañosos',
      'Otro',
    ];
    String? motivoSel;
    final detalleCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
          title: Text('Reportar vendedor',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Por qué reportas a este vendedor?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
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
                              : const Color(0xFF0A0F0A),
                          borderRadius: AppTheme.radiusFull,
                          border: Border.all(
                              color: sel
                                  ? AppTheme.error.withValues(alpha: 0.5)
                                  : AppTheme.border)),
                        child: Text(m,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppTheme.error
                                    : AppTheme.textSecondary))));
                  }).toList()),
                const SizedBox(height: 12),
                TextField(
                  controller: detalleCtrl,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Detalle adicional (opcional)...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
                    filled: true,
                    fillColor: const Color(0xFF0A0F0A),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusM,
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusM,
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.all(12))),
              ])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed:
                  motivoSel == null ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.border,
                shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusM),
                elevation: 0),
              child: Text('Enviar reporte',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700))),
          ])));

    if (confirmed != true || motivoSel == null) return;

    try {
      await FirestoreService().reportContent(
        reporterId: currentUser.uid,
        tipo: 'usuario',
        targetId: sellerId,
        motivo: motivoSel!,
        detalle: detalleCtrl.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reporte enviado. Gracias por ayudarnos a mejorar.',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF131C13))),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusS),
        margin: const EdgeInsets.all(12)));
    } catch (_) {}
  }
}
