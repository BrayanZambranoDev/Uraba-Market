import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
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
import 'src/help_screen.dart';
import 'src/settings_screen.dart';
import 'src/mis_productos_screen.dart';
import 'src/feed_screen.dart';
import 'src/favorites_screen.dart';
import 'src/notifications_screen.dart';
import 'src/cart_screen.dart';
import 'src/analytics_screen.dart';
import 'src/inventory_screen.dart';
import 'src/services/connectivity_service.dart';
import 'src/services/firestore_service.dart';
import 'src/services/cart_service.dart';
import 'src/theme/app_theme.dart';
import 'src/utils/shimmer_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedCategory = 0;
  int _homeRefreshCount = 0;

  final User? _user = FirebaseAuth.instance.currentUser;

  late Stream<int> _pendingStream;
  late final Stream<int> _unreadStream;
  late final Stream<DocumentSnapshot> _userStream;
  late final Stream<int> _cartCountStream;
  late final Stream<QuerySnapshot> _offersStream;
  late final Stream<QuerySnapshot> _sellersStream;
  final ConnectivityService _connectivityService = ConnectivityService();
  final FirestoreService _firestoreService = FirestoreService();
  final CartService _cartService = CartService();

  Set<String> _favorites = {};
  StreamSubscription<List<String>>? _favoritesSub;

  Future<List<int>>? _buyerStatsFuture;
  Future<List<String>>? _recentlyViewedFuture;

  DateTime? _lastBackPress;

  late AnimationController _navAnimController;

  // Cached tab widgets — creados una sola vez para evitar parpadeo
  late final Widget _searchTab;
  late final Widget _ordersTab;

  // Banner carrusel
  int _bannerPage = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _searchTab = SearchScreen(onBack: () => setState(() => _currentIndex = 0));
    _ordersTab = OrdersScreen(onBack: () => setState(() => _currentIndex = 0));
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerPage + 1) % 3;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
    // Streams críticos para el primer frame
    _userStream = _user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .snapshots()
        : const Stream.empty();
    _unreadStream = _user != null
        ? _firestoreService.getTotalUnreadStream(_user!.uid)
        : Stream.value(0);
    _cartCountStream = _cartService.itemCountStream;
    _offersStream = FirebaseFirestore.instance
        .collection('productos')
        .where('activo', isEqualTo: true)
        .orderBy('fechaCreacion', descending: true)
        .limit(60)
        .snapshots();
    _sellersStream = FirebaseFirestore.instance
        .collection('users')
        .where('rol', whereIn: ['Comerciante', 'Productor'])
        .where('perfilCompleto', isEqualTo: true)
        .limit(10)
        .snapshots();
    _pendingStream = Stream.value(0); // placeholder, se reemplaza post-frame

    // Streams no críticos diferidos al post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_user != null) {
        final uid = _user!.uid;
        final vendorStream = FirebaseFirestore.instance
            .collection('pedidos')
            .where('vendedorId', isEqualTo: uid)
            .where('estado', isEqualTo: 'pendiente')
            .snapshots()
            .map((s) => s.docs.length);
        final buyerStream = FirebaseFirestore.instance
            .collection('pedidos')
            .where('compradorId', isEqualTo: uid)
            .where('estado', isEqualTo: 'pendiente')
            .snapshots()
            .map((s) => s.docs.length);
        int v = 0, b = 0;
        setState(() {
          _pendingStream = Stream<int>.multi((controller) {
            final s1 = vendorStream.listen((n) {
              v = n;
              controller.add(v + b);
            });
            final s2 = buyerStream.listen((n) {
              b = n;
              controller.add(v + b);
            });
            controller.onCancel = () {
              s1.cancel();
              s2.cancel();
            };
          });
        });
        _recentlyViewedFuture = SharedPreferences.getInstance()
            .then((p) => p.getStringList('recently_viewed') ?? []);
        _favoritesSub = _firestoreService.getFavoritesStream(uid).listen((ids) {
          if (mounted) setState(() => _favorites = Set<String>.from(ids));
        });
        _buyerStatsFuture = Future.wait([
          FirebaseFirestore.instance
              .collection('pedidos')
              .where('compradorId', isEqualTo: uid)
              .get()
              .then((s) => s.docs.length),
          FirebaseFirestore.instance
              .collection('pedidos')
              .where('compradorId', isEqualTo: uid)
              .where('estado', isEqualTo: 'entregado')
              .get()
              .then((s) => s.docs.length),
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('favoritos')
              .get()
              .then((s) => s.docs.length),
        ]);
      }
    });
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    _navAnimController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Iconsax.element_3,
      'label': 'Todas',
      'value': null,
      'color': const Color(0xFF93D5AC),
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=120&q=80',
    },
    {
      'icon': Iconsax.sun_1,
      'label': 'Frutas',
      'value': 'Frutas',
      'color': const Color(0xFF4D9B3A),
      'image': 'assets/images/cat_frutas.png',
    },
    {
      'icon': Iconsax.health,
      'label': 'Verduras',
      'value': 'Verduras',
      'color': const Color(0xFF2D9E4E),
      'image': 'assets/images/cat_verduras.png',
    },
    {
      'icon': Iconsax.gift,
      'label': 'Artesanías',
      'value': 'Artesanías',
      'color': const Color(0xFFD4952A),
      'image': 'assets/images/cat_artesanias.png',
    },
    {
      'icon': Iconsax.cup,
      'label': 'Gastronomía',
      'value': 'Gastronomía',
      'color': const Color(0xFFC43025),
      'image': 'assets/images/cat_gastronomia.png',
    },
    {
      'icon': Iconsax.category,
      'label': 'Más',
      'value': 'Otros',
      'color': const Color(0xFF4A5548),
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=120&q=80',
    },
  ];

  String get _firstName {
    final name = _user?.displayName ?? _user?.email ?? 'Usuario';
    return name.split(' ').first.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Presiona atrás de nuevo para salir',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.primaryDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            ),
          );
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        extendBody: false,
        body: Column(
          children: [
            // Banner de conectividad
            StreamBuilder<bool>(
              stream: _connectivityService.isConnected,
              builder: (context, snapshot) {
                final online = snapshot.data ?? true;
                if (online) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppTheme.error,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.wifi_square,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Text('Sin conexión a internet',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHome(),
                  _searchTab,
                  _ordersTab,
                  _buildProfile(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ─────────────────────────── HOME TAB ───────────────────────────
  Widget _buildHome() {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        setState(() => _homeRefreshCount++);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: CustomScrollView(
        key: ValueKey(_homeRefreshCount),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          // Hero con foto + gradiente fade al fondo
          SliverToBoxAdapter(
            child: ClipRect(
              child: SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    // Foto de fondo
                    Positioned.fill(
                      child: Image.asset('assets/images/home_bg.png',
                          fit: BoxFit.cover, alignment: Alignment.topCenter),
                    ),
                    // Gradiente oscuro de arriba (donde está el texto)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.72),
                              Colors.black.withValues(alpha: 0.50),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Gradiente fade de foto → fondo oscuro (abajo)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.bg],
                          ),
                        ),
                      ),
                    ),
                    // Contenido encima
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVerdantHeader(),
                        _buildGreetingSearch(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverToBoxAdapter(child: _buildHeroImageBanner()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(
              child: _buildSectionTitle('Productores',
                  onViewAll: () => Navigator.push(context,
                      AppTheme.pageRoute(const SellerDirectoryScreen())))),
          SliverToBoxAdapter(child: _buildSellersRow()),
          SliverToBoxAdapter(
              child: _buildSectionTitle('Productos destacados',
                  emoji: '🔥',
                  onViewAll: () => setState(() => _currentIndex = 1))),
          SliverToBoxAdapter(child: _buildProductsGrid()),
          SliverToBoxAdapter(child: _buildOffersSection()),
          SliverToBoxAdapter(child: _buildNearbySection()),
          SliverToBoxAdapter(child: _buildRecentlyViewed()),
          SliverToBoxAdapter(child: _buildTrustBadges()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Verdant header ──
  Widget _buildVerdantHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo + título (lado izquierdo)
            Row(children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(children: [
                  Positioned(
                      bottom: 0,
                      left: 0,
                      child: Icon(Iconsax.tree,
                          color: const Color(0xFF7BC742), size: 30)),
                  Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Iconsax.tree,
                          color: const Color(0xFF4E9121), size: 20)),
                ]),
              ),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Urabá ',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    TextSpan(
                        text: 'Market',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7BC742))),
                  ]),
                ),
                Row(children: [
                  const Icon(Iconsax.location,
                      size: 10, color: Color(0xFF7BC742)),
                  const SizedBox(width: 2),
                  Text('100% local, 100% Urabá',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500)),
                ]),
              ]),
            ]),
            // Cart + Notifications + Profile (lado derecho)
            Row(children: [
              // Cart
              StreamBuilder<int>(
                stream: _cartCountStream,
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context, AppTheme.pageRoute(const CartScreen())),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Icon(Iconsax.bag,
                                color: AppTheme.textPrimary, size: 20),
                            if (count > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.orange,
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Text(count > 9 ? '9+' : '$count',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white))),
                                ),
                              ),
                          ]),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Notifications
              GestureDetector(
                onTap: () => Navigator.push(
                    context, AppTheme.pageRoute(const NotificationsScreen())),
                child: StreamBuilder<int>(
                  stream: _unreadStream,
                  builder: (context, snap) {
                    final hasUnread = (snap.data ?? 0) > 0;
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Icon(Iconsax.notification,
                                color: AppTheme.textPrimary, size: 20),
                            if (hasUnread)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.orange,
                                      shape: BoxShape.circle),
                                ),
                              ),
                          ]),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Profile
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _userStream,
                  builder: (context, snap) {
                    final photoURL = (snap.data?.data()
                        as Map<String, dynamic>?)?['photoURL'] as String?;
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoURL != null
                          ? CachedNetworkImage(
                              imageUrl: photoURL,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                  Iconsax.user,
                                  color: AppTheme.primary,
                                  size: 18))
                          : const Icon(Iconsax.user,
                              color: AppTheme.primary, size: 18),
                    );
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Greeting + Search ──
  Widget _buildGreetingSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('¡Hola, $_firstName! 👋',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2))])),
        const SizedBox(height: 4),
        Text(
            'Apoya lo local y recibe lo mejor de Urabá directamente en tu hogar.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))])),
        const SizedBox(height: 14),
        // Barra de búsqueda + Filtros
        Row(children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppTheme.radiusL,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(children: [
                  const SizedBox(width: 14),
                  const Icon(Iconsax.search_normal,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Busca productos, servicios o tiendas...',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            height: 48,
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppTheme.radiusL,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Iconsax.setting_4,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text('Filtros',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Category squares with images (como el mockup) ──
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final selected = _selectedCategory == i;
          final color = _categories[i]['color'] as Color;
          final label = _categories[i]['label'] as String;
          final imageUrl = _categories[i]['image'] as String;
          final icon = _categories[i]['icon'] as IconData;
          final useIcon = (i == 0 || i == _categories.length - 1);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: SizedBox(
              width: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: selected ? 2 : 0,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1)
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(selected ? 12 : 14),
                      child: useIcon
                          ? Container(
                              color: AppTheme.surface,
                              child: Center(
                                  child: Icon(icon,
                                      color:
                                          selected ? color : AppTheme.textSecondary,
                                      size: 28)),
                            )
                          : Image.asset(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.surface,
                                child: Center(
                                    child: Icon(icon, color: color, size: 26)),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Hero Image Banner (single wide) ──
  Widget _buildHeroImageBanner() {
    final banners = [
      (
        image: 'assets/images/banner2.png',
        title: 'Frutas y verduras\nfrescas del Urabá',
        btn: 'Ver productos',
        onTap: () => setState(() => _currentIndex = 1),
      ),
      (
        image: 'assets/images/banner3.png',
        title: 'Apoya al productor\nlocal del Urabá',
        btn: 'Publicar ahora',
        onTap: () => Navigator.push(
            context, AppTheme.pageRoute(const PublicarProductoScreen())),
      ),
      (
        image: 'assets/images/banner1.png',
        title: 'Ganadería y campo\ndirecto a tu mesa',
        btn: 'Ver directorio',
        onTap: () => Navigator.push(
            context, AppTheme.pageRoute(const SellerDirectoryScreen())),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (_, i) {
              final b = banners[i];
              return GestureDetector(
                onTap: b.onTap,
                child: Container(
                  decoration: BoxDecoration(borderRadius: AppTheme.radiusXL),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(
                      b.image,
                      fit: BoxFit.cover,
                    ),
                    // Gradiente oscuro de izquierda a derecha
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFF082014).withValues(alpha: 0.92),
                            const Color(0xFF082014).withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge LOCAL
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              borderRadius: AppTheme.radiusFull,
                              border: Border.all(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Iconsax.tree,
                                  color: AppTheme.primary, size: 11),
                              const SizedBox(width: 4),
                              Text('LOCAL',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                      letterSpacing: 1.2)),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(b.title,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2)),
                          const SizedBox(height: 4),
                          Text(
                              'Directos del campo a tu mesa.\nApoya a nuestros productores.',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  height: 1.4)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: AppTheme.radiusFull,
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(b.btn,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF082014))),
                              const SizedBox(width: 4),
                              const Icon(Iconsax.arrow_right,
                                  size: 13, color: Color(0xFF082014)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = _bannerPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.25),
                borderRadius: AppTheme.radiusFull,
              ),
            );
          }),
        ),
      ]),
    );
  }

  // ── Products 2-column grid ──
  Widget _buildProductsGrid() {
    final catValue = _categories[_selectedCategory]['value'] as String?;
    Query query = FirebaseFirestore.instance
        .collection('productos')
        .where('activo', isEqualTo: true)
        .orderBy('fechaCreacion', descending: true)
        .limit(8);
    if (catValue != null) query = query.where('categoria', isEqualTo: catValue);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: List.generate(4, (_) => const ShimmerProductCard()),
            ),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text('Sin productos en esta categoría',
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _buildProductGridCard(doc.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGridCard(String productId, Map<String, dynamic> data) {
    final imgUrl = data['imagenUrl'] as String?;
    final nombre = data['nombre'] ?? 'Producto';
    final precio = (data['precio'] as num?)?.toDouble() ?? 0;
    final unidad = data['unidad'] ?? 'c/u';
    final catStyle = AppTheme.getCategoryStyle(data['categoria']);
    final categoria = data['categoria'] ?? 'Otros';

    // Leemos el rating de la base de datos (dinámico).
    // Si no tiene, usamos un valor por defecto para que la tarjeta no quede vacía (como en el diseño).
    final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 4.8;
    final ratingCount =
        (data['ratingCount'] as num?)?.toInt() ?? (15 + (nombre.length % 20));

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          AppTheme.pageRoute(ProductDetailScreen(
              productId: productId,
              productData: Map<String, dynamic>.from(data)))),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusL,
          border: Border.all(color: AppTheme.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagen cuadrada
          Expanded(
            child: Stack(children: [
              SizedBox.expand(
                child: imgUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                              color: AppTheme.cardBg,
                              child: Icon(catStyle['icon'] as IconData,
                                  size: 40, color: AppTheme.textSecondary),
                            ))
                    : Container(
                        color: AppTheme.cardBg,
                        child: Icon(catStyle['icon'] as IconData,
                            size: 40, color: AppTheme.textSecondary)),
              ),
              // Pill de Categoría (Bottom Left)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bg.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (catStyle['icon'] != null) ...[
                        Icon(catStyle['icon'] as IconData,
                            size: 10, color: AppTheme.primary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        categoria.toString().toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorito (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null)
                      _firestoreService.toggleFavorite(
                          uid, productId, _favorites.contains(productId));
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _favorites.contains(productId)
                          ? Iconsax.heart5
                          : Iconsax.heart,
                      size: 16,
                      color: _favorites.contains(productId)
                          ? AppTheme.orange
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // Info Inferior
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text('\$${precio.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary)),
                      const SizedBox(height: 2),
                      Text('por $unidad',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Iconsax.star5,
                              color: AppTheme.warning, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$ratingAvg',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '($ratingCount)',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón Agregar
                GestureDetector(
                  onTap: () {
                    // Acción de agregar rápido al carrito
                    _cartService.addItem(
                      productId: productId,
                      vendedorId: data['vendedorId'] ?? '',
                      vendedor: data['vendedor'] ?? 'Comerciante',
                      nombre: nombre,
                      precio: precio,
                      cantidad: 1,
                      imagenUrl: imgUrl,
                      unidad: unidad,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Agregado al carrito',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppTheme.primaryDark,
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.add,
                        color: AppTheme.primaryDark, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Quick Actions (Scroll horizontal de tarjetas) ──
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: StreamBuilder<int>(
        stream: _unreadStream,
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _quickItem(
                    icon: Iconsax.add,
                    label: 'Publicar',
                    color: AppTheme.primary,
                    isSolidAction: true,
                    onTap: () => Navigator.push(context,
                        AppTheme.pageRoute(const PublicarProductoScreen())),
                  ),
                  _quickItem(
                    icon: Iconsax.shop,
                    label: 'Directorio',
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(context,
                        AppTheme.pageRoute(const SellerDirectoryScreen())),
                  ),
                  _quickItem(
                    icon: Iconsax.message,
                    label: 'Mensajes',
                    color: AppTheme.primary,
                    badge: unread,
                    onTap: () => Navigator.push(context,
                        AppTheme.pageRoute(const ConversationsScreen())),
                  ),
                  _quickItem(
                    icon: Iconsax.cpu,
                    label: 'Asistente\nIA',
                    color: const Color(0xFFC48BFC),
                    onTap: () => Navigator.push(context,
                        AppTheme.pageRoute(const AiAssistantScreen())),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _quickItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
    bool isSolidAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSolidAction ? color : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: isSolidAction
              ? null
              : Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSolidAction
                      ? Colors.white.withOpacity(0.22)
                      : AppTheme.surfaceHigh.withOpacity(0.0),
                  shape: BoxShape.circle,
                  border: isSolidAction
                      ? null
                      : Border.all(color: color.withOpacity(0.35), width: 1.5),
                ),
                child: Icon(icon,
                    color: isSolidAction ? Colors.white : color, size: 24),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge > 9 ? '9+' : '$badge',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSolidAction ? Colors.white : AppTheme.textPrimary,
                  height: 1.2,
                )),
          ],
        ),
        ),
      ),
    );
  }

  // ── Trust Badges ──
  Widget _buildTrustBadges() {
    final badges = [
      {
        'icon': Iconsax.tree,
        'label': 'Apoya lo local',
        'sub': 'Comercio regional',
        'color': const Color(0xFF16A34A)
      },
      {
        'icon': Iconsax.lock,
        'label': 'Pago seguro',
        'sub': 'Tus datos protegidos',
        'color': const Color(0xFF0891B2)
      },
      {
        'icon': Iconsax.truck,
        'label': 'Envíos rápidos',
        'sub': 'Sin complicaciones',
        'color': const Color(0xFFF59E0B)
      },
      {
        'icon': Iconsax.headphone,
        'label': 'Soporte',
        'sub': 'Estamos para ayudarte',
        'color': const Color(0xFF7C3AED)
      },
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
        children: badges.map((b) {
          final color = b['color'] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: AppTheme.radiusM,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(b['icon'] as IconData, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      Text(b['sub'] as String,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, color: AppTheme.textSecondary),
                          maxLines: 1),
                    ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Cerca de ti ──
  Widget _buildNearbySection() {
    if (_user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnap) {
        final municipio = (userSnap.data?.data()
            as Map<String, dynamic>?)?['municipio'] as String?;
        if (municipio == null || municipio.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('productos')
              .where('activo', isEqualTo: true)
              .where('municipio', isEqualTo: municipio)
              .orderBy('fechaCreacion', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.golfo.withValues(alpha: 0.1),
                          borderRadius: AppTheme.radiusFull,
                          border: Border.all(
                              color: AppTheme.golfo.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.location,
                                size: 13, color: AppTheme.golfo),
                            const SizedBox(width: 4),
                            Text('Cerca de ti · $municipio',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.golfo)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 1),
                        child: Text('Ver más',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.orange)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final style =
                          AppTheme.getCategoryStyle(data['categoria']);
                      return KeyedSubtree(
                        key: ValueKey(docs[i].id),
                        child: _buildProductCardH(docs[i].id, data, style),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Ofertas del día ──
  Widget _buildOffersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _offersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // Filtrar los que tienen descuento real
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final precioOriginal = (data['precioOriginal'] as num?)?.toDouble();
          final precio = (data['precio'] as num?)?.toDouble() ?? 0;
          return precioOriginal != null &&
              precioOriginal > precio &&
              precio > 0;
        }).toList();

        // Ordenar por mayor porcentaje de descuento
        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final pa = (da['precio'] as num?)?.toDouble() ?? 0;
          final oa = (da['precioOriginal'] as num?)?.toDouble() ?? 0;
          final pb = (db['precio'] as num?)?.toDouble() ?? 0;
          final ob = (db['precioOriginal'] as num?)?.toDouble() ?? 0;
          final pctA = oa > 0 ? ((oa - pa) / oa) : 0.0;
          final pctB = ob > 0 ? ((ob - pb) / ob) : 0.0;
          return pctB.compareTo(pctA);
        });

        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                      ),
                      borderRadius: AppTheme.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.flash_1,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('Ofertas del día',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Text('Ver más',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.orange)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 250,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final style = AppTheme.getCategoryStyle(data['categoria']);
                  return KeyedSubtree(
                    key: ValueKey(docs[i].id),
                    child: _buildProductCardH(docs[i].id, data, style),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title,
      {String? emoji, VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 18, fontFamily: '')),
              const SizedBox(width: 6),
            ],
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ]),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text('Ver todas >',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCardH(
      String productId, Map<String, dynamic> data, Map<String, dynamic> style) {
    final nombre = data['nombre'] ?? 'Producto';
    final vendedor = data['vendedor'] ?? '';
    final precio = data['precio'];
    final unidad = data['unidad'] ?? 'c/u';
    final stock = (data['stock'] as num?)?.toInt() ?? 1;
    final precioStr = precio != null ? '\$${precio.toString()}' : 'Consultar';
    final accentColor = style['accent'] as Color;
    final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
    final precioOriginal = (data['precioOriginal'] as num?)?.toDouble();
    final precioNum = (data['precio'] as num?)?.toDouble() ?? 0;
    final descPct =
        (precioOriginal != null && precioOriginal > precioNum && precioNum > 0)
            ? (((precioOriginal - precioNum) / precioOriginal) * 100).round()
            : 0;
    final fechaCreacion = data['fechaCreacion'] as Timestamp?;
    final isNew = fechaCreacion != null &&
        DateTime.now().difference(fechaCreacion.toDate()).inDays < 7;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
            ProductDetailScreen(productId: productId, productData: data)),
      ),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusL,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagen full-bleed
          RepaintBoundary(
            child: SizedBox(
              height: 150,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: data['imagenUrl'] != null
                      ? CachedNetworkImage(
                          imageUrl: data['imagenUrl'] as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, __) => Container(
                            color: style['color'] as Color,
                            child: Center(
                              child: Icon(style['icon'] as IconData,
                                  color: accentColor.withValues(alpha: 0.35),
                                  size: 42),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: style['color'] as Color,
                            child: Center(
                              child: Icon(style['icon'] as IconData,
                                  color: accentColor, size: 48),
                            ),
                          ),
                        )
                      : Container(
                          color: style['color'] as Color,
                          child: Center(
                            child: Icon(style['icon'] as IconData,
                                color: accentColor, size: 56),
                          ),
                        ),
                ),
                // Badge nuevo (solo si no hay alerta de stock)
                if (isNew && stock > 5)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: AppTheme.radiusFull,
                      ),
                      child: Text('Nuevo',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                // Badge stock
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
                if (stock > 0 && stock <= 5)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: AppTheme.radiusFull,
                      ),
                      child: Text('¡Últimas $stock!',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                // Botón favorito
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (_user == null) return;
                      HapticFeedback.lightImpact();
                      final isFav = _favorites.contains(productId);
                      _firestoreService.toggleFavorite(
                          _user!.uid, productId, isFav);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: Icon(
                        _favorites.contains(productId)
                            ? Iconsax.heart5
                            : Iconsax.heart,
                        color: _favorites.contains(productId)
                            ? Colors.red
                            : AppTheme.textSecondary,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                // Rating badge
                if (ratingCount > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: AppTheme.radiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.star5,
                              color: Color(0xFFFBBF24), size: 11),
                          const SizedBox(width: 3),
                          Text(
                            ratingAvg.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Discount badge
                if (descPct > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: AppTheme.radiusFull,
                      ),
                      child: Text('-$descPct%',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
          // Info — nombre serif + precio
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 14, color: AppTheme.textPrimary, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (descPct > 0) ...[
                  Text('\$${precioOriginal!.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(precioStr,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(' /$unidad',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: AppTheme.textSecondary)),
              ]),
              if (vendedor.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(vendedor,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Sellers Row (Instagram Stories style) ──
  Widget _buildSellersRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: _sellersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Center(
              child: Text('Aún no hay comerciantes registrados',
                  style: AppTheme.bodyMuted),
            ),
          );
        }

        return SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _buildSellerStory(docs[i].id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildSellerStory(String sellerId, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? 'Comerciante';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';
    final photoURL = data['photoURL'] as String?;
    final firstName = nombre.split(' ').first;
    final verificado = data['verificado'] == true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppTheme.pageRoute(
            SellerProfileScreen(sellerId: sellerId, sellerData: data)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ring + avatar + badge verificado
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.greenGradient,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.bg,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: photoURL != null
                        ? CachedNetworkImage(
                            imageUrl: photoURL,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.green.withValues(alpha: 0.1),
                              child: Center(
                                  child: Text(inicial,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.green))),
                            ),
                          )
                        : Container(
                            color: AppTheme.green.withValues(alpha: 0.1),
                            child: Center(
                                child: Text(inicial,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.green))),
                          ),
                  ),
                ),
              ),
              if (verificado)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9BF0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Iconsax.check,
                        color: Colors.white, size: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 64,
            child: Text(
              firstName,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── PROFILE TAB ───────────────────────────
  Widget _buildProfile() {
    const bg = Color(0xFF0A0F0A);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final nombre = data?['nombre'] ?? _user?.displayName ?? 'Usuario';
        final nombreCorto = nombre.toString().split(' ').first;
        final rol = data?['rol'] ?? 'Comprador';
        final email = data?['email'] ?? _user?.email ?? '';
        final inicial = nombre.toString().isNotEmpty ? nombre.toString()[0].toUpperCase() : 'U';
        final photoURL = data?['photoURL'] as String?;
        final esComerciante = rol == 'Comerciante' || rol == 'Productor';

        return Container(
          color: bg,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              SafeArea(
                bottom: false,
                child: Column(children: [
                  // ── Top bar ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 0),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.arrow_left,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('¡Hola, $nombreCorto! 👋',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Bienvenido a Urabá Market',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            AppTheme.pageRoute(const SettingsScreen())),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Iconsax.setting_2,
                              color: Colors.white.withValues(alpha: 0.8), size: 20),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Avatar + info ────────────────────────────────
                  Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 3),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoURL != null
                          ? CachedNetworkImage(imageUrl: photoURL, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(child: Text(inicial,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))))
                          : Center(child: Text(inicial,
                              style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, AppTheme.pageRoute(const EditProfileScreen())),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2),
                        ),
                        child: const Icon(Iconsax.camera, color: Colors.white, size: 13),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(nombre.toString(),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(email.toString(),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 10),

                  // Badge de rol
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(esComerciante ? Iconsax.shop : Iconsax.bag,
                          color: AppTheme.primary, size: 13),
                      const SizedBox(width: 5),
                      Text(rol, style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      const SizedBox(width: 4),
                      Icon(Iconsax.verify, color: AppTheme.primary, size: 14),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Completeness
                  _buildProfileCompleteness(data),
                  const SizedBox(height: 8),
                ]),
              ),

              // ── Secciones ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(children: [

                  // MI TIENDA (solo comerciantes)
                  if (esComerciante) ...[
                    _profileSection('MI TIENDA', [
                      _profileAction(Iconsax.box, 'Mis Productos', 'Gestiona tu catálogo',
                          color: AppTheme.primary,
                          onTap: () => Navigator.push(context, AppTheme.pageRoute(const MisProductosScreen()))),
                      _profileAction(Iconsax.add_circle, 'Publicar producto', 'Agrega un nuevo producto',
                          color: const Color(0xFF3B82F6),
                          onTap: () => Navigator.push(context, AppTheme.pageRoute(const PublicarProductoScreen()))),
                      _profileAction(Iconsax.building, 'Inventario', 'Control de stock en tiempo real',
                          color: const Color(0xFF14B8A6),
                          onTap: () => Navigator.push(context, AppTheme.pageRoute(const InventoryScreen()))),
                      _profileAction(Iconsax.chart_2, 'Mi rendimiento', 'Control de stock y pedidos y estadísticas',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(context, AppTheme.pageRoute(const AnalyticsScreen()))),
                    ]),
                    const SizedBox(height: 12),
                    _buildSellerStatsCard(_user!.uid),
                    const SizedBox(height: 12),
                  ],

                  // Stats comprador
                  if (!esComerciante && _user != null) ...[
                    _buildBuyerStatsCard(_user!.uid),
                    const SizedBox(height: 12),
                  ],

                  // MI CUENTA
                  _profileSection('MI CUENTA', [
                    _profileAction(Iconsax.user, 'Editar perfil', 'Cambia tu nombre, foto o rol',
                        color: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const EditProfileScreen()))),
                    _profileAction(Iconsax.heart, 'Mis Favoritos', 'Productos que guardaste',
                        color: const Color(0xFFEF4444),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const FavoritesScreen()))),
                    _profileAction(Iconsax.message, 'Mensajes', 'Revisa tus conversaciones',
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const ConversationsScreen()))),
                    _profileAction(Iconsax.magic_star, 'Asistente IA', 'Análisis y recomendaciones',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const AiAssistantScreen()))),
                    _profileAction(Iconsax.setting_2, 'Ajustes', 'Cuenta y privacidad',
                        color: Colors.white.withValues(alpha: 0.5),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const SettingsScreen()))),
                    _profileAction(Iconsax.info_circle, 'Ayuda y soporte', 'Preguntas frecuentes',
                        color: const Color(0xFF06B6D4),
                        onTap: () => Navigator.push(context, AppTheme.pageRoute(const HelpScreen()))),
                  ]),
                  const SizedBox(height: 12),

                  // Cerrar sesión
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A0A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Iconsax.logout, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Text('Cerrar sesión',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer
                  Column(children: [
                    Image.asset('imagen conversaciones.png', width: 40, height: 40, fit: BoxFit.contain),
                    const SizedBox(height: 6),
                    Text('Urabá Market v1.0.0',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    Text('Gracias por usar nuestra app ❤️',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                  ]),
                  const SizedBox(height: 100),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Vistos recientemente ──────────────────────────────────────────
  Widget _buildRecentlyViewed() {
    if (_recentlyViewedFuture == null) return const SizedBox.shrink();
    return FutureBuilder<List<String>>(
      future: _recentlyViewedFuture,
      builder: (context, snap) {
        final ids = snap.data ?? [];
        if (ids.isEmpty) return const SizedBox.shrink();
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(ids.map((id) => FirebaseFirestore.instance
              .collection('productos')
              .doc(id)
              .get()
              .then((d) =>
                  d.exists ? {'id': id, ...d.data()!} : <String, dynamic>{}))),
          builder: (context, snap2) {
            final products = (snap2.data ?? [])
                .where((m) => m.isNotEmpty && m['activo'] != false)
                .toList();
            if (products.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Vistos recientemente'),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      final cat = p['categoria'] as String? ?? 'Otros';
                      return _buildProductCardH(
                          p['id'] as String, p, AppTheme.getCategoryStyle(cat));
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  // ── Panel de estadísticas del comprador ───────────────────────────
  Widget _buildBuyerStatsCard(String uid) {
    return FutureBuilder<List<int>>(
      future: _buyerStatsFuture,
      builder: (context, snap) {
        final total = snap.data?[0] ?? 0;
        final entregados = snap.data?[1] ?? 0;
        final favs = snap.data?[2] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.radiusL,
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.10),
                    borderRadius: AppTheme.radiusS,
                  ),
                  child: const Icon(Iconsax.chart_2,
                      color: AppTheme.orange, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Mi actividad',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _buyerStat(Iconsax.bag, '$total', 'Pedidos',
                    AppTheme.orange),
                _buyerStat(Iconsax.tick_circle, '$entregados',
                    'Entregados', AppTheme.green),
                _buyerStat(Iconsax.heart, '$favs', 'Favoritos',
                    Colors.red),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buyerStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        Text(label, style: AppTheme.caption),
      ]),
    );
  }

  // ── Panel de estadísticas del vendedor ────────────────────────────
  Widget _buildSellerStatsCard(String vendedorId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firestoreService.getSellerStats(vendedorId),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final loading = !snapshot.hasData;

        final totalPedidos = (stats?['totalPedidos'] as num?)?.toInt() ?? 0;
        final entregados = (stats?['pedidosEntregados'] as num?)?.toInt() ?? 0;
        final ventas = (stats?['totalVentas'] as num?)?.toDouble() ?? 0;
        final productos = (stats?['productosActivos'] as num?)?.toInt() ?? 0;
        final ratingAvg = (stats?['ratingAvg'] as num?)?.toDouble() ?? 0;
        final ratingCount = (stats?['ratingCount'] as num?)?.toInt() ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.radiusL,
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusS,
                      ),
                      child: const Icon(Iconsax.chart_2,
                          color: AppTheme.orange, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text('MIS ESTADÍSTICAS',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.8)),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(color: AppTheme.orange)),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Fila 1
                      Row(
                        children: [
                          _statChip(
                            icon: Iconsax.receipt_2,
                            label: 'Pedidos',
                            value: '$totalPedidos',
                            color: AppTheme.info,
                          ),
                          const SizedBox(width: 10),
                          _statChip(
                            icon: Iconsax.truck,
                            label: 'Entregados',
                            value: '$entregados',
                            color: AppTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Fila 2
                      Row(
                        children: [
                          _statChip(
                            icon: Iconsax.dollar_circle,
                            label: 'Ventas totales',
                            value:
                                '\$${ventas >= 1000 ? '${(ventas / 1000).toStringAsFixed(1)}K' : ventas.toStringAsFixed(0)}',
                            color: AppTheme.orange,
                          ),
                          const SizedBox(width: 10),
                          _statChip(
                            icon: Iconsax.box,
                            label: 'Productos',
                            value: '$productos activos',
                            color: AppTheme.green,
                          ),
                        ],
                      ),
                      if (ratingCount > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.10),
                            borderRadius: AppTheme.radiusM,
                            border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.30)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.star5,
                                  color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                ratingAvg.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($ratingCount ${ratingCount == 1 ? "calificación" : "calificaciones"})',
                                style: AppTheme.caption,
                              ),
                              const Spacer(),
                              Text('Rating promedio', style: AppTheme.caption),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: AppTheme.radiusM,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label, style: AppTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompleteness(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    // Calcular campos completados
    int total = 6;
    int filled = 0;
    final missing = <String>[];

    if ((data['nombre'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Nombre');
    if ((data['photoURL'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Foto de perfil');
    if ((data['telefono'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Teléfono');
    if ((data['municipio'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Municipio');
    if ((data['rol'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Rol');
    if ((data['email'] as String?)?.isNotEmpty == true)
      filled++;
    else
      missing.add('Email');

    final pct = filled / total;
    if (pct >= 1.0) return const SizedBox.shrink(); // 100% → no mostrar

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, AppTheme.pageRoute(const EditProfileScreen())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Iconsax.user,
                    color: Colors.white.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 8),
                Text('Perfil ${(pct * 100).toInt()}% completo',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Spacer(),
                Icon(Iconsax.arrow_right_1,
                    color: Colors.white.withValues(alpha: 0.4), size: 12),
              ]),
              const SizedBox(height: 10),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct < 0.5
                          ? AppTheme.orange
                          : pct < 0.8
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                    'Falta: ${missing.take(2).join(", ")}${missing.length > 2 ? "..." : ""}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131C13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppTheme.primary, letterSpacing: 1.2)),
        ),
        Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white.withValues(alpha: 0.06)),
        ...items,
        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _profileAction(IconData icon, String title, String subtitle,
      {required VoidCallback onTap, Color color = AppTheme.primary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusM,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            ]),
          ),
          Icon(Iconsax.arrow_right_1,
              color: Colors.white.withValues(alpha: 0.3), size: 20),
        ]),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        title: Text('Cerrar sesión',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro que deseas cerrar sesión?',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
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
                AppTheme.pageRoute(const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusFull),
            ),
            child: Text('Cerrar sesión',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── BOTTOM NAV (5 tabs) ───────────────────────────
  Widget _buildBottomNav() {
    const iconsOutlined = [
      Iconsax.home,
      Iconsax.element_3,
      Iconsax.search_normal,
      Iconsax.receipt_2,
      Iconsax.user
    ];
    const iconsFilled = [
      Iconsax.home_24,
      Iconsax.element_35,
      Iconsax.search_normal4,
      Iconsax.receipt_25,
      Iconsax.user4
    ];
    const labels = ['Inicio', 'Feed', 'Explorar', 'Pedidos', 'Perfil'];

    Widget _tab(int i) {
      final sel = _currentIndex == i;
      Widget iconW;
      if (i == 3) {
        iconW = StreamBuilder<int>(
          stream: _pendingStream,
          builder: (ctx, snap) {
            final n = snap.data ?? 0;
            return Stack(clipBehavior: Clip.none, children: [
              Icon(sel ? iconsFilled[i] : iconsOutlined[i],
                  color: sel ? AppTheme.primary : AppTheme.textSecondary, size: 22),
              if (n > 0)
                Positioned(
                  top: -3,
                  right: -5,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: AppTheme.error, shape: BoxShape.circle),
                    child: Center(
                        child: Text(n > 9 ? '9+' : '$n',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))),
                  ),
                ),
            ]);
          },
        );
      } else if (i == 4) {
        iconW = StreamBuilder<int>(
          stream: _unreadStream,
          builder: (ctx, snap) {
            final n = snap.data ?? 0;
            return Stack(clipBehavior: Clip.none, children: [
              Icon(sel ? iconsFilled[i] : iconsOutlined[i],
                  color: sel ? AppTheme.primary : AppTheme.textSecondary, size: 22),
              if (n > 0)
                Positioned(
                    top: -3,
                    right: -5,
                    child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppTheme.orange, shape: BoxShape.circle))),
            ]);
          },
        );
      } else {
        iconW = Icon(sel ? iconsFilled[i] : iconsOutlined[i],
            color: sel ? AppTheme.primary : AppTheme.textSecondary, size: 22);
      }
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (i == 1) {
              Navigator.push(context, AppTheme.pageRoute(const FeedScreen()));
            } else {
              setState(() => _currentIndex = i > 1 ? i - 1 : i);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconW,
                const SizedBox(height: 3),
                Text(labels[i],
                    style: GoogleFonts.plusJakartaSans(
                        height: 1.0,
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AppTheme.primary : AppTheme.textSecondary)),
              ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _tab(0),
            _tab(1),
            // Botón central Ura IA
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                      context, AppTheme.pageRoute(const AiAssistantScreen()));
                },
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: const Icon(Iconsax.magic_star,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 1),
                      Text('Ura IA',
                          style: GoogleFonts.plusJakartaSans(
                              height: 1.0,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ]),
              ),
            ),
            _tab(2),
            _tab(3),
          ]),
        ),
      ),
    );
  }
}
