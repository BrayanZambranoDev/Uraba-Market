import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'product_detail_screen.dart';
import 'utils/shimmer_box.dart';
import 'package:iconsax/iconsax.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final service = FirestoreService();

    const bg = Color(0xFF0A0F0A);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // Header
        Container(
          color: bg,
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
                  Text('Mis Favoritos', style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Tus productos favoritos', style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                ]),
              ]),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: service.getFavoritesStream(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.68),
                  itemBuilder: (_, __) => const ShimmerProductCard(width: double.infinity, height: 240),
                );
              }
              final ids = snap.data ?? [];
              if (ids.isEmpty) return _EmptyFavorites(context: context);
              return _FavoritesGrid(productIds: ids, userId: user.uid);
            },
          ),
        ),
      ]),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  final List<String> productIds;
  final String userId;

  const _FavoritesGrid({required this.productIds, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirestoreService().getFavoriteProducts(productIds),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.68),
            itemBuilder: (_, __) => const ShimmerProductCard(width: double.infinity, height: 240),
          );
        }

        final products = snap.data ?? [];
        if (products.isEmpty) return _EmptyFavorites(context: context);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.68),
          itemBuilder: (context, i) {
            final item = products[i];
            final productId = item['id'] as String;
            final data = Map<String, dynamic>.from(item)..remove('id');
            return _FavoriteCard(productId: productId, data: data, userId: userId);
          },
        );
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  final String userId;

  const _FavoriteCard(
      {required this.productId, required this.data, required this.userId});

  @override
  Widget build(BuildContext context) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? '';
    final precio = (data['precio'] as num?)?.toDouble() ?? 0;
    final unidad = data['unidad'] ?? '';
    final imagenURL = data['imagenURL'] as String?;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final style = AppTheme.getCategoryStyle(data['categoria']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
            ProductDetailScreen(productId: productId, productData: data)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          borderRadius: AppTheme.radiusL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Stack(children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imagenURL != null && imagenURL.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imagenURL,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _PlaceholderImg(style),
                        )
                      : _PlaceholderImg(style),
                ),
                if (stock == 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: AppTheme.radiusFull,
                      ),
                      child: Text('Agotado',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                // Botón quitar favorito
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await FirestoreService()
                          .toggleFavorite(userId, productId, true);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: const Icon(Iconsax.heart5,
                          color: Colors.red, size: 15),
                    ),
                  ),
                ),
              ]),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(nombre,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (vendedor.isNotEmpty)
                      Text(vendedor,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Text(
                          '\$${precio % 1 == 0 ? precio.toInt() : precio.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(width: 4),
                        Text('/$unidad',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.35))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  final Map<String, dynamic> style;
  const _PlaceholderImg(this.style);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: (style['accent'] as Color).withValues(alpha: 0.15),
      child: Center(
        child: Icon(style['icon'] as IconData,
            color: style['accent'] as Color, size: 40),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final BuildContext context;
  const _EmptyFavorites({required this.context});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Heart icon with sparkles
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.heart5, size: 50, color: Color(0xFFEF4444)),
            ),
            Positioned(top: 8, right: 8,
                child: Icon(Iconsax.star, size: 14, color: AppTheme.primary.withValues(alpha: 0.7))),
            Positioned(bottom: 12, left: 6,
                child: Icon(Iconsax.star, size: 10, color: Colors.white.withValues(alpha: 0.4))),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Aún no tienes favoritos', style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Toca el corazón en cualquier producto para guardarlo aquí',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), height: 1.5)),
        const SizedBox(height: 24),
        // Feature chips
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _chip(Iconsax.flash_1, 'Acceso\nrápido', 'Encuentra tus\nfavoritos fácilmente'),
          _chip(Iconsax.notification, 'Notificaciones', 'Te avisaremos de\nofertas y precios'),
          _chip(Iconsax.convert, 'Compara', 'Compara precios y\ntoma mejores\ndecisiones'),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.search_normal, size: 18),
            label: Text('Explorar productos', style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.lamp_on, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('¿Sabías que?', style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              Text('Puedes agregar productos a favoritos desde la página del producto.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String title, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF131C13),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 24),
      ),
      const SizedBox(height: 6),
      Text(title, textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(subtitle, textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
    ]);
  }
}
