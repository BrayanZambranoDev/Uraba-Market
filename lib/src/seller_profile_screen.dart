import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'chat_screen.dart';
import 'product_detail_screen.dart';

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
    final nombre = sellerData['nombre'] ?? 'Comerciante';
    final email = sellerData['email'] ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == sellerId;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header del vendedor
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppTheme.radiusS,
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        if (!isOwnProfile)
                          GestureDetector(
                            onTap: () => _contactSeller(context, currentUser),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_rounded,
                                      size: 16, color: AppTheme.green),
                                  const SizedBox(width: 6),
                                  Text('Contactar',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.green)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Text(inicial,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.green)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(nombre,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Comerciante verificado',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(email,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white70)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Productos del vendedor
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text('Productos', style: AppTheme.heading3),
                const Spacer(),
                const Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppTheme.textMuted),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getVendorProducts(sellerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.green));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Este comerciante aún no tiene productos',
                            style: AppTheme.bodyMuted),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final style =
                        AppTheme.getCategoryStyle(data['categoria']);
                    return _productCard(
                        context, docs[i].id, data, style);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: productId,
            productData: data,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: style['color'] as Color,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(style['icon'] as IconData,
                    color: style['accent'] as Color, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
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
                            color: AppTheme.orange)),
                    Text(unidad, style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
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
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: sellerId,
          otherUserName: sellerData['nombre'] ?? 'Comerciante',
          currentUserName: buyerName,
        ),
      ),
    );
  }
}
