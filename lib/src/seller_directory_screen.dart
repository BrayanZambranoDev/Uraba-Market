import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'seller_profile_screen.dart';
import 'constants/app_constants.dart';
import 'package:iconsax/iconsax.dart';

class SellerDirectoryScreen extends StatefulWidget {
  const SellerDirectoryScreen({super.key});

  @override
  State<SellerDirectoryScreen> createState() =>
      _SellerDirectoryScreenState();
}

class _SellerDirectoryScreenState extends State<SellerDirectoryScreen> {
  String _searchQuery = '';
  String _sortBy = 'nombre';
  String? _municipioFiltro;
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.orangeGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.arrow_left,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendedores locales',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('Directorio del Urabá',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppTheme.radiusFull,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Buscar comerciante...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: Colors.white60),
                    prefixIcon: const Icon(Iconsax.search_normal,
                        color: Colors.white60, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Container(
                              margin: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.close_circle,
                                  color: Colors.white, size: 14),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // Sort chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _sortChip('A-Z', 'nombre'),
                  const SizedBox(width: 8),
                  _sortChip('Z-A', 'nombre_desc'),
                  const SizedBox(width: 8),
                  _sortChip('Más reciente', 'reciente'),
                ],
              ),
            ),
            // Municipio chips
            SizedBox(
              height: 32,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                scrollDirection: Axis.horizontal,
                children: [
                  _municipioChip(null, 'Todos'),
                  ...AppConstants.municipios
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _municipioChip(m, m),
                          )),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.orange : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _municipioChip(String? value, String label) {
    final selected = _municipioFiltro == value;
    return GestureDetector(
      onTap: () => setState(() => _municipioFiltro = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: AppTheme.radiusFull,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.orange : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('rol', whereIn: ['Comerciante', 'Productor'])
          .where('perfilCompleto', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        var docs = snapshot.data?.docs ?? [];

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre =
                (data['nombre'] ?? '').toString().toLowerCase();
            return nombre.contains(q);
          }).toList();
        }

        if (_municipioFiltro != null) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['municipio'] == _municipioFiltro;
          }).toList();
        }

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final aNombre = (da['nombre'] ?? '').toString().toLowerCase();
          final bNombre = (db['nombre'] ?? '').toString().toLowerCase();
          if (_sortBy == 'nombre_desc') return bNombre.compareTo(aNombre);
          if (_sortBy == 'reciente') {
            final aTs = (da['fechaRegistro'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTs = (db['fechaRegistro'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTs.compareTo(aTs);
          }
          return aNombre.compareTo(bNombre);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.shop,
                      size: 40, color: AppTheme.green),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No se encontraron comerciantes'
                      : 'Aún no hay comerciantes registrados',
                  style: AppTheme.subtitle,
                ),
                const SizedBox(height: 6),
                Text('¡Sé el primero en registrarte!',
                    style: AppTheme.bodyMuted),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildSellerTile(docs[i].id, data);
          },
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: AppTheme.radiusM,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: AppTheme.radiusFull)),
                  const SizedBox(height: 7),
                  Container(
                      height: 11,
                      width: 90,
                      decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: AppTheme.radiusFull)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerTile(String userId, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Vendedor';
    final email = data['email'] ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'V';
    final rol = data['rol'] as String? ?? 'Comerciante';
    final esProductor = rol == 'Productor';
    final esVerificado = data['verificado'] == true;
    final photoURL = data['photoURL'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
          SellerProfileScreen(sellerId: userId, sellerData: data),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            // Avatar con anillo gradiente
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0F1A10),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoURL != null
                    ? CachedNetworkImage(
                        imageUrl: photoURL,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initialAvatar(inicial),
                      )
                    : _initialAvatar(inicial),
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(esProductor ? 'Productor directo' : 'Comerciante local',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.green)),
                      if (esVerificado) ...[
                        const SizedBox(width: 6),
                        const Icon(Iconsax.verify,
                            size: 14, color: Color(0xFF2563EB)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FutureBuilder<int>(
                        future: FirebaseFirestore.instance
                            .collection('productos')
                            .where('vendedorId', isEqualTo: userId)
                            .where('activo', isEqualTo: true)
                            .limit(50)
                            .get()
                            .then((s) => s.docs.length),
                        builder: (ctx, snap) {
                          final count = snap.data ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.1),
                              borderRadius: AppTheme.radiusFull,
                              border: Border.all(
                                  color: AppTheme.orange
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Iconsax.box,
                                    size: 11,
                                    color: AppTheme.orange),
                                const SizedBox(width: 4),
                                Text('$count producto${count == 1 ? '' : 's'}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.orange)),
                              ],
                            ),
                          );
                        },
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(email,
                              style: AppTheme.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.arrow_right,
                  color: AppTheme.green, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(String inicial) {
    return Container(
      color: AppTheme.green.withValues(alpha: 0.1),
      child: Center(
        child: Text(inicial,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.green)),
      ),
    );
  }
}
