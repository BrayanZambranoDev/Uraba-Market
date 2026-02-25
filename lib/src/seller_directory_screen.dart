import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'seller_profile_screen.dart';

class SellerDirectoryScreen extends StatefulWidget {
  const SellerDirectoryScreen({super.key});

  @override
  State<SellerDirectoryScreen> createState() => _SellerDirectoryScreenState();
}

class _SellerDirectoryScreenState extends State<SellerDirectoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
              child: Column(
                children: [
                  Row(
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
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Directorio de Comerciantes',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text('Comerciantes verificados de Urabá',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Búsqueda
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppTheme.radiusM,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar comerciante...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white60),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white60, size: 18),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 28),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('rol', isEqualTo: 'Comerciante')
                    .where('perfilCompleto', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.green));
                  }

                  var docs = snapshot.data?.docs ?? [];

                  // Filtrar por búsqueda
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre =
                          (data['nombre'] ?? '').toString().toLowerCase();
                      return nombre.contains(q);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron comerciantes'
                                : 'Aún no hay comerciantes registrados',
                            style: AppTheme.bodyMuted,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      return _buildSellerTile(
                          docs[i].id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerTile(String userId, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Comerciante';
    final email = data['email'] ?? '';
    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerProfileScreen(
            sellerId: userId,
            sellerData: data,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: [AppTheme.shadowSmall],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.1),
                borderRadius: AppTheme.radiusM,
              ),
              child: Center(
                child: Text(inicial,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.green)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 12, color: AppTheme.green),
                      const SizedBox(width: 4),
                      Text('Comerciante verificado',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: AppTheme.green)),
                    ],
                  ),
                  if (email.isNotEmpty)
                    Text(email, style: AppTheme.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
