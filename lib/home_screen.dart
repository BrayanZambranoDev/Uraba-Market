import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/login_screen.dart';
import 'src/publicar_producto_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _selectedCategory = 0;

  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _bg = Color(0xFFF8FAFC);

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

  // Colores para las tarjetas de productos según categoría
  Map<String, dynamic> _categoryStyle(String? cat) {
    switch (cat) {
      case 'Frutas':
        return {
          'color': const Color(0xFFFEF3C7),
          'accent': const Color(0xFFF59E0B),
          'icon': Icons.eco_rounded
        };
      case 'Verduras':
        return {
          'color': const Color(0xFFDCFCE7),
          'accent': const Color(0xFF16A34A),
          'icon': Icons.grass_rounded
        };
      case 'Artesanías':
        return {
          'color': const Color(0xFFFFEDD5),
          'accent': const Color(0xFFF97316),
          'icon': Icons.palette_rounded
        };
      case 'Gastronomía':
        return {
          'color': const Color(0xFFFCE7F3),
          'accent': const Color(0xFFEC4899),
          'icon': Icons.restaurant_rounded
        };
      default:
        return {
          'color': const Color(0xFFF1F5F9),
          'accent': const Color(0xFF64748B),
          'icon': Icons.inventory_2_rounded
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHome(),
          _buildPlaceholder(Icons.search_rounded, 'Buscar'),
          _buildPlaceholder(Icons.receipt_long_rounded, 'Mis Pedidos'),
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
          SliverToBoxAdapter(child: _buildSectionTitle('Categorías')),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(child: _buildSectionTitle('Productos destacados')),
          SliverToBoxAdapter(child: _buildProductsGrid()),
          SliverToBoxAdapter(child: _buildSectionTitle('Comerciantes locales')),
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
        // Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Sin productos
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Center(
              child: Column(children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('Aún no hay productos en esta categoría',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: const Color(0xFF94A3B8)),
                    textAlign: TextAlign.center),
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
              final style = _categoryStyle(data['categoria']);
              return _buildProductCard(data, style);
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
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Center(
              child: Text('Aún no hay comerciantes registrados',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: const Color(0xFF94A3B8))),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildSellerCard(data);
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
            Text('¡Hola, $_firstName! 👋',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
            Text('¿Qué vas a vender hoy?',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ]),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_outlined,
                color: Color(0xFF374151), size: 22),
            Positioned(
                top: 8,
                right: 8,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _orange, shape: BoxShape.circle))),
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() => _currentIndex = 3),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded,
                color: Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 10),
            Text('Buscar productos o comerciantes...',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF94A3B8))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune_rounded, color: _orange, size: 16),
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
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _orange.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PublicarProductoScreen())),
                        child: Text('Empezar ahora',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _orange)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
        Text('Ver todos',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: _orange)),
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
                color: selected ? _orange : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: selected
                          ? _orange.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_categories[i]['icon'],
                        color:
                            selected ? Colors.white : const Color(0xFF64748B),
                        size: 20),
                    const SizedBox(height: 4),
                    Text(_categories[i]['label'],
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF64748B))),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> data, Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? 'Comerciante';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final precioStr = precio != null ? '\$${precio.toString()}' : 'Consultar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: style['color'],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
                child: Icon(style['icon'], color: style['accent'], size: 52)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(vendedor,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(precioStr,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _orange)),
                Text(unidad,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: const Color(0xFF94A3B8))),
              ]),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: _orange, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 18),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Comerciante';
    final categoria = data['categoria'] ?? 'Productos locales';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(inicial,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _green))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              Text(categoria,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: const Color(0xFF64748B))),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1), size: 20),
        ]),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                        child: Text(inicial,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: _orange))),
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
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
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
                        onTap: () {}),
                    _profileAction(Icons.notifications_outlined,
                        'Notificaciones', 'Gestiona tus alertas',
                        onTap: () {}),
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
                          color: Color(0xFFEF4444), size: 20),
                      label: Text('Cerrar sesión',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Urabá Market v1.0.0',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: const Color(0xFFCBD5E1))),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
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
            color: _orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orange, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A))),
        ]),
      ]),
    );
  }

  Widget _profileAction(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A))),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1), size: 20),
        ]),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro que deseas cerrar sesión?',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B))),
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
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cerrar sesión',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── PLACEHOLDER ───────────────────────────
  Widget _buildPlaceholder(IconData icon, String label) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 60, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8))),
        const SizedBox(height: 6),
        Text('Próximamente',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: const Color(0xFFCBD5E1))),
      ]),
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
                              ? _orange.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(items[i]['icon'] as IconData,
                            color: selected ? _orange : const Color(0xFF94A3B8),
                            size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(items[i]['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? _orange
                                  : const Color(0xFF94A3B8))),
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
