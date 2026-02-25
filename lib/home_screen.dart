import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/login_screen.dart';
import 'src/publicar_producto_screen.dart';
import 'src/search_screen.dart';
import 'src/orders_screen.dart';
import 'src/product_detail_screen.dart';
import 'src/seller_profile_screen.dart';
import 'src/seller_directory_screen.dart';
import 'src/conversations_screen.dart';
import 'src/edit_profile_screen.dart';
import 'src/ai_assistant_screen.dart';
import 'src/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _selectedCategory = 0;

  final User? _user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.grid_view_rounded, 'label': 'Todo', 'value': null},
    {'icon': Icons.eco_rounded, 'label': 'Frutas', 'value': 'Frutas'},
    {'icon': Icons.grass_rounded, 'label': 'Verduras', 'value': 'Verduras'},
    {
      'icon': Icons.storefront_rounded,
      'label': 'Artesanías',
      'value': 'Artesanías'
    },
    {
      'icon': Icons.restaurant_rounded,
      'label': 'Gastronomía',
      'value': 'Gastronomía'
    },
    {'icon': Icons.inventory_2_rounded, 'label': 'Otros', 'value': 'Otros'},
  ];

  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuario';
    return name.split(' ').first.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHome(),
          const SearchScreen(),
          const OrdersScreen(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────── HOME ───────────────────────────
  Widget _buildHome() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildSectionTitle('Categorías')),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(
              child: _buildSectionTitle('Productos destacados',
                  onViewAll: () => setState(() => _currentIndex = 1))),
          SliverToBoxAdapter(child: _buildProductsGrid()),
          SliverToBoxAdapter(
              child: _buildSectionTitle('Comerciantes locales',
                  onViewAll: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SellerDirectoryScreen())))),
          SliverToBoxAdapter(child: _buildSellersList()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Productos desde Firestore ──
  Widget _buildProductsGrid() {
    final categoriaFiltro = _categories[_selectedCategory]['value'] as String?;

    Query query = FirebaseFirestore.instance
        .collection('productos')
        .where('activo', isEqualTo: true)
        .limit(6);

    if (categoriaFiltro != null) {
      query = query.where('categoria', isEqualTo: categoriaFiltro);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child:
                Center(child: CircularProgressIndicator(color: AppTheme.orange)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Center(
              child: Column(children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('Aún no hay productos en esta categoría',
                    style: AppTheme.bodyMuted, textAlign: TextAlign.center),
              ]),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final style = AppTheme.getCategoryStyle(data['categoria']);
              return _buildProductCard(docs[i].id, data, style);
            },
          ),
        );
      },
    );
  }

  // ── Comerciantes desde Firestore ──
  Widget _buildSellersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('rol', isEqualTo: 'Comerciante')
          .where('perfilCompleto', isEqualTo: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child:
                Center(child: CircularProgressIndicator(color: AppTheme.orange)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Center(
              child: Text('Aún no hay comerciantes registrados',
                  style: AppTheme.bodyMuted),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildSellerCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¡Hola, $_firstName! 👋', style: AppTheme.heading1),
            Text('¿Qué vas a vender hoy?', style: AppTheme.bodyMuted),
          ]),
        ),
        // Mensajes
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ConversationsScreen())),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radiusM,
              boxShadow: [AppTheme.shadowSmall],
            ),
            child: const Stack(alignment: Alignment.center, children: [
              Icon(Icons.chat_outlined, color: AppTheme.textSecondary, size: 20),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        // Notificaciones
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radiusM,
            boxShadow: [AppTheme.shadowSmall],
          ),
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_outlined,
                color: AppTheme.textSecondary, size: 22),
            Positioned(
                top: 8,
                right: 8,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppTheme.orange, shape: BoxShape.circle))),
          ]),
        ),
        const SizedBox(width: 10),
        // Avatar
        GestureDetector(
          onTap: () => setState(() => _currentIndex = 3),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.orangeGradient,
              borderRadius: AppTheme.radiusM,
            ),
            child: Center(
              child: Text(
                (_firstName.isNotEmpty ? _firstName[0] : 'U').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 1),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radiusL,
            boxShadow: [AppTheme.shadowSmall],
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded,
                color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 10),
            Text('Buscar productos o comerciantes...', style: AppTheme.bodyMuted),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.orange.withOpacity(0.1),
                borderRadius: AppTheme.radiusS,
              ),
              child:
                  const Icon(Icons.tune_rounded, color: AppTheme.orange, size: 16),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: AppTheme.orangeGradient,
          borderRadius: AppTheme.radiusXL,
          boxShadow: [AppTheme.shadowOrange],
        ),
        child: Stack(children: [
          Positioned(
              right: -20,
              top: -20,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle))),
          Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('¡NUEVO!',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 4),
                    Text('Publica tus\nproductos gratis',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PublicarProductoScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.radiusS,
                        ),
                        child: Text('Empezar ahora',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.orange)),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.storefront_rounded,
                  color: Colors.white54, size: 70),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _quickAction(
            Icons.auto_awesome_rounded,
            'Asistente IA',
            AppTheme.orange,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
          ),
          const SizedBox(width: 10),
          _quickAction(
            Icons.storefront_rounded,
            'Directorio',
            AppTheme.green,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SellerDirectoryScreen())),
          ),
          const SizedBox(width: 10),
          _quickAction(
            Icons.add_box_outlined,
            'Publicar',
            AppTheme.info,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PublicarProductoScreen())),
          ),
          const SizedBox(width: 10),
          _quickAction(
            Icons.chat_outlined,
            'Mensajes',
            const Color(0xFF8B5CF6),
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConversationsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radiusM,
            boxShadow: [AppTheme.shadowSmall],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTheme.heading3),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text('Ver todos',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.orange)),
          ),
      ]),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.orange : Colors.white,
                borderRadius: AppTheme.radiusL,
                boxShadow: [
                  BoxShadow(
                      color: selected
                          ? AppTheme.orange.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_categories[i]['icon'] as IconData,
                        color: selected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        size: 20),
                    const SizedBox(height: 4),
                    Text(_categories[i]['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary)),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
      String productId, Map<String, dynamic> data, Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? 'Comerciante';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final precioStr = precio != null ? '\$${precio.toString()}' : 'Consultar';

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: style['color'] as Color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                  child: Icon(style['icon'] as IconData,
                      color: style['accent'] as Color, size: 52)),
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
                  const SizedBox(height: 2),
                  Text(vendedor,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(precioStr,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.orange)),
                              Text(unidad, style: AppTheme.caption),
                            ]),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: AppTheme.orange,
                              borderRadius: AppTheme.radiusS),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ]),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSellerCard(String sellerId, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Comerciante';
    final categoria = data['categoria'] ?? 'Productos locales';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(
              sellerId: sellerId,
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
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.1),
                borderRadius: AppTheme.radiusM,
              ),
              child: Center(
                  child: Text(inicial,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.green))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(categoria, style: AppTheme.caption),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────── PERFIL ───────────────────────────
  Widget _buildProfile() {
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final nombre = data?['nombre'] ?? _user?.displayName ?? 'Usuario';
          final rol = data?['rol'] ?? 'Comprador';
          final email = data?['email'] ?? _user?.email ?? '';
          final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            child: Column(children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: AppTheme.orangeGradient),
                child: Column(children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [AppTheme.shadowMedium],
                    ),
                    child: Center(
                        child: Text(inicial,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.orange))),
                  ),
                  const SizedBox(height: 12),
                  Text(nombre,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          rol == 'Comerciante'
                              ? Icons.storefront_rounded
                              : Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 14),
                      const SizedBox(width: 6),
                      Text(rol,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _profileSection('Información personal', [
                    _profileItem(
                        Icons.person_outline_rounded, 'Nombre', nombre),
                    _profileItem(Icons.mail_outline_rounded, 'Correo', email),
                    _profileItem(Icons.badge_outlined, 'Rol', rol),
                  ]),
                  const SizedBox(height: 16),
                  _profileSection('Mi cuenta', [
                    _profileAction(Icons.edit_outlined, 'Editar perfil',
                        'Cambia tu nombre o rol',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()))),
                    _profileAction(Icons.chat_outlined, 'Mensajes',
                        'Revisa tus conversaciones',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ConversationsScreen()))),
                    _profileAction(Icons.auto_awesome_rounded,
                        'Asistente IA', 'Análisis y recomendaciones',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AiAssistantScreen()))),
                    _profileAction(Icons.help_outline_rounded,
                        'Ayuda y soporte', 'Preguntas frecuentes',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.error, size: 20),
                      label: Text('Cerrar sesión',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
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
                  const SizedBox(height: 8),
                  Text('Urabá Market v1.0.0', style: AppTheme.caption),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _profileSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusL,
        boxShadow: [AppTheme.shadowSmall],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ]),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.orange.withOpacity(0.08),
            borderRadius: AppTheme.radiusS,
          ),
          child: Icon(icon, color: AppTheme.orange, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.caption),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ]),
      ]),
    );
  }

  Widget _profileAction(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusM,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.orange.withOpacity(0.08),
              borderRadius: AppTheme.radiusS,
            ),
            child: Icon(icon, color: AppTheme.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Text(subtitle, style: AppTheme.caption),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted, size: 20),
        ]),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusL),
        title: Text('Cerrar sesión',
            style:
                GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro que deseas cerrar sesión?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusS),
            ),
            child: Text('Cerrar sesión',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── BOTTOM NAV ───────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Inicio'},
      {'icon': Icons.search_rounded, 'label': 'Buscar'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Pedidos'},
      {'icon': Icons.person_rounded, 'label': 'Perfil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.orange.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: AppTheme.radiusM,
                        ),
                        child: Icon(items[i]['icon'] as IconData,
                            color: selected
                                ? AppTheme.orange
                                : AppTheme.textMuted,
                            size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(items[i]['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppTheme.orange
                                  : AppTheme.textMuted)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
